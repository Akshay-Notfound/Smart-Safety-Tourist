import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // For ClipRRect and ImageFilter

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
    if (_isTyping) {
      _chatService.updateTypingStatus(false);
    }
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final String text = _messageController.text.trim();

    if (_editingMessage != null) {
      _chatService.editMessage(_editingMessage!.id, text);
      setState(() {
        _editingMessage = null;
      });
    } else {
      bool isAuthority = widget.userData['role'] == 'authority';
      String senderName = widget.userData['fullName'] ?? 'Unknown';
      String? senderProfileUrl = widget.userData['profileImage'];
      _chatService.sendMessage(text, isAuthority, senderName, senderProfileUrl);
    }

    _messageController.clear();
    _handleTypingChanged('');
  }

  void _handleTypingChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.updateTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isTyping) {
        _isTyping = false;
        _chatService.updateTypingStatus(false);
      }
    });
  }

  bool _canEdit(Message message) {
    if (message.senderId != _auth.currentUser?.uid) return false;
    final difference = DateTime.now().difference(message.timestamp);
    return difference.inMinutes < 10;
  }

  bool _canDelete(Message message) {
    if (widget.userData['role'] == 'authority') return true;
    return message.senderId == _auth.currentUser?.uid;
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                    leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                    title: const Text('Edit Message'),
                    subtitle: const Text('Available for 10 mins after sending',
                        style: TextStyle(fontSize: 12)),
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
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    title: const Text('Delete Message',
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _chatService.deleteMessage(message.id);
                    },
                  ),
                const SizedBox(height: 12),
              ],
            ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.transparent,
          shape: BoxShape.circle,
          border:
              isSelected ? Border.all(color: Colors.deepPurple.shade100) : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Chat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            StreamBuilder<List<String>>(
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
                  text = '${typingUsers[0]} and ${typingUsers[1]}...';
                } else {
                  text = 'Multiple people typing...';
                }
                return Text(
                  text,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
        elevation: 0,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              const Color(0xFF1A1A2E), // Dark Navy
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _chatService.getMessages(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }

                  final messages = snapshot.data!;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.only(
                        top: 100, bottom: 20, left: 16, right: 16),
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
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _handleTypingChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _editingMessage != null
                          ? 'Edit message...'
                          : 'Type a message...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _editingMessage != null
                          ? [Colors.orange.shade400, Colors.orange.shade700]
                          : [
                              Colors.deepPurple.shade400,
                              Colors.deepPurple.shade700
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_editingMessage != null
                                ? Colors.orange
                                : Colors.deepPurple)
                            .withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                        _editingMessage != null
                            ? Icons.check
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showUserInfo) {
    final bool isAuthorityMessage = message.isAuthority;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
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
          Flexible(
            // Use Flexible to allow wrapping
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Container(
                margin: EdgeInsets.only(
                  left: isMe ? 50 : 0,
                  right: isMe ? 0 : 50,
                  top: showUserInfo ? 12 : 2,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? LinearGradient(
                          colors: isAuthorityMessage
                              ? [Colors.amber.shade700, Colors.orange.shade900]
                              : [
                                  Colors.deepPurple.shade500,
                                  Colors.blue.shade600
                                ],
                        )
                      : isAuthorityMessage
                          ? LinearGradient(
                              colors: [
                                Colors.amber.shade100,
                                Colors.orange.shade100
                              ],
                            )
                          : null,
                  color: (!isMe && !isAuthorityMessage) ? Colors.white : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe
                        ? const Radius.circular(20)
                        : const Radius.circular(4),
                    bottomRight: isMe
                        ? const Radius.circular(4)
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Wrap content
                  children: [
                    if ((!isMe || isAuthorityMessage) && showUserInfo) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            // Constrain name text
                            child: Text(
                              message.senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isMe
                                    ? Colors.white.withOpacity(0.9)
                                    : (isAuthorityMessage
                                        ? Colors.deepOrange.shade900
                                        : Colors.deepPurple.shade700),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAuthorityMessage)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.deepOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: (isMe
                                              ? Colors.white
                                              : Colors.deepOrange)
                                          .withOpacity(0.5),
                                      width: 0.5)),
                              child: Text(
                                'AUTHORITY',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isMe ? Colors.white : Colors.deepOrange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (message.isEdited)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.edit,
                                size: 10,
                                color: isMe ? Colors.white54 : Colors.black38),
                          ),
                        Text(
                          DateFormat('hh:mm a').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white54 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    if (message.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: GestureDetector(
                          onTap: () => _showReactionDetails(message),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _buildReactionCountChips(
                                message.reactions, isMe),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
    );
  }

  void _showReactionDetails(Message message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  List<Widget> _buildReactionCountChips(
      Map<String, String> reactions, bool isMe) {
    final Map<String, int> counts = {};
    reactions.values.forEach((emoji) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    });

    return counts.entries.map((entry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMe ? Colors.black.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isMe
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2)),
        ),
        child: Text('${entry.key} ${entry.value}',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : Colors.black87)),
      );
    }).toList();
  }
}
