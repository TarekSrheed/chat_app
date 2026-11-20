import 'package:chat_app/features/data/local/hobbies.dart';
import 'package:chat_app/features/view/cubit/home/home_cubit.dart';
import 'package:chat_app/features/view/cubit/home/home_state.dart';
import 'package:chat_app/features/view/screens/chat_screen.dart';
import 'package:chat_app/features/view/screens/search_screen.dart';
import 'package:chat_app/features/view/widgets/build_group_search_tile.dart';
import 'package:chat_app/features/view/widgets/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..initHomeScreen(),
      child: const _HomeScreenBody(),
    );
  }
}

class _HomeScreenBody extends StatelessWidget {
  const _HomeScreenBody();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();

    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {
        if (state is HomeError) {
          showSnackbar(context, Colors.red, state.message);
        } else if (state is HomeGroupCreatedSuccess) {
          showSnackbar(context, Colors.green, 'Group created successfully.');
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Groups"),
            actions: [
              IconButton(
                color: Colors.white,
                onPressed: () => nextScreen(context, const SearchScreen()),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          drawer: myDrawer(
            context,
            userName: cubit.userName,
            email: cubit.email,
            currentRoute: "Groups",
          ),
          body: state is HomeLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildGroupStream(context, cubit.groupsStream, cubit.userName),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.9),
            onPressed: () => _showCreateGroupDialog(context, cubit),
            icon: const Icon(Icons.add, color: Colors.white),
            label:
                const Text('New Group', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildGroupStream(
    BuildContext context,
    Stream<QuerySnapshot>? groupsStream,
    String userName,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: groupsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
              context, 'We could not load your groups right now.');
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final groupDocs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: groupDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final groupData = groupDocs[index].data() as Map<String, dynamic>;
              final String groupId = groupDocs[index].id;
              final String groupName = groupData["groupName"];
              final String recentMessage = groupData['recentMessage'] ?? '';
              final String recentSender =
                  groupData['recentMessageSender'] ?? '';
              return buildGroupSearchTile(
                groupId: groupId,
                groupName: groupName,
                subtitle: recentSender.isNotEmpty
                    ? "$recentSender: $recentMessage"
                    : 'No messages yet',
                context: context,
                isJoined: true,
                userName: userName,
                istrailing: false,
                onPressed: () {
                  nextScreen(
                    context,
                    ChatScreen(
                      groupId: groupId,
                      groupName: groupName,
                      userName: userName,
                    ),
                  );
                },
              );
            },
          );
        }
        return _buildEmptyState(
          context,
          "You haven't joined any groups yet. Create one or search for new ones.",
        );
      },
    );
  }

  Future<void> _showCreateGroupDialog(
      BuildContext context, HomeCubit cubit) async {
    String groupName = '';
    String selectedHobby = hobbies.isNotEmpty ? hobbies.first : 'Fashion';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Create a group',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (val) => setDialogState(() => groupName = val),
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        floatingLabelStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedHobby,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: hobbies
                          .map((hobby) => DropdownMenuItem(
                                value: hobby,
                                child: Text(hobby),
                              ))
                          .toList(),
                      onChanged: (val) => setDialogState(
                        () => selectedHobby = val ?? selectedHobby,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await cubit.createGroup(
                      groupName: groupName,
                      category: selectedHobby,
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final cubit = context.read<HomeCubit>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 72,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showCreateGroupDialog(context, cubit),
              icon: const Icon(Icons.add),
              label: const Text('Create a group'),
            ),
          ],
        ),
      ),
    );
  }
}
