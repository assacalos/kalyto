import 'dart:io';

import 'package:easyconnect/services/http_interceptor.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    pathProviderChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getTemporaryDirectory':
        case 'getApplicationSupportDirectory':
        case 'getLibraryDirectory':
        case 'getExternalStorageDirectory':
          return Directory.systemTemp.path;
        default:
          return Directory.systemTemp.path;
      }
    });

    await GetStorage.init();
  });

  tearDownAll(() async {
    pathProviderChannel.setMockMethodCallHandler(null);
  });

  group('HttpInterceptor.apiUri', () {
    test('normalise correctement les slashes', () {
      final uri1 = HttpInterceptor.apiUri('clients-list');
      final uri2 = HttpInterceptor.apiUri('/clients-list');

      expect(uri1.toString(), equals(uri2.toString()));
      expect(uri1.path.endsWith('/clients-list'), isTrue);
    });
  });

  group('AuthErrorHandler', () {
    setUp(() {
      AuthErrorHandler.logoutCallback = null;
      AuthErrorHandler.currentRouteCallback = null;
      AuthErrorHandler.showSnackbarCallback = null;
    });

    test('ne déclenche pas de logout sur une réponse 200', () async {
      var logoutCalled = false;
      AuthErrorHandler.logoutCallback = ({bool silent = false, String? redirectTo}) async {
        logoutCalled = true;
      };

      final okResponse = http.Response('{"ok":true}', 200);
      final success = await AuthErrorHandler.checkResponse(okResponse);

      expect(success, isTrue);
      expect(logoutCalled, isFalse);
    });

    test('déclenche logout sur 401 en mode skipRefresh', () async {
      var logoutCalled = false;
      bool? capturedSilent;
      String? capturedRedirect;

      AuthErrorHandler.currentRouteCallback = () => '/dashboard';
      AuthErrorHandler.logoutCallback = ({bool silent = false, String? redirectTo}) async {
        logoutCalled = true;
        capturedSilent = silent;
        capturedRedirect = redirectTo;
      };

      final unauthorized = http.Response('{"message":"unauthorized"}', 401);
      await AuthErrorHandler.handleHttpResponse(unauthorized, skipRefresh: true);

      expect(logoutCalled, isTrue);
      expect(capturedSilent, isFalse);
      expect(capturedRedirect, equals('/login'));
    });
  });
}

