importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDIRb7PkmUSAlFzgaMvhvKmFpsv8v1bDHw",
  authDomain: "ayhamproject-758e8.firebaseapp.com",
  projectId: "ayhamproject-758e8",
  storageBucket: "ayhamproject-758e8.firebasestorage.app",
  messagingSenderId: "503214777250",
  appId: "1:503214777250:web:11fc089842cc6ba8edc8fb",
  measurementId: "G-2TMY4SF69Z"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  console.log(
    '[firebase-messaging-sw.js] Received background message ',
    payload
  );

  if (payload.notification) {
    self.registration.showNotification(
      payload.notification.title,
      {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png', // اختياري
      }
    );
  }
});
