import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  void _addUserToChat(String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser!;

    // Check if a chat already exists with the same set of participants
    final existingChatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    bool chatExists = existingChatQuery.docs.any((doc) {
      final participants = List<String>.from(doc['participants']);
      return participants.contains(otherUserId) && participants.length == 2;
    });

    if (chatExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat already exists with this user.')),
      );
      return;
    }

    // Create a new chat document with both user IDs if no existing chat is found
    final chatRef = FirebaseFirestore.instance.collection('chats').doc();
    await chatRef.set({
      'participants': [currentUser.uid, otherUserId],
      'createdAt': Timestamp.now(),
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration:
                  const InputDecoration(labelText: 'Search by username'),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: _searchQuery)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (ctx, index) {
                    return ListTile(
                      title: Text(users[index]['username']),
                      onTap: () => _addUserToChat(users[index].id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
