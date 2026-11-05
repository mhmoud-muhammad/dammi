/// فصائل الدم وقواعد التوافق الطبي (كريات الدم الحمراء).
library;

const List<String> kBloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

/// لكل فصيلة مريض: الفصائل التي يمكنها التبرع له.
const Map<String, List<String>> _donorsFor = {
  'O-': ['O-'],
  'O+': ['O+', 'O-'],
  'A-': ['A-', 'O-'],
  'A+': ['A+', 'A-', 'O+', 'O-'],
  'B-': ['B-', 'O-'],
  'B+': ['B+', 'B-', 'O+', 'O-'],
  'AB-': ['AB-', 'A-', 'B-', 'O-'],
  'AB+': ['AB+', 'AB-', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-'],
};

/// نطاق البحث عند إنشاء الطلب.
enum SearchScope {
  /// الفصيلة المطلوبة وحدها.
  exact,

  /// كل الفصائل المتوافقة طبياً.
  compatible;

  String get label => this == exact ? 'الفصيلة المطلوبة فقط' : 'الفصائل المتوافقة';

  static SearchScope fromName(String? name) =>
      name == 'exact' ? SearchScope.exact : SearchScope.compatible;
}

/// الفصائل التي يمكنها التبرع لمريض فصيلته [recipient].
List<String> donorsFor(String recipient) =>
    List.unmodifiable(_donorsFor[recipient] ?? [recipient]);

/// الفصائل التي يستطيع المتبرع [donor] أن يعطيها.
List<String> recipientsFor(String donor) =>
    kBloodTypes.where((r) => _donorsFor[r]!.contains(donor)).toList();

/// قائمة الفصائل المقبولة التي تُحفظ في الطلب (`acceptedTypes`).
List<String> acceptedTypesFor(String bloodType, SearchScope scope) =>
    scope == SearchScope.exact ? [bloodType] : donorsFor(bloodType);
