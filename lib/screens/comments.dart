import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/utils/blog_comment.dart';
import 'package:harvest_guardian/widgets/community_post.dart';
import 'package:intl/intl.dart';

class CommentItem extends StatelessWidget {
  final String profilePicUrl;
  final String userEmail;
  final String commentText;
  final int timestamp;

  const CommentItem({
    super.key,
    required this.profilePicUrl,
    required this.userEmail,
    required this.commentText,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 14),
          CircleAvatar(
            backgroundImage: NetworkImage(profilePicUrl),
            radius: 20,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Constants.primaryColor,
                  ),
                ),
                Text(
                  commentText,
                  style: TextStyle(
                    fontSize: 16,
                    color: Constants.primaryColor,
                  ),
                ),
                Text(
                  'On: ${DateFormat('yyyy/MM/dd - HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp))}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Comments extends StatefulWidget {
  final SinglePost blogPost;
  const Comments({super.key, Key? key2, required this.blogPost});

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  final TextEditingController _commentController = TextEditingController();
  bool _isRefreshing = false;

  Future<void> addComment(String commentText) async {
    if (commentText.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter a comment.');
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      Fluttertoast.showToast(msg: 'Please log in to add a comment.');
      return;
    }

    FocusScope.of(context).unfocus();
    DatabaseReference databaseReference = FirebaseDatabase.instance
        .ref()
        .child('Blogs')
        .child(widget.blogPost.data.postId)
        .child('comments');

    int timestamp = DateTime.now().millisecondsSinceEpoch;

    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

    Map<String, dynamic> commentData = {
      'text': commentText,
      'timestamp': timestamp,
      'userEmail': currentUserEmail,
    };

    try {
      await databaseReference.push().set(commentData);

      var snapshot = await databaseReference.once();

      var data = snapshot.snapshot.value;

      List<BlogComment> updatedComments = _parseComments(data);

      setState(() {
        widget.blogPost.data.comments = updatedComments;
      });

      Fluttertoast.showToast(msg: 'Comment added successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding comment: $e');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    DatabaseReference blogsRef = FirebaseDatabase.instance
        .ref()
        .child('Blogs')
        .child(widget.blogPost.data.postId)
        .child('comments');
    blogsRef.onValue.listen((event) {}).cancel();
    super.dispose();
  }

  List<BlogComment> _parseComments(dynamic commentsData) {
    List<BlogComment> comments = [];
    if (commentsData != null && commentsData is Map) {
      List<BlogComment> extractedComments = [];
      for (var commentValue in commentsData.values) {
        if (commentValue is Map) {
          String commentText = commentValue['text'] ?? '';
          int timestamp = commentValue['timestamp'] ?? 0;
          String userEmail = commentValue['userEmail'] ?? '';

          extractedComments.add(BlogComment(
            commentText: commentText,
            timestamp: timestamp,
            userEmail: userEmail,
          ));
        } else {
          Fluttertoast.showToast(
              msg: "Unexpected commentValue format: $commentValue");
        }
      }

      extractedComments.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      comments.addAll(extractedComments);
    }
    return comments;
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      var snapshot = await FirebaseDatabase.instance
          .ref()
          .child('Blogs')
          .child(widget.blogPost.data.postId)
          .child('comments')
          .once();

      var data = snapshot.snapshot.value;
      List<BlogComment> updatedComments = _parseComments(data);

      setState(() {
        widget.blogPost.data.comments = updatedComments;
      });

      Fluttertoast.showToast(msg: "Comments refreshed successfully");
    } catch (error) {
      Fluttertoast.showToast(msg: "Error refreshing comments: $error");
    } finally {
      _isRefreshing = false;
    }
  }

  void _setupCommentsListener() {
    DatabaseReference commentsRef = FirebaseDatabase.instance
        .ref()
        .child('Blogs')
        .child(widget.blogPost.data.postId)
        .child('comments');

    commentsRef.onValue.listen((event) {
      var data = event.snapshot.value;
      List<BlogComment> updatedComments = _parseComments(data);

      setState(() {
        widget.blogPost.data.comments =
            updatedComments; // Update the comments list
      });
    }, onError: (error) {
      Fluttertoast.showToast(msg: "Error fetching comments: $error");
    });
  }

  Future<Map<String, dynamic>?> getUserDataFromEmail(String email) async {
    try {
      DatabaseReference reference = FirebaseDatabase.instance.ref();
      Query query =
          reference.child('Users').orderByChild('email').equalTo(email);

      DatabaseEvent event = await query.once();

      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> userData =
            snapshot.value as Map<dynamic, dynamic>;
        String key = userData.keys.first;
        Map<String, dynamic> user = userData[key].cast<String, dynamic>();
        return user;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCommentsListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Comments',
          style: TextStyle(
            color: Constants.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
          icon: Icon(
            Icons.arrow_back,
            size: 30,
            color: Constants.primaryColor,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SinglePost(
                    data: widget.blogPost.data,
                    isCommentScreen: true,
                  ),
                  ListView.builder(
                    itemCount: widget.blogPost.data.comments.length,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final comment = widget.blogPost.data.comments[index];
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: getUserDataFromEmail(comment.userEmail),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting ||
                              !snapshot.hasData) {
                            return const SizedBox();
                          }
                          final userData = snapshot.data!;
                          return CommentItem(
                            profilePicUrl: userData['photoUrl'] ??
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS3LtPpyEGxYGWK-cFpXK3bvjQajWfoXXwnhTXY5X-xrQ&s',
                            userEmail:
                                userData['displayName'] ?? comment.userEmail,
                            commentText: comment.commentText,
                            timestamp: comment.timestamp,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(
                    height: 100,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: TextStyle(
                  fontSize: 16,
                  color: Constants.primaryColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                addComment(_commentController.text);
                _commentController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: const Text(
                "Post",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
