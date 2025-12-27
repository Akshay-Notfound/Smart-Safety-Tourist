import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_tourist_app/services/logout_service.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  final Color _executiveBg = const Color(0xFF020617); // Deep Navy
  final Color _executiveCard = const Color(0xFF0F172A); // Slate 900
  final Color _goldAccent = const Color(0xFFF59E0B); // Gold
  final Color _textPlatinum = const Color(0xFFE2E8F0); // Platinum

  // Function to delete user data with Executive Protocol
  Future<void> _deleteUser(
      BuildContext context, String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _executiveCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Colors.red.withOpacity(0.5))),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'PURGE RECORD?',
                style: TextStyle(
                    color: _textPlatinum,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2),
              ),
            ),
          ],
        ),
        content: Text(
          'Target: "$name"\nAction: PERMANENT DELETION\n\nThis action is irreversible. All associated data will be expunged from the mainframe.',
          style: TextStyle(color: _textPlatinum.withOpacity(0.7), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ABORT',
                style: TextStyle(
                    color: _textPlatinum.withOpacity(0.5), letterSpacing: 1)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4))),
            child: const Text('EXECUTE PURGE',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('RECORD EXPUNGED: $name',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
              backgroundColor: _executiveCard,
              shape: Border(top: BorderSide(color: _goldAccent, width: 2)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SYSTEM ERROR: $e')),
          );
        }
      }
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _executiveCard,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: _goldAccent, size: 20),
                Text(value,
                    style: TextStyle(
                        color: _textPlatinum,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title.toUpperCase(),
                style: TextStyle(
                    color: _textPlatinum.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _goldAccent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'DATA CORRUPTION DETECTED',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hex Dump: ${snapshot.error}',
                    style: TextStyle(
                        color: _textPlatinum.withOpacity(0.5),
                        fontFamily: 'Courier',
                        fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Text('DATABASE EMPTY',
                  style: TextStyle(color: _textPlatinum.withOpacity(0.3))));
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userRole = data['role'];
          if (role == 'tourist') {
            return userRole == 'tourist' || userRole == null;
          } else {
            return userRole == 'authority';
          }
        }).toList();

        if (users.isEmpty) {
          return Center(
              child: Text('NO RECORDS FOUND',
                  style: TextStyle(color: _textPlatinum.withOpacity(0.3))));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['fullName'] ?? 'UNKNOWN ENTITY';
            final email = data['email'] ?? 'NO CONTACT';
            final detail = role == 'authority'
                ? 'DEPT: ${data['department']?.toString().toUpperCase() ?? 'N/A'}'
                : 'PHONE: ${data['phoneNumber'] ?? 'N/A'}';

            return Container(
              decoration: BoxDecoration(
                color: _executiveCard,
                borderRadius: BorderRadius.circular(4),
                border: Border(
                    left: BorderSide(
                        color:
                            role == 'authority' ? _goldAccent : Colors.blueGrey,
                        width: 4)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(name.toUpperCase(),
                    style: TextStyle(
                        color: _textPlatinum,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(email,
                        style:
                            TextStyle(color: _textPlatinum.withOpacity(0.6))),
                    Text(detail,
                        style: TextStyle(
                            color: _goldAccent.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_forever_rounded,
                      color: Colors.red.withOpacity(0.7)),
                  onPressed: () => _deleteUser(context, doc.id, name),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _executiveBg,
        appBar: AppBar(
          backgroundColor: _executiveBg,
          elevation: 0,
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: _goldAccent),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXECUTIVE CONTROL',
                      style: TextStyle(
                          color: _textPlatinum,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5)),
                  Text('SUPER ADMIN ACCESS LEVEL 1',
                      style: TextStyle(
                          color: _goldAccent, fontSize: 8, letterSpacing: 2)),
                ],
              ),
            ],
          ),
          bottom: TabBar(
            indicatorColor: _goldAccent,
            labelColor: _goldAccent,
            unselectedLabelColor: _textPlatinum.withOpacity(0.5),
            dividerColor: Colors.white10,
            tabs: const [
              Tab(
                  child: Text('CIVILIAN DATABASE',
                      style: TextStyle(letterSpacing: 1.2))),
              Tab(
                  child: Text('AUTHORITY PERSONNEL',
                      style: TextStyle(letterSpacing: 1.2))),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.power_settings_new, color: Colors.red.shade400),
              onPressed: () => LogoutService.showLogoutDialog(context),
            )
          ],
        ),
        body: Column(
          children: [
            // Live Stats Panel (Mockup from Stream)
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                int tourists = 0;
                int authorities = 0;

                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  tourists = docs.where((d) {
                    final r = (d.data() as Map)['role'];
                    return r == 'tourist' || r == null;
                  }).length;
                  authorities = docs
                      .where((d) => (d.data() as Map)['role'] == 'authority')
                      .length;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  color: _executiveBg,
                  child: Row(
                    children: [
                      _buildStatCard(
                          'CIVILIANS', '$tourists', Icons.people_outline),
                      const SizedBox(width: 12),
                      _buildStatCard(
                          'OFFICERS', '$authorities', Icons.security),
                    ],
                  ),
                );
              },
            ),
            Divider(color: Colors.white10, height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUserList('tourist'),
                  _buildUserList('authority'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
