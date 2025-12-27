import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  // Function to delete user data
  Future<void> _deleteUser(
      BuildContext context, String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Data?'),
        content: Text(
            'Are you sure you want to permanently delete data for "$name"?\n\nThis will remove their profile and access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
            SnackBar(content: Text('$name deleted successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  Widget _buildUserList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading users:\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found in database.'));
        }

        // Filter locally to include "old data" (missing role) as Tourists
        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userRole = data['role'];

          if (role == 'tourist') {
            // Show if role is 'tourist' OR role is missing/null (Legacy/Old Data)
            return userRole == 'tourist' || userRole == null;
          } else {
            // Show only if role is explicitly 'authority'
            return userRole == 'authority';
          }
        }).toList();

        if (users.isEmpty) {
          return Center(child: Text('No $role found.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['fullName'] ?? 'Unknown Name';
            final email = data['email'] ?? 'No Email';
            final detail = role == 'authority'
                ? 'Dept: ${data['department'] ?? 'N/A'}'
                : 'Phone: ${data['phoneNumber'] ?? 'N/A'}';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      role == 'authority' ? Colors.deepPurple : Colors.blue,
                  child: Icon(
                    role == 'authority' ? Icons.security : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    Text(detail, style: TextStyle(color: Colors.grey[600])),
                    if (data['role'] == null) // Indicate legacy data
                      Text('(Legacy User)',
                          style: TextStyle(
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
                              fontSize: 12)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
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
        appBar: AppBar(
        appBar: AppBar(
            title: const Text('Super Admin Dashboard'),
            backgroundColor: Colors.redAccent,
            bottom: TabBar(
              tabs: [
                Tab(text: 'Tourists'),
                Tab(text: 'Authorities'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => Navigator.pop(context),
              )
            ]),
        body: TabBarView(
          children: [
            _buildUserList('tourist'),
            _buildUserList('authority'),
          ],
        ),
      ),
    );
  }
}
