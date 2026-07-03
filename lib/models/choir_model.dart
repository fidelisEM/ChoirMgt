class ChoirModel {
  
  ChoirModel({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.adminId,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.memberCount = 0,
    this.imageUrl,
    this.tags = const [],
    this.location,
    this.schedule,
    this.country,
    this.diocese,
    this.parish,
  });

  factory ChoirModel.fromJson(Map<String, dynamic> json) {
    return ChoirModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      leaderId: json['leader_id'] ?? json['leaderId'] ?? '',
      adminId: json['admin_id'] ?? json['adminId'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
          : null,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      memberCount: json['member_count'] ?? json['memberCount'] ?? 0,
      imageUrl: json['image_url'] ?? json['imageUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      location: json['location'],
      schedule: json['schedule'],
      country: json['country'],
      diocese: json['diocese'],
      parish: json['parish'],
    );
  }
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final String adminId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int memberCount;
  final String? imageUrl;
  final List<String> tags;
  final String? location;
  final String? schedule;
  final String? country;
  final String? diocese;
  final String? parish;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'description': description,
      'leader_id': leaderId,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'member_count': memberCount,
      'image_url': imageUrl,
      'tags': tags,
    };
    
    // Include location fields if they have values
    if (location != null) json['location'] = location;
    if (schedule != null) json['schedule'] = schedule;
    if (country != null) json['country'] = country;
    if (diocese != null) json['diocese'] = diocese;
    if (parish != null) json['parish'] = parish;
    
    // Only include id if it's not empty (for updates, not creation)
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }

  ChoirModel copyWith({
    String? id,
    String? name,
    String? description,
    String? leaderId,
    String? adminId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? memberCount,
    String? imageUrl,
    List<String>? tags,
    String? location,
    String? schedule,
    String? country,
    String? diocese,
    String? parish,
  }) {
    return ChoirModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      leaderId: leaderId ?? this.leaderId,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      schedule: schedule ?? this.schedule,
      country: country ?? this.country,
      diocese: diocese ?? this.diocese,
      parish: parish ?? this.parish,
    );
  }
}