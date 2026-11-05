# تطبيق التبرع بالدم المجتمعي (Flutter + Firebase)

تطبيق تواصل مباشر (P2P) بين أفراد المجتمع بفكرة **الحساب الموحد**: كل مستخدم متبرع جاهز يتلقى
النداءات المتوافقة مع فصيلته، ويمكنه التحول إلى **طالب دم** بضغطة زر.

## الشاشات

| # | الشاشة | الملف |
|---|--------|-------|
| ١ | التسجيل برقم الهاتف (OTP) ثم إكمال الملف | `lib/screens/auth/` |
| ٢ | الرئيسية: طلبات تناسب فصيلتي / طلباتي + مفتاح التوفر + زر «طلب دم طارئ» | `lib/screens/home/home_screen.dart` |
| ٣ | إنشاء طلب مع نطاق البحث الذكي | `lib/screens/request/create_request_screen.dart` |
| ٤أ | تفاصيل الطلب للمتبرع + «أنا قادم» | `lib/screens/request/request_details_screen.dart` |
| ٤ب | المستجيبون لطالب الدم + اتصال / واتساب / رسالة + إغلاق الطلب | نفس الملف |

منطق التوافق في `lib/core/blood_types.dart`، وكل التعامل مع قاعدة البيانات في
`lib/services/firestore_service.dart`.

## نموذج البيانات (Cloud Firestore)

```
users/{uid}                     name, phone, bloodType, city, area, isAvailable, createdAt
hospitals/{id}                  name, city, isActive, order          ← تديرها لوحة الإدارة
requests/{id}                   patientName, hospitalId, hospitalName, bloodType,
                                scope: exact|compatible, acceptedTypes[], units,
                                respondersCount, contactPhone, requesterId, city,
                                status: active|completed, createdAt, completedAt
requests/{id}/responders/{uid}  name, bloodType, area, phone, respondedAt
```

**التصفية الذكية:** عند إنشاء الطلب يُحسب `acceptedTypes`. إذا اختار المستخدم «الفصيلة فقط» تكون
القائمة هي الفصيلة المطلوبة وحدها، وإذا اختار «المتوافقة» تشمل كل الفصائل التي يمكنها التبرع لها.
بعدها تعرض الرئيسية الطلبات بالاستعلام:

```
status == 'active' && city == me.city && acceptedTypes array-contains me.bloodType
```

## التشغيل لأول مرة

المستودع يحتوي على `lib/` و`test/` وملفات Firebase فقط. مجلدات المنصات تُولَّد محلياً:

```bash
flutter create . --org com.example --platforms android,ios
```

```bash
flutter pub get
```

ربط Firebase (يولّد `lib/firebase_options.dart`):

```bash
dart pub global activate flutterfire_cli
```

```bash
flutterfire configure
```

في Firebase Console:
1. **Authentication → Sign-in method:** فعّل **Phone**. على أندرويد أضف بصمة SHA-1 وSHA-256
   للتطبيق في إعدادات المشروع.
2. **Firestore Database:** أنشئ قاعدة البيانات.

انشر القواعد والفهارس:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

أضف مستشفى واحداً على الأقل في مجموعة `hospitals` بالحقول `name` و`city: "عطبرة"`
و`isActive: true` و`order: 0`. لاحقاً يتم ذلك من لوحة الإدارة.

### إعداد url_launcher على أندرويد 11+

أضف داخل `<manifest>` في `android/app/src/main/AndroidManifest.xml`:

```xml
<queries>
  <intent><action android:name="android.intent.action.DIAL" /><data android:scheme="tel" /></intent>
  <intent><action android:name="android.intent.action.SENDTO" /><data android:scheme="sms" /></intent>
  <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>
</queries>
```

وعلى iOS أضف إلى `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array><string>tel</string><string>sms</string><string>https</string></array>
```

## الاختبارات

```bash
flutter test
```

## الأمان (firestore.rules)

- المستخدم يقرأ ويعدّل ملفه فقط، ولا يستطيع تغيير رقم هاتفه المُتحقق منه.
- المستشفيات للقراءة فقط، والكتابة للأدمن وحده.
- الطلب يغلقه صاحبه فقط. العداد `respondersCount` يزيد بواحد فقط، وفي نفس المعاملة التي يُنشأ فيها
  مستند المستجيب.
- لا يستجيب المتبرع إلا إذا كانت فصيلته المسجلة ضمن `acceptedTypes`. بيانات المستجيبين يراها طالب الدم
  والمتبرع نفسه والأدمن فقط.
- الأدمن يُعرَّف بـ Custom Claim اسمه `admin: true` (يُضبط عبر Admin SDK).

## الخطوة التالية

لوحة الإدارة على الويب (Firebase Hosting): الإحصاءات، مراقبة الطلبات وحذفها، وإدارة المستشفيات.

## لوحة الإدارة (ويب)

موجودة في مجلد `admin/`، وهي صفحة HTML/JavaScript ثابتة تستخدم Firebase JS SDK وتُستضاف على
Firebase Hosting. تحتوي على:

- **الإحصاءات:** إجمالي المستخدمين، المتبرعون المتاحون، الطلبات النشطة والمكتملة.
- **الطلبات:** جدول بآخر ٢٠٠ طلب مع بحث وتصفية حسب الحالة، وإمكانية إغلاق أي طلب أو حذفه.
  الحذف يشمل المستجيبين له.
- **المستشفيات:** إضافة مستشفى، تعديل اسمه، وإيقافه أو تفعيله. التغيير ينعكس فوراً على القائمة
  المنسدلة في التطبيق.

### الإعداد

1. في Firebase Console ← **Project settings ← Your apps** أضف تطبيق **Web**، وانسخ قيم
   `firebaseConfig` إلى `admin/config.js`.
2. في **Authentication ← Sign-in method** فعّل **Email/Password**.
3. في **Authentication ← Users** اضغط **Add user** وأنشئ حساب المدير.
4. امنح الحساب صلاحية الإدارة. نزّل مفتاح Service account من **Project settings ← Service accounts**
   واحفظه خارج المستودع، ثم:

```bash
cd scripts && npm install
```

```bash
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node set-admin.mjs admin@example.com
```

5. انشر اللوحة مع القواعد:

```bash
firebase deploy --only hosting,firestore:rules,firestore:indexes
```

ستعمل اللوحة على `https://<PROJECT_ID>.web.app`. لتجربتها محلياً:

```bash
firebase serve --only hosting
```

أي حساب لا يملك `admin: true` يُسجَّل خروجه تلقائياً، وقواعد Firestore ترفض عمليات الإدارة له
حتى لو تجاوز الواجهة.
