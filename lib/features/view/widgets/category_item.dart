import 'package:chat_app/features/view/screens/group_category_body.dart';
import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  const CategoryItem({
    super.key,
    required this.title,
    required this.imageUrl,
  });
  final String title;
  final String imageUrl;

  void selectGategory(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (context) => GroupCategoryBody(
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => selectGategory(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.network(
              imageUrl,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black.withOpacity(0.4),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ],
      ),
    );
  }
}
