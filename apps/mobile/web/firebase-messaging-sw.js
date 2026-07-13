importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCZUfA5L6poVTO2c6xANv-oW3lK4TDQ8xQ",
  authDomain: "ya-app-z.firebaseapp.com",
  projectId: "ya-app-z",
  storageBucket: "ya-app-z.firebasestorage.app",
  messagingSenderId: "432248591325",
  databaseURL: "https://ya-app-z-default-rtdb.firebaseio.com",
});

const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage((message) => {
  console.log("Background message received:", message);
});
