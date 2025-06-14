import 'package:flutter/material.dart';

class AdminFeedbackManagementScreen extends StatefulWidget {
  const AdminFeedbackManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackManagementScreen> createState() => _AdminFeedbackManagementScreenState();
}

class _AdminFeedbackManagementScreenState extends State<AdminFeedbackManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sample data - replace with your actual data fetching
  final List<FeedbackItem> _allFeedbacks = [
    FeedbackItem(id: '1', userName: 'Jane Doe', userImage: 'assets/images/profile.png', message: 'Great app, very useful!', date: DateTime.now().subtract(const Duration(days: 1)), rating: 5, isNew: true),
    FeedbackItem(id: '2', userName: 'John Smith', userImage: 'assets/images/profile.png', message: 'Found a bug on the payment screen.', date: DateTime.now().subtract(const Duration(hours: 5)), rating: 2, isNew: true),
    FeedbackItem(id: '3', userName: 'Alice Wonderland', userImage: 'assets/images/profile.png', message: 'Love the new features!', date: DateTime.now().subtract(const Duration(days: 2)), rating: 4, isNew: false),
  ];

  List<FeedbackItem> get _newFeedbacks => _allFeedbacks.where((f) => f.isNew).toList();
  List<FeedbackItem> get _resolvedFeedbacks => _allFeedbacks.where((f) => !f.isNew).toList();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add listener to rebuild UI when tab changes, e.g., by swiping TabBarView
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Optional: handle if index is changing (mid-swipe)
      } else {
        // Update state when tab animation completes
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReplyDialog(FeedbackItem feedback) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReplyDialog(feedback: feedback);
      },
    );
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
      body: Column(
        children: [
          // Custom Toggle Tabs
          _buildToggleTabs(), // Use the new custom toggle

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // New Feedbacks
                _buildFeedbackList(_newFeedbacks),
                // Resolved Feedbacks
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
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(feedback.userImage),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        // Format date as needed, e.g., using intl package
                        '${feedback.date.day}/${feedback.date.month}/${feedback.date.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
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
            const SizedBox(height: 12),
            Text(
              feedback.message,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            if (feedback.isNew && !isResolvedList)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _showReplyDialog(feedback),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B47),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Reply'),
                ),
              ),
            if (!feedback.isNew && isResolvedList)
              Text(
                'Replied: Thank you for your feedback! We are looking into it.', // Example reply
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green[700]),
              )
          ],
        ),
      ),
    );
  }
}

class FeedbackItem {
  final String id;
  final String userName;
  final String userImage;
  final String message;
  final DateTime date;
  final int rating;
  bool isNew; // To distinguish between new and resolved

  FeedbackItem({
    required this.id,
    required this.userName,
    required this.userImage,
    required this.message,
    required this.date,
    required this.rating,
    this.isNew = true,
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