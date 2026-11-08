class Listing {
  final String id;
  final String userId;
  final String categoryId;
  final String title;
  final String description;
  final String? descriptionEn;
  final double? price;
  final String priceType;
  final String? cityId;
  final double? lat;
  final double? lng;
  final String? whatsapp;
  final String status;
  final bool isFeatured;
  final int views;
  final List<String> imageUrls;
  final double? avgRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? userName;
  final String? userAvatarUrl;
  final String? categoryName;
  final String? cityName;

  const Listing({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.description,
    this.descriptionEn,
    this.price,
    this.priceType = 'negotiable',
    this.cityId,
    this.lat,
    this.lng,
    this.whatsapp,
    this.status = 'active',
    this.isFeatured = false,
    this.views = 0,
    this.imageUrls = const [],
    this.avgRating,
    this.reviewCount = 0,
    required this.createdAt,
    required this.expiresAt,
    this.userName,
    this.userAvatarUrl,
    this.categoryName,
    this.cityName,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    List<String> parseImages() {
      if (json['imageUrls'] is List) {
        return (json['imageUrls'] as List).map((e) => e.toString()).toList();
      }
      if (json['images'] is List) {
        return (json['images'] as List).map((e) => e is Map ? (e['url']?.toString() ?? '') : e.toString()).where((s) => s.isNotEmpty).toList();
      }
      if (json['image_urls'] is String) {
        try {
          final parsed = List<dynamic>.from(json['image_urls'] is String ? (json['image_urls'].startsWith('[') ? (json['image_urls'] as String).replaceAll('"', '').replaceAll('[', '').replaceAll(']', '').split(',') : []) : []);
          return parsed.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        } catch (_) {}
      }
      if (json['main_image'] != null && json['main_image'].toString().isNotEmpty) {
        return [json['main_image'].toString()];
      }
      return [];
    }

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      return val.toString().toLowerCase() == 'true' || val.toString() == '1';
    }

    return Listing(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? json['category_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      descriptionEn: (json['descriptionEn'] ?? json['description_en'])?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      priceType: (json['priceType'] ?? json['price_type'] ?? 'negotiable').toString(),
      cityId: (json['cityId'] ?? json['city_id'])?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      whatsapp: (json['whatsapp'])?.toString(),
      status: (json['status'] ?? 'active').toString(),
      isFeatured: parseBool(json['isFeatured'] ?? json['is_featured']),
      views: (json['views'] as num?)?.toInt() ?? 0,
      imageUrls: parseImages(),
      avgRating: (json['avgRating'] ?? json['avg_rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] ?? json['review_count'] as num?)?.toInt() ?? 0,
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
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'descriptionEn': descriptionEn,
      'price': price,
      'priceType': priceType,
      'cityId': cityId,
      'lat': lat,
      'lng': lng,
      'whatsapp': whatsapp,
      'status': status,
      'isFeatured': isFeatured,
      'views': views,
      'imageUrls': imageUrls,
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'categoryName': categoryName,
      'cityName': cityName,
    };
  }

  Listing copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    String? description,
    String? descriptionEn,
    double? price,
    String? priceType,
    String? cityId,
    double? lat,
    double? lng,
    String? whatsapp,
    String? status,
    bool? isFeatured,
    int? views,
    List<String>? imageUrls,
    double? avgRating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? userName,
    String? userAvatarUrl,
    String? categoryName,
    String? cityName,
  }) {
    return Listing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      cityId: cityId ?? this.cityId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      whatsapp: whatsapp ?? this.whatsapp,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      views: views ?? this.views,
      imageUrls: imageUrls ?? this.imageUrls,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      categoryName: categoryName ?? this.categoryName,
      cityName: cityName ?? this.cityName,
    );
  }

  String get formattedPrice {
    if (price == null || priceType == 'negotiable') return 'A convenir';
    final formatted = price!.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    switch (priceType) {
      case 'hourly':
        return '\$$formatted/h';
      case 'daily':
        return '\$$formatted/día';
      default:
        return '\$$formatted';
    }
  }

  @override
  String toString() => 'Listing(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Listing && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
