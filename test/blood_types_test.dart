import 'package:blood_donation_app/core/blood_types.dart';
import 'package:blood_donation_app/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('donorsFor', () {
    test('O- receives only from O-', () {
      expect(donorsFor('O-'), ['O-']);
    });

    test('AB+ receives from everyone', () {
      expect(donorsFor('AB+').toSet(), kBloodTypes.toSet());
    });

    test('A+ receives from A+, A-, O+, O-', () {
      expect(donorsFor('A+').toSet(), {'A+', 'A-', 'O+', 'O-'});
    });
  });

  group('recipientsFor', () {
    test('O- donates to everyone', () {
      expect(recipientsFor('O-').toSet(), kBloodTypes.toSet());
    });

    test('O+ donates to positive types', () {
      expect(recipientsFor('O+').toSet(), {'O+', 'A+', 'B+', 'AB+'});
    });

    test('AB+ donates only to AB+', () {
      expect(recipientsFor('AB+'), ['AB+']);
    });

    test('is the inverse of donorsFor', () {
      for (final donor in kBloodTypes) {
        for (final recipient in kBloodTypes) {
          expect(
            recipientsFor(donor).contains(recipient),
            donorsFor(recipient).contains(donor),
            reason: '$donor -> $recipient',
          );
        }
      }
    });
  });

  group('acceptedTypesFor', () {
    test('exact scope keeps only the requested type', () {
      expect(acceptedTypesFor('B+', SearchScope.exact), ['B+']);
    });

    test('compatible scope expands to all compatible donors', () {
      expect(acceptedTypesFor('B+', SearchScope.compatible).toSet(), {'B+', 'B-', 'O+', 'O-'});
    });
  });

  group('normalizePhone', () {
    test('local formats become international', () {
      expect(normalizePhone('0912345678'), '+249912345678');
      expect(normalizePhone('912 345 678'), '+249912345678');
      expect(normalizePhone('+249912345678'), '+249912345678');
      expect(normalizePhone('00249912345678'), '+249912345678');
    });

    test('validation', () {
      expect(isValidLocalPhone('0912345678'), isTrue);
      expect(isValidLocalPhone('12345'), isFalse);
    });
  });

  test('timeAgo', () {
    final now = DateTime(2026, 1, 1, 12);
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), 'منذ ٥ د');
    expect(timeAgo(now.subtract(const Duration(hours: 1)), now: now), 'منذ ساعة');
  });
}
