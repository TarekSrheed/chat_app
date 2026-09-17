import 'package:chat_app/core/shared/app_string.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_cubit.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_state.dart';
import 'package:chat_app/features/view/widgets/build_group_search_tile.dart';
import 'package:chat_app/features/view/widgets/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/widgets.dart';

class GroupCategoryBody extends StatelessWidget {
  const GroupCategoryBody({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => GroupSearchCubit()..fetchGroupsbyCategory(title),
        child: GroupList(
          title: title,
          drawerEnabled: false,
        ));
  }
}

class GroupList extends StatelessWidget {
  final String title;
  final bool drawerEnabled;
  const GroupList(
      {super.key, required this.title, required this.drawerEnabled});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupSearchCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: drawerEnabled
          ? myDrawer(
              context,
              userName: cubit.userName,
              email: cubit.email,
              currentRoute: AppString.suggestedGroups,
            )
          : null,
      body: BlocConsumer<GroupSearchCubit, GroupSearchState>(
        listener: (context, state) {
          if (state is GroupSearchError) {
            showSnackbar(context, Colors.red, state.message);
          }
        },
        builder: (context, state) {
          if (state is GroupSearchLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }

          if (state is GroupSearchSuccess) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  for (var snapshot in state.snapshots)
                    _buildGroupList(context, snapshot, state.joinedStatusMap),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGroupList(
    BuildContext context,
    QuerySnapshot? searchSnap,
    Map<String, bool> joinedStatusMap,
  ) {
    if (searchSnap == null || searchSnap.docs.isEmpty) {
      return !drawerEnabled
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_outlined,
                        size: 72, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 12),
                    const Text('No groups found for this category.',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink();
    }

    final cubit = context.read<GroupSearchCubit>();

    return ListView.builder(
      primary: false,
      shrinkWrap: true,
      itemCount: searchSnap.docs.length,
      itemBuilder: (context, index) {
        final doc = searchSnap.docs[index];
        final String groupId = doc['groupId'];
        final String groupName = doc['groupName'];
        return buildGroupSearchTile(
          groupId: groupId,
          groupName: groupName,
          userName: cubit.userName,
          context: context,
          subtitle: "admin: ${doc['adminName']}",
          isJoined: joinedStatusMap[groupId] ?? false,
          istrailing: true,
          onPressed: () async {
            try {
              bool isJoined = await cubit.toggleGroupJoin(groupId, groupName);
              showSnackbar(
                context,
                isJoined ? Colors.green : Colors.red,
                isJoined
                    ? AppString.groupJoinSuccess
                    : AppString.groupLeaveSuccess,
              );
            } catch (_) {
              showSnackbar(context, Colors.red, AppString.errorOccurred);
            }
          },
        );
      },
    );
  }
}
