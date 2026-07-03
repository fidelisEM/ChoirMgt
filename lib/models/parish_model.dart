class ParishModel {

  ParishModel({
    required this.id,
    required this.name,
    required this.code,
    required this.archdioceseId,
    required this.archdioceseName,
    this.address,
    this.phoneNumber,
    this.email,
    this.pastor,
    required this.createdAt,
    this.isActive = true,
  });

  factory ParishModel.fromJson(Map<String, dynamic> json) {
    return ParishModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      archdioceseId: json['archdiocese_id'] ?? '',
      archdioceseName: json['archdiocese_name'] ?? '',
      address: json['address'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      pastor: json['pastor'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? true,
    );
  }
  final String id;
  final String name;
  final String code;
  final String archdioceseId;
  final String archdioceseName;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? pastor;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'archdiocese_id': archdioceseId,
      'archdiocese_name': archdioceseName,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'pastor': pastor,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  ParishModel copyWith({
    String? id,
    String? name,
    String? code,
    String? archdioceseId,
    String? archdioceseName,
    String? address,
    String? phoneNumber,
    String? email,
    String? pastor,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ParishModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      archdioceseId: archdioceseId ?? this.archdioceseId,
      archdioceseName: archdioceseName ?? this.archdioceseName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      pastor: pastor ?? this.pastor,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}