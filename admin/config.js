// إعدادات Firebase لتطبيق الويب.
// انسخها من: Firebase Console ← Project settings ← Your apps ← Web app ← SDK setup and configuration.
// (هذه القيم ليست سرية؛ الحماية الفعلية في firestore.rules وصلاحية admin.)
export const firebaseConfig = {
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
};

// يجب أن تطابق kCities في lib/core/constants.dart
export const CITIES = ['عطبرة'];
