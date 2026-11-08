import 'package:flutter/material.dart';

class Category {
  final String id;
  final String? parentId;
  final String nameEs;
  final String nameEn;
  final String? icon;
  final String? color;
  final List<Category> subcategories;

  const Category({
    required this.id,
    this.parentId,
    required this.nameEs,
    required this.nameEn,
    this.icon,
    this.color,
    this.subcategories = const [],
  });

  IconData get materialIcon {
    switch (id.toLowerCase()) {
      case 'servicios':
      case 'mudanzas':
        return Icons.local_shipping_outlined;
      case 'plomeria':
        return Icons.plumbing_outlined;
      case 'electricidad':
        return Icons.electric_bolt_outlined;
      case 'pintura':
        return Icons.format_paint_outlined;
      case 'limpieza':
        return Icons.cleaning_services_outlined;
      case 'jardineria':
        return Icons.yard_outlined;
      case 'vivienda':
      case 'arriendos':
      case 'venta':
      case 'habitaciones':
        return Icons.home_outlined;
      case 'empleos':
      case 'tiempo-completo':
      case 'tiempo-parcial':
      case 'freelance':
        return Icons.work_outlined;
      case 'vehiculos':
        return Icons.directions_car_outlined;
      case 'segunda-mano':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      parentId: (json['parentId'] ?? json['parent_id']) as String?,
      nameEs: (json['nameEs'] ?? json['name_es'] ?? '') as String,
      nameEn: (json['nameEn'] ?? json['name_en'] ?? '') as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'nameEs': nameEs,
      'nameEn': nameEn,
      'icon': icon,
      'color': color,
      'subcategories': subcategories.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Category(id: $id, nameEs: $nameEs)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
