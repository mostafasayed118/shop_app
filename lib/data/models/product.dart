import 'package:equatable/equatable.dart';

/// A catalogue product. Immutable and value-comparable via [Equatable].
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageAsset,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageAsset: json['imageAsset'] as String,
      category: json['category'] as String? ?? 'General',
    );
  }

  final String id;
  final String name;
  final String description;
  final double price;

  /// Path of the bundled placeholder image, e.g. `assets/images/product_1.png`.
  final String imageAsset;
  final String category;

  /// Serializes a full product snapshot so a persisted cart can be restored
  /// without depending on the catalogue having loaded first.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'imageAsset': imageAsset,
    'category': category,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    imageAsset,
    category,
  ];
}
