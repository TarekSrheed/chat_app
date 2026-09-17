import 'package:chat_app/features/data/remote/service/database_service.dart';
import 'package:chat_app/features/view/cubit/categories/categories_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit() : super(CategoriesInitial());

  Future<void> fetchCategories() async {
    emit(CategoriesLoading());
    try {
      final categories = await DatabaseService().getCategories();
      emit(CategoriesSuccess(categories: categories));
    } catch (e) {
      emit(CategoriesError(message: "Error fetching categories: $e"));
    }
  }
}