class ArchdioceseModel {
  ArchdioceseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.country,
    this.description,
    this.bishop,
    required this.createdAt,
    this.isActive = true,
  });

  factory ArchdioceseModel.fromJson(Map<String, dynamic> json) {
    return ArchdioceseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      country: json['country'] ?? '',
      description: json['description'],
      bishop: json['bishop'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['is_active'] ?? true,
    );
  }
  final String id;
  final String name;
  final String code;
  final String country;
  final String? description;
  final String? bishop;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'country': country,
      'description': description,
      'bishop': bishop,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  ArchdioceseModel copyWith({
    String? id,
    String? name,
    String? code,
    String? country,
    String? description,
    String? bishop,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ArchdioceseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      country: country ?? this.country,
      description: description ?? this.description,
      bishop: bishop ?? this.bishop,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
