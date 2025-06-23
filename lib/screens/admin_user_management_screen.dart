import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../widgets/loading_dialog.dart'; // <-- Import your loading dialog
import 'dart:developer'; // For log()

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserItem> filteredUsers = [];
  
  // Sample user data
  List<UserItem> allUsers = [];

  Future<void> _logCurrentUserClaims() async {
    final user = FirebaseAuth.instance.currentUser;
    final idTokenResult = await user?.getIdTokenResult();
    log('User claims: ${idTokenResult?.claims}');
  }

  @override
  void initState() {
    super.initState();
    // Schedule _fetchUsers after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers();
      _searchController.addListener(_filterUsers);
      _logCurrentUserClaims(); // Log claims on screen load
    });
  }

  Future<void> _fetchUsers() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingDialog(message: "Loading users..."),
    );
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      allUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserItem(
          id: doc.id,
          name: data['name'] ?? 'username',
          email: data['email'] ?? 'email@email.com',
          isAdmin: data['isAdmin'] ?? false,
          backgroundColor: Colors.blue,
        );
      }).toList();
      setState(() {
        filteredUsers = List.from(allUsers);
      });
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(allUsers);
      } else {
        filteredUsers = allUsers.where((user) =>
          user.name.toLowerCase().contains(query) ||
          user.id.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _showUserDetails(UserItem user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            Text('User ID: ${user.id}'),
            Text('Admin: ${user.isAdmin ? "Yes" : "No"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: user.isAdmin
                ? null
                : () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const LoadingDialog(message: "Setting user to admin..."),
                    );
                    // Set isAdmin in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.id)
                        .update({'isAdmin': true});
                    try {
                      log('User ${user.name} set to admin in Firestore');
                      log('User ID: ${user.id}');
                      await FirebaseAuth.instance.currentUser?.getIdToken(true);
                      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('setAdmin');
                      await callable.call({'uid': user.id});
                      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
                      Navigator.pop(context);
                      _fetchUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${user.name} is now an admin'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      log('Error calling setAdmin function: $e');
                      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to set admin status'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isAdmin ? Colors.grey : const Color(0xFFFF6B47),
            ),
            child: Text(user.isAdmin ? 'Already Admin' : 'Set Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: const Text(
          'Manage User',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.amber,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Find username',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: filteredUsers.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                ),
          ),          
        ],
      ),
    );
  }

  Widget _buildUserCard(UserItem user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: user.backgroundColor,
                backgroundImage: AssetImage('assets/images/profile.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      user.id,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showUserDetails(user),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserItem {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;
  final Color backgroundColor;

  UserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.backgroundColor,
  });

  UserItem copyWith({
    String? id,
    String? name,
    String? email,
    bool? isAdmin,
    Color? backgroundColor,
  }) {
    return UserItem(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final UserItem user;
  final Function(UserItem) onSave;

  const EditUserDialog({Key? key, required this.user, required this.onSave}) : super(key: key);

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedUser = widget.user.copyWith(
              name: _nameController.text,
            );
            widget.onSave(updatedUser);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B47)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AddUserDialog extends StatefulWidget {
  final Function(UserItem) onAdd;

  const AddUserDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add New User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              final newUser = UserItem(
                id: '#${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}',
                name: _nameController.text,
                email: '',
                isAdmin: false,
                backgroundColor: Colors.blue,
              );
              widget.onAdd(newUser);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B47)),
          child: const Text('Add'),
        ),
      ],
    );
  }
}