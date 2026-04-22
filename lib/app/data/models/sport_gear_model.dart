class SportGear {
  const SportGear({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.specifications,
    this.suitableFor,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String imageUrl;
  final String description;
  final Map<String, String> specifications;
  final List<String>? suitableFor;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'description': description,
      'specifications': specifications,
      'suitable_for': suitableFor,
    };
  }

  factory SportGear.fromMap(Map<String, dynamic> map) {
    return SportGear(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      category: map['category'] as String? ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: (map['image_url'] ?? map['imageUrl']) as String? ?? '',
      description: map['description'] as String? ?? '',
      specifications:
          Map<String, String>.from(map['specifications'] as Map? ?? {}),
      suitableFor: map['suitable_for'] != null
          ? List<String>.from(map['suitable_for'])
          : null,
    );
  }
}
