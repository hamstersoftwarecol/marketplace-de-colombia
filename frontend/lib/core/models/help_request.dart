class HelpRequest {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? categoryId;
  final String? cityId;
  final double? budgetMin;
  final double? budgetMax;
  final String status;
  final int offersCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? userName;
  final String? userAvatarUrl;
  final String? categoryName;
  final String? cityName;

  const HelpRequest({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.categoryId,
    this.cityId,
    this.budgetMin,
    this.budgetMax,
    this.status = 'open',
    this.offersCount = 0,
    required this.createdAt,
    required this.expiresAt,
    this.userName,
    this.userAvatarUrl,
    this.categoryName,
    this.cityName,
  });

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final rawBudget = (json['budget'] ?? json['budgetMin']) as num?;

    return HelpRequest(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? json['category_id'])?.toString(),
      cityId: (json['cityId'] ?? json['city_id'])?.toString(),
      budgetMin: rawBudget?.toDouble(),
      budgetMax: (json['budgetMax'] as num?)?.toDouble() ?? rawBudget?.toDouble(),
      status: (json['status'] ?? 'open').toString(),
      offersCount: (json['offersCount'] ?? json['proposals_count'] ?? 0) as int,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      expiresAt: parseDate(json['expiresAt'] ?? json['expires_at']),
      userName: (json['userName'] ?? json['user_name'])?.toString(),
      userAvatarUrl: (json['userAvatarUrl'] ?? json['user_avatar_url'])?.toString(),
      categoryName: (json['categoryName'] ?? json['category_name'])?.toString(),
      cityName: (json['cityName'] ?? json['city_name'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'cityId': cityId,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'status': status,
      'offersCount': offersCount,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'categoryName': categoryName,
      'cityName': cityName,
    };
  }
}
