import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatefulWidget {
  final String userId;
  final String senderName;
  final String? profileUrl;
  final double radius;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.senderName,
    this.profileUrl,
    this.radius = 16,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _fetchedUrl;

  @override
  void initState() {
    super.initState();
    if (widget.profileUrl == null || widget.profileUrl!.isEmpty) {
      _fetchProfileUrl();
    }
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.profileUrl != widget.profileUrl) {
      _fetchedUrl = null;
      if (widget.profileUrl == null || widget.profileUrl!.isEmpty) {
        _fetchProfileUrl();
      }
    }
  }

  Future<void> _fetchProfileUrl() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _fetchedUrl = doc.data()?['profileImage'];
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final url =
        widget.profileUrl?.isNotEmpty == true ? widget.profileUrl : _fetchedUrl;

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: NetworkImage(url),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        widget.senderName.isNotEmpty ? widget.senderName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: widget.radius * 0.75,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}
