import 'package:chat_app/features/view/cubit/categories/categories_state.dart';
import 'package:chat_app/features/view/cubit/categories/categoris_cubit.dart';
import 'package:chat_app/features/view/widgets/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/category_item.dart';

class CategoriesScreen extends StatelessWidget {
  final String userName;
  final String email;
  const CategoriesScreen(
      {super.key, required this.email, required this.userName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoriesCubit()..fetchCategories(),
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            children: [
              Text(
                "Find the best groups",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                " that work for you",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        drawer: myDrawer(context,
            userName: userName, email: email, currentRoute: "Categories"),
        body: BlocConsumer<CategoriesCubit, CategoriesState>(
          listener: (context, state) {
            if (state is CategoriesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is CategoriesLoading) {
                return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
            }

            if (state is CategoriesSuccess) {
              final categories = state.categories;
              return GridView.builder(
                padding: const EdgeInsets.all(10.0),
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  childAspectRatio: 7 / 8,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (ctx, index) {
                  final category = categories[index];
                  return CategoryItem(
                    title: category.categoryName,
                    imageUrl: category.imageUrl,
                  );
                },
              );
            }
             return const SizedBox.shrink();}
            
            ),
      ),
    );
  }
}
