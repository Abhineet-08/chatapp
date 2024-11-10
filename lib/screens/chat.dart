import 'package:chatapp/widgets/chatlist.dart';
import 'package:chatapp/widgets/usersearchscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;

  // Method to open a user search screen
  void _openUserSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const UserSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.account_circle_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              _auth.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Button to add new users
          ElevatedButton(
            onPressed: _openUserSearch,
            child: const Text('Add User to Chat'),
          ),
          const Expanded(
            child: ChatList(),
          ),
        ],
      ),
    );
  }
}
