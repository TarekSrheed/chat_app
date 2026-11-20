import 'package:chat_app/core/shared/app_string.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_cubit.dart';
import 'package:chat_app/features/view/cubit/group_search/group_search_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
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
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(GroupSearchCubit cubit, String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      cubit.searchGroupByName(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GroupSearchCubit>();

    return Scaffold(
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
                    onChanged: (query) => _search(cubit, query),
                    onSubmitted: (query) {
                      _searchDebounce?.cancel();
                      cubit.searchGroupByName(query);
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () => cubit.searchGroupByName(_searchController.text),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
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
                  if (state.searchResults != null) {
                    if (state.searchResults!.isEmpty) {
                      return const Center(
                        child: Text(AppString.noGroupsFound),
                      );
                    }
                    return _buildGroupResultList(
                      context,
                      state.searchResults!,
                      state.joinedStatusMap,
                    );
                  }
                  final snapshot = state.snapshots.first;
                  if (snapshot == null || snapshot.docs.isEmpty) {
                    return const Center(child: Text(AppString.noGroupsFound));
                  }
                  return _buildGroupList(
                      context, snapshot, state.joinedStatusMap);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
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
              if (!context.mounted) return;
              showSnackbar(
                context,
                isJoined ? Colors.green : Colors.red,
                isJoined
                    ? AppString.groupJoinSuccess
                    : AppString.groupLeaveSuccess,
              );
            } catch (_) {
              if (!context.mounted) return;
              showSnackbar(context, Colors.red, AppString.errorOccurred);
            }
          },
        );
      },
    );
  }

  Widget _buildGroupResultList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, bool> joinedStatusMap,
  ) {
    final cubit = context.read<GroupSearchCubit>();

    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        final groupId = data['groupId'] as String? ?? doc.id;
        final groupName = data['groupName'] as String? ?? '';

        return buildGroupSearchTile(
          groupId: groupId,
          groupName: groupName,
          userName: cubit.userName,
          context: context,
          istrailing: true,
          subtitle: "admin: ${data['adminName'] ?? ''}",
          isJoined: joinedStatusMap[groupId] ?? false,
          onPressed: () async {
            try {
              final isJoined = await cubit.toggleGroupJoin(groupId, groupName);
              if (!context.mounted) return;
              showSnackbar(
                context,
                isJoined ? Colors.green : Colors.red,
                isJoined
                    ? AppString.groupJoinSuccess
                    : AppString.groupLeaveSuccess,
              );
            } catch (_) {
              if (!context.mounted) return;
              showSnackbar(context, Colors.red, AppString.errorOccurred);
            }
          },
        );
      },
    );
  }
}
