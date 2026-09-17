import 'package:chat_app/features/data/remote/models/category_model.dart';

abstract class CategoriesState {}
class CategoriesInitial extends CategoriesState {}
class CategoriesLoading extends CategoriesState {}
class CategoriesSuccess extends CategoriesState {
  final List<CategoryModel> categories;

  CategoriesSuccess({required this.categories});
}
class CategoriesError extends CategoriesState {
  final String message;

  CategoriesError({required this.message});
}