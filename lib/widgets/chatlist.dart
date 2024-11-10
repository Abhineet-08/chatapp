import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'chat_messages.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.exists ? userDoc['username'] : 'Unknown User';
    } catch (e) {
      print("Error fetching username: $e");
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants',
              arrayContains: FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return ListView.builder(
            itemCount: 10,
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListTile(
                title: Container(height: 10, width: 100, color: Colors.white),
              ),
            ),
          );
        }

        final chatDocs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: chatDocs.length,
          itemBuilder: (ctx, index) {
            final chatData = chatDocs[index].data();
            final otherUserId = (chatData['participants'] as List).firstWhere(
              (userId) => userId != FirebaseAuth.instance.currentUser!.uid,
            );

            return FutureBuilder<String>(
              future: _getUserName(otherUserId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: const ListTile(
                      title: Text('Loading...'),
                    ),
                  );
                }

                return ListTile(
                  title: Text(userSnapshot.data ?? 'Unknown User'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            ChatMessagesScreen(chatId: chatDocs[index].id),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
