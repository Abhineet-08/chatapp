import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'message_bubble.dart';
import 'new_message.dart';

class ChatMessagesScreen extends StatelessWidget {
  final String chatId;

  const ChatMessagesScreen({required this.chatId, super.key});

  Future<String> _getOtherUserName(String currentUserId) async {
    try {
      // Get the chat document
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      // Retrieve the user IDs from the chat document
      final userIds = List<String>.from(chatDoc['participants'] ?? []);

      // Find the other user's ID (the one that's not the current user)
      final otherUserId =
          userIds.firstWhere((id) => id != currentUserId, orElse: () => '');

      if (otherUserId.isEmpty) {
        throw Exception('Other user not found');
      }

      // Fetch the username from the 'users' collection using the other user's ID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found in users collection');
      }

      // Return the username (assuming the field is named 'username')
      return userDoc['username'] ?? 'Unknown User';
    } catch (e) {
      print("Error fetching username: $e");
      return 'Error fetching username';
    }
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 150.0,
        height: 20.0,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _getOtherUserName(currentUserId),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerPlaceholder();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.hasData) {
              final username = snapshot.data ?? 'Unknown User';
              return Text(username);
            }
            return const Text('No data');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: ListView.builder(
                        itemCount: 6,
                        itemBuilder: (ctx, index) {
                          return ListTile(
                            title: Container(
                              width: double.infinity,
                              height: 20.0,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final message = messages[index]['text'];
                    final isMe = messages[index]['userId'] ==
                        FirebaseAuth.instance.currentUser!.uid;
                    return MessageBubble.next(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          NewMessage(chatId: chatId),
        ],
      ),
    );
  }
}
