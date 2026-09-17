import 'package:chat_app/core/shared/app_string.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_cubit.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/build_group_search_tile.dart';
import '../widgets/widgets.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupSearchCubit(),
      child: const _SearchScreenBody(),
    );
  }
}

class _SearchScreenBody extends StatefulWidget {
  const _SearchScreenBody();

  @override
  State<_SearchScreenBody> createState() => _SearchScreenBodyState();
}

class _SearchScreenBodyState extends State<_SearchScreenBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupSearchCubit>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Search")),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: AppString.searchGroups,
                        hintStyle: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onSubmitted: (query) => cubit.searchGroupByName(query),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => cubit.searchGroupByName(_searchController.text),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues( alpha:  0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<GroupSearchCubit, GroupSearchState>(
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
                    final snapshot = state.snapshots.first;
                    if (snapshot == null || snapshot.docs.isEmpty) {
                      return const Center(child: Text(AppString.noGroupsFound));
                    }
                    return _buildGroupList(context, snapshot, state.joinedStatusMap);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList(
    BuildContext context,
    QuerySnapshot searchSnap,
    Map<String, bool> joinedStatusMap,
  ) {
    final cubit = context.read<GroupSearchCubit>();

    return ListView.builder(
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
          istrailing: true,
          subtitle: "admin: ${doc['adminName']}",
          isJoined: joinedStatusMap[groupId] ?? false,
          onPressed: () async {
            try {
              bool isJoined = await cubit.toggleGroupJoin(groupId, groupName);
              showSnackbar(
                context,
                isJoined ? Colors.green : Colors.red,
                isJoined ? AppString.groupJoinSuccess : AppString.groupLeaveSuccess,
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