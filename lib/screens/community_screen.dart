import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/add_blog_post_screen.dart';
import 'package:harvest_guardian/screens/comments.dart';
import 'package:harvest_guardian/utils/blog_comment.dart';
import 'package:harvest_guardian/utils/blogs.dart';
import 'package:harvest_guardian/widgets/community_post.dart';
import 'package:page_transition/page_transition.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<Blogs> blogsData = [];

  @override
  void initState() {
    super.initState();
    _getData();
    _setupBlogsListener();
  }

  @override
  void dispose() {
    DatabaseReference blogsRef = FirebaseDatabase.instance.ref().child('Blogs');
    blogsRef.onValue.listen((event) {}).cancel();

    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      List<Blogs> newData = await _getData();

      setState(() {
        blogsData = newData;
      });

      Fluttertoast.showToast(msg: "Blog refreshed successfully");
    } catch (error) {
      Fluttertoast.showToast(msg: "Error refreshing data: $error");
    }
  }

  Future<List<Blogs>> _getData() async {
    DatabaseReference reference = FirebaseDatabase.instance.ref();
    try {
      var snapshot = await reference.child("Blogs").once();
      var data = snapshot.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        List<Blogs> newData = [];
        data.forEach((key, value) {
          List<String> likes = _parseLikes(value['likes']);
          List<BlogComment> comments = _parseComments(value['comments']);

          newData.add(
            Blogs(
              desc: value['desc'],
              title: value['title'],
              image: value['image'],
              postId: key,
              likes: likes,
              comments: comments,
              timestamp: value['timestamp'],
              userEmail: value['userEmail'],
            ),
          );
        });
        return newData;
      } else {
        Fluttertoast.showToast(msg: "No Posts Uploaded Yet");
        return [];
      }
    } catch (error) {
      Fluttertoast.showToast(msg: "Error fetching data: $error");
      rethrow;
    }
  }

  List<String> _parseLikes(dynamic likesData) {
    List<String> likes = [];
    if (likesData != null) {
      if (likesData is List) {
        likes = List<String>.from(likesData);
      } else if (likesData is Map) {
        for (var value in likesData.values) {
          if (value is String) {
            likes.add(value);
          } else {
            Fluttertoast.showToast(
                msg: "Unexpected likesData format: $likesData");
          }
        }
      } else if (likesData is String) {
        likes.add(likesData);
      } else {
        Fluttertoast.showToast(msg: "Unexpected likesData format: $likesData");
      }
    }
    return likes;
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

  void _setupBlogsListener() {
    DatabaseReference blogsRef = FirebaseDatabase.instance.ref().child('Blogs');

    blogsRef.onValue.listen((event) {
      var data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        List<Blogs> newData = [];
        data.forEach((key, value) {
          List<String> likes = _parseLikes(value['likes']);
          List<BlogComment> comments = _parseComments(value['comments']);

          newData.add(
            Blogs(
              desc: value['desc'],
              title: value['title'],
              image: value['image'],
              postId: key,
              likes: likes,
              comments: comments,
              timestamp: value['timestamp'],
              userEmail: value['userEmail'],
            ),
          );
        });
        setState(() {
          blogsData = newData;
        });
      } else {
        setState(() {
          blogsData = [];
        });
      }
    }, onError: (error) {
      Fluttertoast.showToast(msg: "Error fetching blog posts: $error");
    });
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
          'Harvest Guardian Community',
          style: TextStyle(
            color: Constants.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: FutureBuilder<List<Blogs>>(
          future: _getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Constants.primaryColor,
                ),
              );
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              // Sort the blog posts based on timestamp
              snapshot.data!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              return ListView.builder(
                itemCount: snapshot.data!.length,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          child: Comments(
                            blogPost: SinglePost(
                              data: snapshot.data![index],
                              isCommentScreen: true,
                            ),
                          ),
                          type: PageTransitionType.topToBottom,
                        ),
                      );
                    },
                    child: SinglePost(
                      data: snapshot.data![index],
                      isCommentScreen: false,
                    ),
                  );
                },
              );
            } else {
              return Center(
                child: Text(
                  "No Posts Uploaded Yet",
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontSize: 18,
                  ),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Constants.primaryColor,
        icon: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
        label: const Text(
          'Ask Community',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(
            context,
            PageTransition(
              child: const AddBlogPost(),
              type: PageTransitionType.topToBottom,
            ),
          );
        },
      ),
    );
  }
}
