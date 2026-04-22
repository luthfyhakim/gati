class GearCategory {
  final String id;
  final String name;

  GearCategory({required this.id, required this.name});

  factory GearCategory.fromMap(Map<String, dynamic> map) {
    return GearCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}

class GearSubcategory {
  final String id;
  final String categoryName;
  final String name;

  GearSubcategory({
    required this.id,
    required this.categoryName,
    required this.name,
  });

  factory GearSubcategory.fromMap(Map<String, dynamic> map) {
    return GearSubcategory(
      id: map['id'] ?? '',
      categoryName: map['category_name'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
