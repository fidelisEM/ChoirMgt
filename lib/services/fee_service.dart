import 'package:uuid/uuid.dart';

import '../models/fee_model.dart';
import '../services/member_service.dart';
import '../utils/logger.dart';

class FeeService {
  factory FeeService() => _instance;
  FeeService._internal();
  static final FeeService _instance = FeeService._internal();

  final MemberService _memberService = MemberService();
  final List<FeeDefinitionModel> _feeDefinitions = [];
  final List<MemberFeeModel> _memberFees = [];
  final List<FeePaymentModel> _payments = [];
  final Uuid _uuid = const Uuid();

  // Fee Definition Management
  Future<FeeDefinitionModel> createFeeDefinition({
    required String choirId,
    required String name,
    required String description,
    required double amount,
    required FeeType type,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final feeDefinition = FeeDefinitionModel(
        id: _uuid.v4(),
        choirId: choirId,
        name: name,
        description: description,
        amount: amount,
        type: type,
        createdAt: DateTime.now(),
        startDate: startDate,
        endDate: endDate,
        category: category,
        metadata: metadata ?? {},
      );

      _feeDefinitions.add(feeDefinition);

      // Auto-generate member fees for all current members
      await _generateMemberFeesForDefinition(feeDefinition);

      Logger.info('Created fee definition: ${feeDefinition.name}');
      return feeDefinition;
    } catch (e, stackTrace) {
      Logger.error('Failed to create fee definition', e, stackTrace);
      rethrow;
    }
  }

  Future<List<FeeDefinitionModel>> getChoirFeeDefinitions(
    String choirId,
  ) async {
    return _feeDefinitions.where((fee) => fee.choirId == choirId).toList();
  }

  Future<FeeDefinitionModel?> updateFeeDefinition(
    String feeId, {
    String? name,
    String? description,
    double? amount,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final index = _feeDefinitions.indexWhere((fee) => fee.id == feeId);
      if (index == -1) return null;

      final updatedFee = _feeDefinitions[index].copyWith(
        name: name,
        description: description,
        amount: amount,
        isActive: isActive,
        startDate: startDate,
        endDate: endDate,
        category: category,
        metadata: metadata,
      );

      _feeDefinitions[index] = updatedFee;

      // Update existing member fees if amount changed
      if (amount != null && amount != _feeDefinitions[index].amount) {
        await _updateMemberFeesForDefinition(updatedFee);
      }

      Logger.info('Updated fee definition: ${updatedFee.name}');
      return updatedFee;
    } catch (e, stackTrace) {
      Logger.error('Failed to update fee definition', e, stackTrace);
      return null;
    }
  }

