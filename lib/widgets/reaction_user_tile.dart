import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReactionUserTile extends StatefulWidget {
  final String userId;
  final String emoji;

  const ReactionUserTile({
    super.key,
    required this.userId,
    required this.emoji,
  });

  @override
  State<ReactionUserTile> createState() => _ReactionUserTileState();
}

class _ReactionUserTileState extends State<ReactionUserTile> {
  String _name = 'Loading...';
  String? _profileUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _name = data?['fullName'] ?? 'Unknown';
          _profileUrl = data?['profileImage'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _name = 'Unknown';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            _profileUrl != null ? NetworkImage(_profileUrl!) : null,
        child: _profileUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(_name),
      trailing: Text(
        widget.emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
