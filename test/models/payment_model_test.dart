import 'package:choir_management_system/models/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentModel.fromJson', () {
    test('parses snake_case keys from Supabase', () {
      final payment = PaymentModel.fromJson({
        'id': 'p1',
        'choir_id': 'c1',
        'member_id': 'm1',
        'user_id': 'u1',
        'amount': 5000,
        'type': 'monthly',
        'method': 'mobilePayment',
        'description': 'March dues',
        'status': 'pending',
        'payment_date': '2026-03-01T10:00:00.000Z',
        'currency': 'KES',
      });

      expect(payment.choirId, 'c1');
      expect(payment.memberId, 'm1');
      expect(payment.amount, 5000.0);
      expect(payment.type, PaymentType.monthly);
      expect(payment.method, PaymentMethod.mobilePayment);
      expect(payment.status, PaymentStatus.pending);
      expect(payment.currency, 'KES');
    });

    test('falls back to defaults for missing or unknown values', () {
      final payment = PaymentModel.fromJson({
        'type': 'nonsense',
        'method': 'nonsense',
        'status': 'nonsense',
      });

      expect(payment.id, '');
      expect(payment.amount, 0.0);
      expect(payment.type, PaymentType.other);
      expect(payment.method, PaymentMethod.cash);
      expect(payment.status, PaymentStatus.completed);
      expect(payment.currency, 'TZS');
    });
  });

  group('PaymentModel.toJson', () {
    test('round-trips through fromJson', () {
      final original = PaymentModel(
        id: 'p1',
        choirId: 'c1',
        memberId: 'm1',
        userId: 'u1',
        amount: 1234.5,
        type: PaymentType.special,
        method: PaymentMethod.bankTransfer,
        description: 'Concert fund',
        reference: 'REF-1',
        status: PaymentStatus.refunded,
        paymentDate: DateTime.utc(2026, 3, 1, 10),
        receivedBy: 'treasurer',
        notes: 'n',
      );

      final copy = PaymentModel.fromJson(original.toJson());

      expect(copy.toJson(), original.toJson());
    });
  });

  group('PaymentModel.copyWith', () {
    test('changes only the given fields', () {
      final payment = PaymentModel(
        id: 'p1',
        choirId: 'c1',
        memberId: 'm1',
        userId: 'u1',
        amount: 100,
        type: PaymentType.monthly,
        method: PaymentMethod.cash,
        description: 'd',
        paymentDate: DateTime.utc(2026),
      );

      final updated = payment.copyWith(status: PaymentStatus.failed);

      expect(updated.status, PaymentStatus.failed);
      expect(updated.amount, 100);
      expect(updated.id, 'p1');
    });
  });
}
