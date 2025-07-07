import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminFeedbackManagementScreen extends StatefulWidget {
  const AdminFeedbackManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackManagementScreen> createState() => _AdminFeedbackManagementScreenState();
}

class _AdminFeedbackManagementScreenState extends State<AdminFeedbackManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<FeedbackItem> _allFeedbacks = [];
  bool _isLoading = true;

  List<FeedbackItem> get _newFeedbacks => _allFeedbacks.where((f) => !f.resolved).toList();
  List<FeedbackItem> get _resolvedFeedbacks => _allFeedbacks.where((f) => f.resolved).toList();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('timestamp', descending: true)
        .get();

    _allFeedbacks = snapshot.docs.map((doc) {
      final data = doc.data();
      return FeedbackItem(
        id: doc.id,
        userName: data['user_name'] ?? 'Unknown User',
        userId: data['user_id'] ?? '',
        userImage: 'assets/images/profile.png',
        message: data['feedback'] ?? '',
        date: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
        rating: (data['rating'] is int)
            ? data['rating']
            : (data['rating'] is double)
                ? (data['rating'] as double).round()
                : 0,
        resolved: data['resolved'] ?? false,
      );
    }).toList();

    setState(() => _isLoading = false);
  }

  Widget _buildToggleTabs() {
    return Center( // Center the toggle container
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: Colors.grey[200], // Background of the toggle area
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Row takes minimum space needed by children
          children: [
            _buildToggleItem(
              text: 'New',
              isSelected: _tabController.index == 0,
              onTap: () {
                if (_tabController.index != 0) {
                  setState(() {
                    _tabController.animateTo(0);
                  });
                }
              },
            ),
            _buildToggleItem(
              text: 'Resolved',
              isSelected: _tabController.index == 1,
              onTap: () {
                if (_tabController.index != 1) {
                  setState(() {
                    _tabController.animateTo(1);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded( // Make each item take equal width within the Row
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12), // Adjust padding as needed
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6B47) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SofiaSans', // Assuming you use this font
              color: isSelected ? Colors.white : const Color(0xFFFF6B47),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[50],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Feedback Management',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'SofiaSans',
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300], // Placeholder color
              backgroundImage: const AssetImage('assets/images/profile.png'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildToggleTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFeedbackList(_newFeedbacks),
                      _buildFeedbackList(_resolvedFeedbacks, isResolvedList: true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeedbackList(List<FeedbackItem> feedbacks, {bool isResolvedList = false}) {
    if (feedbacks.isEmpty) {
      return Center(
        child: Text(
          isResolvedList ? 'No resolved feedbacks yet.' : 'No new feedbacks.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = feedbacks[index];
        return _buildFeedbackCard(feedback, isResolvedList: isResolvedList);
      },
    );
  }

  Widget _buildFeedbackCard(FeedbackItem feedback, {bool isResolvedList = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile picture and user info (user id and date) stacked vertically
                Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(feedback.userImage),
                      radius: 20,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Name vertically centered with profile picture
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      feedback.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // Star rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < feedback.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              feedback.userId,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontFamily: 'SofiaSans',
              ),
            ),
            Text(
              '${feedback.date.day}/${feedback.date.month}/${feedback.date.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              feedback.message,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            // RESOLVE/UNRESOLVE BUTTON AND RESOLVED TEXT IN THE SAME ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Resolved text aligned left
                if (feedback.resolved && isResolvedList)
                  Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: Text(
                      'Resolved',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.green[700],
                      ),
                    ),
                  )
                else
                const SizedBox(), // Keeps spacing consistent if not resolved
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('feedback')
                        .doc(feedback.id)
                        .update({'resolved': !feedback.resolved});
                    _fetchFeedbacks();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: feedback.resolved
                        ? Colors.grey
                        : const Color(0xFFFF6B47),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(feedback.resolved ? 'Unresolve' : 'Resolve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbackItem {
  final String id;
  final String userName;
  final String userId;
  final String userImage;
  final String message;
  final DateTime date;
  final int rating;
  final bool resolved;

  FeedbackItem({
    required this.id,
    required this.userName,
    required this.userId,
    required this.userImage,
    required this.message,
    required this.date,
    required this.rating,
    required this.resolved,
  });
}

// Reply Dialog (ensure this is defined, potentially in the same file or imported)
class ReplyDialog extends StatefulWidget {
  final FeedbackItem feedback;
  const ReplyDialog({super.key, required this.feedback});

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Reply to ${widget.feedback.userName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original feedback:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.feedback.message,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _replyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your reply here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_replyController.text.isNotEmpty) {
              // Implement your reply logic here
              // For example, update the feedback item and move it to resolved
              print('Reply: ${_replyController.text}');
              Navigator.pop(context); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reply sent to ${widget.feedback.userName}'),
                  backgroundColor: Colors.green,
                ),
              );
              // You would typically call setState on the parent screen or use a state management solution
              // to refresh the lists after a reply.
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B47),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
            )
          ),
          child: const Text('Send Reply'),
        ),
      ],
    );
  }
}