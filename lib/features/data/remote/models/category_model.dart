// ignore_for_file: public_member_api_docs, sort_constructors_first

class CategoryModel {
  final String? id;
  final String categoryName;
  final String imageUrl;

  CategoryModel({
    this.id,
    required this.categoryName,
    required this.imageUrl,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] != null ? map['id'] as String : null,
      categoryName: map['categoryName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
