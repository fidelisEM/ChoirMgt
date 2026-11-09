import 'package:choir_management_system/controllers/payment_controller.dart';
import 'package:choir_management_system/models/models.dart';
import 'package:choir_management_system/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePaymentService implements PaymentService {
  List<Map<String, dynamic>> payments = [];
  bool createSucceeds = true;
  bool statusUpdateSucceeds = true;
  bool deleteSucceeds = true;
  Object? throwOnList;
  int listCalls = 0;

  @override
  Future<PaymentModel?> createPayment({
    required String choirId,
    required String memberId,
    required String userId,
    required double amount,
    required PaymentType type,
    required PaymentMethod method,
    required String description,
    String? reference,
    String? receivedBy,
    String currency = 'TZS',
  }) async {
    if (!createSucceeds) return null;
    payments.add({
      'id': 'p${payments.length + 1}',
      'amount': amount,
      'status': 'completed',
    });
    return PaymentModel(
      id: 'p${payments.length}',
      choirId: choirId,
      memberId: memberId,
      userId: userId,
      amount: amount,
      type: type,
      method: method,
      description: description,
      paymentDate: DateTime.utc(2026),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getChoirPayments({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
    PaymentStatus? status,
    PaymentType? type,
  }) async {
    listCalls++;
    if (throwOnList != null) throw throwOnList!;
    return payments.map((p) => Map<String, dynamic>.from(p)).toList();
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatistics({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async => {'total_payments': payments.length};

  @override
  Future<List<Map<String, dynamic>>> getOutstandingFees(String choirId) async =>
      [];

  @override
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? notes,
  }) async => statusUpdateSucceeds;

  @override
  Future<bool> deletePayment(String paymentId) async {
    if (!deleteSucceeds) return false;
    payments.removeWhere((p) => p['id'] == paymentId);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakePaymentService service;
  late PaymentController controller;

  setUp(() {
    service = FakePaymentService();
    controller = PaymentController(paymentService: service);
  });

  Future<bool> create() => controller.createPayment(
    choirId: 'c1',
    memberId: 'm1',
    userId: 'u1',
    amount: 100,
    type: PaymentType.monthly,
    method: PaymentMethod.cash,
    description: 'dues',
  );

  test('createPayment reloads the list on success', () async {
    expect(await create(), isTrue);
    expect(controller.payments, hasLength(1));
    expect(controller.paymentStats['total_payments'], 1);
    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('createPayment reports failure and sets an error', () async {
    service.createSucceeds = false;

    expect(await create(), isFalse);
    expect(controller.payments, isEmpty);
    expect(controller.errorMessage, isNotNull);
    expect(controller.isLoading, isFalse);
  });

  test('loadChoirPayments surfaces service exceptions', () async {
    service.throwOnList = Exception('boom');

    await controller.loadChoirPayments(choirId: 'c1');

    expect(controller.errorMessage, contains('boom'));
    expect(controller.isLoading, isFalse);
  });

  test('updatePaymentStatus updates the local copy', () async {
    await create();

    final ok = await controller.updatePaymentStatus(
      paymentId: 'p1',
      status: PaymentStatus.refunded,
      choirId: 'c1',
    );

    expect(ok, isTrue);
    expect(controller.getPaymentById('p1')!['status'], 'refunded');
  });

  test('updatePaymentStatus leaves local data alone on failure', () async {
    await create();
    service.statusUpdateSucceeds = false;

    final ok = await controller.updatePaymentStatus(
      paymentId: 'p1',
      status: PaymentStatus.refunded,
      choirId: 'c1',
    );

    expect(ok, isFalse);
    expect(controller.getPaymentById('p1')!['status'], 'completed');
    expect(controller.errorMessage, isNotNull);
  });

  test('deletePayment removes the payment and refreshes the list', () async {
    await create();
    await create();
    expect(controller.payments, hasLength(2));

    final ok = await controller.deletePayment(paymentId: 'p1', choirId: 'c1');

    expect(ok, isTrue);
    expect(controller.payments.map((p) => p['id']), ['p2']);
    expect(controller.paymentStats['total_payments'], 1);
  });

  test(
    'deletePayment keeps the list and reports an error on failure',
    () async {
      await create();
      service.deleteSucceeds = false;

      final ok = await controller.deletePayment(paymentId: 'p1', choirId: 'c1');

      expect(ok, isFalse);
      expect(controller.payments, hasLength(1));
      expect(controller.errorMessage, isNotNull);
      expect(controller.isLoading, isFalse);
    },
  );
}
