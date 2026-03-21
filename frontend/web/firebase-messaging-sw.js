// Service Worker pour Firebase Cloud Messaging (Web) - voir FCM_WEB_SETUP.md
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Même firebaseConfig que web/index.html (remplacer YOUR_WEB_APP_ID par l'appId de l'app web Firebase)
firebase.initializeApp({
  apiKey: "AIzaSyBGNKXbt8dIALOA-DSGvCqwJBHPjfmGMVk",
  authDomain: "easyconnect-aleb.firebaseapp.com",
  projectId: "easyconnect-aleb",
  storageBucket: "easyconnect-aleb.firebasestorage.app",
  messagingSenderId: "17317714210",
  appId: "1:17317714210:web:YOUR_WEB_APP_ID"
});

// Récupérer l'instance de messaging
const messaging = firebase.messaging();

// Gérer les messages reçus en arrière-plan
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Message reçu en arrière-plan:', payload);

  // Personnaliser la notification
  const notificationTitle = payload.notification?.title || 'EasyConnect';
  const notificationOptions = {
    body: payload.notification?.body || 'Nouvelle notification',
    icon: '/favicon.png',
    badge: '/favicon.png',
    tag: payload.data?.entityType || 'default',
    data: payload.data,
    requireInteraction: false,
    vibrate: [200, 100, 200],
  };

  // Afficher la notification
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Gérer les clics sur les notifications
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification cliquée:', event);
  
  event.notification.close();

  // Ouvrir l'application ou naviguer vers la bonne page (FCM peut envoyer action_route ou actionRoute)
  const data = event.notification.data || {};
  const actionRoute = data.action_route || data.actionRoute;
  const urlToOpen = actionRoute
    ? `${self.location.origin}${actionRoute}`
    : self.location.origin;

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((windowClients) => {
        // Vérifier si l'application est déjà ouverte
        for (let client of windowClients) {
          if (client.url === urlToOpen && 'focus' in client) {
            return client.focus();
          }
        }
        // Sinon, ouvrir une nouvelle fenêtre
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});

console.log('✅ Service Worker Firebase Messaging chargé');

