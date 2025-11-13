import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _itineraryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItinerary();
  }

  Future<void> _fetchItinerary() async {
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('itinerary')) {
      setState(() {
        _itineraryItems = List<Map<String, dynamic>>.from(userDoc.data()!['itinerary']);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateItineraryInFirestore() async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'itinerary': _itineraryItems,
    }, SetOptions(merge: true));
  }

  void _addItineraryItem() {
    final dayController = TextEditingController();
    final planController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dayController, decoration: const InputDecoration(labelText: 'Day (e.g., Day 1, Oct 4)')),
              TextField(controller: planController, decoration: const InputDecoration(labelText: 'Plan (e.g., Visit a place)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (dayController.text.isNotEmpty && planController.text.isNotEmpty) {
                  setState(() {
                    _itineraryItems.add({'day': dayController.text, 'plan': planController.text});
                  });
                  _updateItineraryInFirestore();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Itinerary'),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _itineraryItems.isEmpty
          ? const Center(
        child: Text('No itinerary added yet. Tap + to add a plan.', style: TextStyle(fontSize: 16, color: Colors.grey)),
      )
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _itineraryItems.length,
        itemBuilder: (context, index) {
          final item = _itineraryItems[index];
          return Card(
            key: ValueKey(item),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Text('${index + 1}'),
              ),
              title: Text(item['day'] ?? 'No Day', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['plan'] ?? 'No Plan'),
              trailing: const Icon(Icons.drag_handle),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _itineraryItems.removeAt(oldIndex);
            _itineraryItems.insert(newIndex, item);
          });
          _updateItineraryInFirestore();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItineraryItem,
        child: const Icon(Icons.add),
        tooltip: 'Add a new plan',
      ),
    );
  }
}
