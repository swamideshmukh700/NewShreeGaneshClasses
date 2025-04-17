// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCa6D2JxItosuAVZNJoWRSwEIGEL9MWWSo",
  projectId: "shreeapp-41b65",
  storageBucket: "shreeapp-41b65.appspot.com",
  messagingSenderId: "267300961273",
  appId: "1:267300961273:web:b23218352270920bb95b28"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