  Future<bool> deleteFeeDefinition(String feeId) async {
    try {
      final index = _feeDefinitions.indexWhere((fee) => fee.id == feeId);
      if (index == -1) return false;

      // Remove related member fees
      _memberFees.removeWhere((fee) => fee.feeDefinitionId == feeId);
      _payments.removeWhere((payment) {
        final memberFee = _memberFees.firstWhere(
          (fee) => fee.id == payment.memberFeeId,
          orElse: () => MemberFeeModel(
            id: '',
            memberId: '',
            feeDefinitionId: '',
            choirId: '',
            amountDue: 0,
            dueDate: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
        return memberFee.feeDefinitionId == feeId;
      });

      _feeDefinitions.removeAt(index);
      Logger.info('Deleted fee definition: $feeId');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Failed to delete fee definition', e, stackTrace);
      return false;
    }
  }

  // Member Fee Management
  Future<void> _generateMemberFeesForDefinition(
    FeeDefinitionModel feeDefinition,
  ) async {
    try {
      final members = await _memberService.getChoirMembersWithUserInfo(
        feeDefinition.choirId,
      );

      for (final member in members) {
        final dueDate = _calculateDueDate(feeDefinition);
        if (dueDate != null) {
          await _createMemberFee(
            memberId: member['id'],
            feeDefinition: feeDefinition,
            dueDate: dueDate,
          );
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to generate member fees', e, stackTrace);
    }
  }

  Future<void> _updateMemberFeesForDefinition(
    FeeDefinitionModel feeDefinition,
  ) async {
    try {
      final memberFees = _memberFees
          .where(
            (fee) =>
                fee.feeDefinitionId == feeDefinition.id &&
                fee.status == FeeStatus.pending,
          )
          .toList();

      for (final memberFee in memberFees) {
        final index = _memberFees.indexWhere((fee) => fee.id == memberFee.id);
        if (index != -1) {
          _memberFees[index] = memberFee.copyWith(
            amountDue: feeDefinition.amount,
          );
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to update member fees', e, stackTrace);
    }
  }

  Future<MemberFeeModel> _createMemberFee({
    required String memberId,
    required FeeDefinitionModel feeDefinition,
    required DateTime dueDate,
  }) async {
    final memberFee = MemberFeeModel(
      id: _uuid.v4(),
      memberId: memberId,
      feeDefinitionId: feeDefinition.id,
      choirId: feeDefinition.choirId,
      amountDue: feeDefinition.amount,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );

    _memberFees.add(memberFee);
    return memberFee;
  }

  DateTime? _calculateDueDate(FeeDefinitionModel feeDefinition) {
    final now = DateTime.now();

    switch (feeDefinition.type) {
      case FeeType.weekly:
        return now.add(const Duration(days: 7));
      case FeeType.monthly:
        return DateTime(now.year, now.month + 1, 1);
      case FeeType.quarterly:
        return DateTime(now.year, now.month + 3, 1);
      case FeeType.annual:
        return DateTime(now.year + 1, now.month, 1);
      case FeeType.oneTime:
        return feeDefinition.startDate ?? now;
      case FeeType.event:
        return feeDefinition.startDate;
    }
  }

  Future<List<MemberFeeModel>> getMemberFees(String memberId) async {
    return _memberFees.where((fee) => fee.memberId == memberId).toList();
  }

  Future<List<MemberFeeModel>> getChoirFees(String choirId) async {
    return _memberFees.where((fee) => fee.choirId == choirId).toList();
  }

  Future<List<MemberFeeModel>> getOverdueFees(String choirId) async {
    final now = DateTime.now();
    return _memberFees
        .where(
          (fee) =>
              fee.choirId == choirId &&
              fee.dueDate.isBefore(now) &&
              !fee.isPaid,
        )
        .toList();
  }

  // Payment Processing
  Future<FeePaymentModel> recordPayment({
    required String memberFeeId,
    required double amount,
    required String paymentMethod,
    required String recordedBy,
    String? reference,
    String? notes,
    DateTime? paidAt,
  }) async {
    try {
      final memberFeeIndex = _memberFees.indexWhere(
        (fee) => fee.id == memberFeeId,
      );
      if (memberFeeIndex == -1) {
        throw Exception('Member fee not found');
      }

      final memberFee = _memberFees[memberFeeIndex];
      final payment = FeePaymentModel(
        id: _uuid.v4(),
        memberFeeId: memberFeeId,
        memberId: memberFee.memberId,
        choirId: memberFee.choirId,
        amount: amount,
        paidAt: paidAt ?? DateTime.now(),
        paymentMethod: paymentMethod,
        reference: reference,
        notes: notes,
        recordedBy: recordedBy,
      );

      _payments.add(payment);

      // Update member fee
      final newAmountPaid = memberFee.amountPaid + amount;
      final newStatus = _calculateFeeStatus(
        memberFee.amountDue,
        newAmountPaid,
        memberFee.dueDate,
      );

      _memberFees[memberFeeIndex] = memberFee.copyWith(
        amountPaid: newAmountPaid,
        status: newStatus,
        paidAt: newStatus == FeeStatus.paid ? payment.paidAt : null,
        paymentReference: newStatus == FeeStatus.paid
            ? payment.reference
            : null,
      );

      Logger.info(
        'Recorded payment: \$$amount for member ${memberFee.memberId}',
      );
      return payment;
    } catch (e, stackTrace) {
      Logger.error('Failed to record payment', e, stackTrace);
      rethrow;
    }
  }

  FeeStatus _calculateFeeStatus(
    double amountDue,
    double amountPaid,
    DateTime dueDate,
  ) {
    final isPaid = amountPaid >= amountDue;
    final isOverdue = DateTime.now().isAfter(dueDate);
    final hasPartialPayment = amountPaid > 0 && amountPaid < amountDue;

    if (isPaid) {
      return FeeStatus.paid;
    } else if (hasPartialPayment) {
      return FeeStatus.partial;
    } else if (isOverdue) {
      return FeeStatus.overdue;
    } else {
      return FeeStatus.pending;
    }
  }

  Future<List<FeePaymentModel>> getMemberPayments(String memberId) async {
    return _payments.where((payment) => payment.memberId == memberId).toList();
  }

  Future<List<FeePaymentModel>> getChoirPayments(String choirId) async {
    return _payments.where((payment) => payment.choirId == choirId).toList();
  }

  // Fee Statistics and Reports
  Future<Map<String, dynamic>> getChoirFeeStatistics(String choirId) async {
    final fees = await getChoirFees(choirId);
    final payments = await getChoirPayments(choirId);

    final totalDue = fees.fold<double>(0, (sum, fee) => sum + fee.amountDue);
    final totalPaid = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final totalOutstanding = fees.fold<double>(
      0,
      (sum, fee) => sum + fee.outstandingAmount,
    );

    final paidFees = fees.where((fee) => fee.isPaid).length;
    final overdueFees = fees.where((fee) => fee.isOverdue).length;
    final partialFees = fees.where((fee) => fee.isPartial).length;

    return {
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'totalOutstanding': totalOutstanding,
      'collectionRate': totalDue > 0 ? (totalPaid / totalDue) * 100 : 0,
      'totalFees': fees.length,
      'paidFees': paidFees,
      'overdueFees': overdueFees,
      'partialFees': partialFees,
      'pendingFees': fees.length - paidFees - overdueFees - partialFees,
      'avgPaymentTime': _calculateAveragePaymentTime(fees),
    };
  }

  double _calculateAveragePaymentTime(List<MemberFeeModel> fees) {
    final paidFees = fees
        .where((fee) => fee.isPaid && fee.paidAt != null)
        .toList();
    if (paidFees.isEmpty) return 0;

    final totalDays = paidFees.fold<int>(0, (sum, fee) {
      return sum + fee.paidAt!.difference(fee.dueDate).inDays;
    });

    return totalDays / paidFees.length;
  }

  // Automated Fee Generation
  Future<void> generateRecurringFees(String choirId) async {
    try {
      final feeDefinitions = await getChoirFeeDefinitions(choirId);
      final recurringDefinitions = feeDefinitions
          .where(
            (def) =>
                def.isActive &&
                def.type != FeeType.oneTime &&
                def.type != FeeType.event,
          )
          .toList();

      for (final definition in recurringDefinitions) {
        await _generateNextRecurringFee(definition);
      }

      Logger.info('Generated recurring fees for choir: $choirId');
    } catch (e, stackTrace) {
      Logger.error('Failed to generate recurring fees', e, stackTrace);
    }
  }

  Future<void> _generateNextRecurringFee(FeeDefinitionModel definition) async {
    final members = await _memberService.getChoirMembersWithUserInfo(
      definition.choirId,
    );
    final nextDueDate = definition.getNextDueDate();

    if (nextDueDate == null) return;

    for (final member in members) {
      // Check if member already has a fee for this period
      final existingFee = _memberFees.firstWhere(
        (fee) =>
            fee.memberId == member['id'] &&
            fee.feeDefinitionId == definition.id &&
            _isSamePeriod(fee.dueDate, nextDueDate, definition.type),
        orElse: () => MemberFeeModel(
          id: '',
          memberId: '',
          feeDefinitionId: '',
          choirId: '',
          amountDue: 0,
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      if (existingFee.id.isEmpty) {
        await _createMemberFee(
          memberId: member['id'],
          feeDefinition: definition,
          dueDate: nextDueDate,
        );
      }
    }
  }

  bool _isSamePeriod(DateTime date1, DateTime date2, FeeType type) {
    switch (type) {
      case FeeType.weekly:
        return _isSameWeek(date1, date2);
      case FeeType.monthly:
        return date1.year == date2.year && date1.month == date2.month;
      case FeeType.quarterly:
        return date1.year == date2.year &&
            _getQuarter(date1) == _getQuarter(date2);
      case FeeType.annual:
        return date1.year == date2.year;
      case FeeType.oneTime:
      case FeeType.event:
        return false;
    }
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final diff = date1.difference(date2).inDays.abs();
    return diff < 7;
  }

  int _getQuarter(DateTime date) {
    return ((date.month - 1) / 3).floor() + 1;
  }
}
