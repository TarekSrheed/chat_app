import 'package:chat_app/core/shared/app_string.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_cubit.dart';
import 'package:chat_app/features/view/screens/group_category_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SuggestedGroups extends StatelessWidget {
  const SuggestedGroups({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupSearchCubit()..fetchSuggestedGroups(),
      child: const GroupList(
        title: AppString.suggestedGroups,
        drawerEnabled: true,
      ),
    );
  }
}
