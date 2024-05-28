import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String groupName;

  ChatScreen(this.groupName);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} Chat'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups')
                  .doc(widget.groupName)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;
                String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
                List<MessageBubble> messageBubbles = [];
                for (var message in messages) {
                  var messageText = message['text'];
                  var messageSender = message['sender'];
                  var isMe = messageSender == currentUserUid;
                  var messageBubble = MessageBubble(sender: messageSender, text: messageText, isMe: isMe, groupName: widget.groupName);
                  messageBubbles.add(messageBubble);
                }

                return ListView(
                  reverse: true,
                  children: messageBubbles,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    String messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUserUid)
          .get();
      String username = userDoc['username'];

      _firestore.collection('groups').doc(widget.groupName).collection('messages').add({
        'text': messageText,
        'sender': username,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final String groupName;

  MessageBubble({required this.sender, required this.text, required this.isMe, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          if (!isMe)
            Text(
              sender,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.black54,
              ),
            ),
          Material(
            borderRadius: BorderRadius.circular(10.0),
            elevation: 5.0,
            color: isMe ? Colors.blue : Color.fromARGB(255, 139, 15, 255),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15.0,
                        color: isMe ? Colors.white : Colors.white,
                      ),
                    ),
                  ),
                ),
                if (isMe)
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteMessage(text); // Call delete message function
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String message) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupName)
        .collection('messages')
        .where('text', isEqualTo: message)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String messageId = querySnapshot.docs.first.id;
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupName)
          .collection('messages')
          .doc(messageId)
          .delete();
    }
  }
}
