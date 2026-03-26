import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easyconnect/gen_l10n/app_localizations.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/auth_state.dart';
import 'package:easyconnect/Views/Auth/login_page.dart';

void main() {
  group('AuthState', () {
    test('copyWith conserve les valeurs non passées', () {
      const base = AuthState(isLoading: false, showPassword: false);
      final u = base.copyWith(isLoading: true);
      expect(u.isLoading, isTrue);
      expect(u.showPassword, isFalse);
      expect(u.user, isNull);
    });
  });

  group('authProvider (AuthNotifier)', () {
    test('togglePasswordVisibility inverse showPassword', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => AuthNotifier.test()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).showPassword, isFalse);
      container.read(authProvider.notifier).togglePasswordVisibility();
      expect(container.read(authProvider).showPassword, isTrue);
      container.read(authProvider.notifier).togglePasswordVisibility();
      expect(container.read(authProvider).showPassword, isFalse);
    });
  });

  group('LoginPage (widget)', () {
    testWidgets('affiche le formulaire et bascule la visibilité du mot de passe', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => AuthNotifier.test()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
