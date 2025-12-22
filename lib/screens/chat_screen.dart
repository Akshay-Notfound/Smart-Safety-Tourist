import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/reaction_user_tile.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ChatScreen({super.key, required this.userData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  Timer? _typingTimer;
  bool _isTyping = false;
  Message? _editingMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Ensure we stop typing status when leaving
    if (_isTyping) {
      _chatService.updateTypingStatus(false);
    }
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final String text = _messageController.text.trim();

    if (_editingMessage != null) {
      // Handle Edit
      _chatService.editMessage(_editingMessage!.id, text);
      setState(() {
        _editingMessage = null;
      });
    } else {
      // Handle New Message
      bool isAuthority = widget.userData['role'] == 'authority';
      String senderName = widget.userData['fullName'] ?? 'Unknown';
      String? senderProfileUrl = widget.userData['profileImage'];
      _chatService.sendMessage(text, isAuthority, senderName, senderProfileUrl);
    }

    _messageController.clear();
    _handleTypingChanged(''); // Stop typing immediately
  }

  void _handleTypingChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.updateTypingStatus(true);
    }

    // Debounce the stop typing
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isTyping) {
        _isTyping = false;
        _chatService.updateTypingStatus(false);
      }
    });
  }

  bool _canEdit(Message message) {
    // Only self can edit, within 10 minutes
    if (message.senderId != _auth.currentUser?.uid) return false;
    final difference = DateTime.now().difference(message.timestamp);
    return difference.inMinutes < 10;
  }

  bool _canDelete(Message message) {
    // Authority can delete anyone's message
    if (widget.userData['role'] == 'authority') return true;
    // Users can delete their own
    return message.senderId == _auth.currentUser?.uid;
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reaction Picker
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReactionButton(message, '👍'),
                    _buildReactionButton(message, '❤️'),
                    _buildReactionButton(message, '😂'),
                    _buildReactionButton(message, '😮'),
                    _buildReactionButton(message, '😢'),
                    _buildReactionButton(message, '🙏'),
                  ],
                ),
              ),
              const Divider(),
              if (_canEdit(message))
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit (within 10m)'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _editingMessage = message;
                      _messageController.text = message.text;
                    });
                  },
                ),
              if (_canDelete(message))
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _chatService.deleteMessage(message.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReactionButton(Message message, String emoji) {
    final isSelected = message.reactions[_auth.currentUser?.uid] == emoji;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _chatService.toggleReaction(message.id, emoji);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chat'),
        backgroundColor: Colors.deepPurple.shade400,
        actions: [
          if (_editingMessage != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _editingMessage = null;
                  _messageController.clear();
                });
              },
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse:
                      true, // Show newest at bottom (requires ordering descending in query)
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _auth.currentUser?.uid;

                    bool showUserInfo = true;
                    if (index + 1 < messages.length) {
                      if (messages[index + 1].senderId == message.senderId) {
                        showUserInfo = false;
                      }
                    }

                    return _buildMessageBubble(message, isMe, showUserInfo);
                  },
                );
              },
            ),
          ),
          _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<List<String>>(
      stream: _chatService.getTypingUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final typingUsers = snapshot.data!;
        String text;
        if (typingUsers.length == 1) {
          text = '${typingUsers.first} is typing...';
        } else if (typingUsers.length == 2) {
          text = '${typingUsers[0]} and ${typingUsers[1]} are typing...';
        } else {
          text = 'Multiple people are typing...';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                fontSize: 12),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: _handleTypingChanged,
              decoration: InputDecoration(
                hintText: _editingMessage != null
                    ? 'Edit message...'
                    : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor:
                _editingMessage != null ? Colors.orange : Colors.deepPurple,
            child: IconButton(
              icon: Icon(_editingMessage != null ? Icons.check : Icons.send,
                  color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showUserInfo) {
    final bool isAuthorityMessage = message.isAuthority;

    // Determine alignemnt
    // CrossAxisAlignment align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start; // Removed as we use Row
    Color bubbleColor = isMe
        ? (isAuthorityMessage
            ? Colors.amber.shade300
            : Colors.deepPurple.shade100)
        : (isAuthorityMessage ? Colors.amber.shade100 : Colors.white);

    // Authority messages are highlighted
    if (isAuthorityMessage && !isMe) {
      bubbleColor = Colors.amber.shade200;
    }

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              if (showUserInfo)
                UserAvatar(
                  userId: message.senderId,
                  senderName: message.senderName,
                  profileUrl: message.senderProfileUrl,
                )
              else
                const SizedBox(width: 32),
              const SizedBox(width: 8),
            ],
            Container(
              decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isMe
                        ? const Radius.circular(12)
                        : const Radius.circular(0),
                    bottomRight: isMe
                        ? const Radius.circular(0)
                        : const Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                    )
                  ]),
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.70),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((!isMe || isAuthorityMessage) && showUserInfo)
                    Text(
                      message.senderName +
                          (message.isAuthority ? ' (Authority)' : ''),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isAuthorityMessage
                            ? Colors.deepOrange
                            : Colors.deepPurple,
                      ),
                    ),
                  if ((!isMe || isAuthorityMessage) && showUserInfo)
                    const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isAuthorityMessage
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (message.isEdited)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text('(edited)',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600)),
                        ),
                      Text(
                        DateFormat('hh:mm a').format(message.timestamp),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  // Reactions Display
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: GestureDetector(
                        onTap: () => _showReactionDetails(message),
                        child: Wrap(
                          spacing: 4,
                          children: _buildReactionCountChips(message.reactions),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              if (showUserInfo)
                UserAvatar(
                  userId: message.senderId,
                  senderName: message.senderName,
                  profileUrl: message.senderProfileUrl,
                )
              else
                const SizedBox(width: 32),
            ],
          ],
        ),
      ),
    );
  }

  void _showReactionDetails(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: message.reactions.length,
                  itemBuilder: (context, index) {
                    final userId = message.reactions.keys.elementAt(index);
                    final emoji = message.reactions.values.elementAt(index);
                    return ReactionUserTile(userId: userId, emoji: emoji);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildReactionCountChips(Map<String, String> reactions) {
    final Map<String, int> counts = {};
    reactions.values.forEach((emoji) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    });

    return counts.entries.map((entry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
        ),
        child: Text('${entry.key} ${entry.value}',
            style: const TextStyle(fontSize: 10)),
      );
    }).toList();
  }
}
