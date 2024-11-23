import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/add_blog_post_screen.dart';
import 'package:harvest_guardian/screens/comments.dart';
import 'package:harvest_guardian/utils/blog_comment.dart';
import 'package:harvest_guardian/utils/blogs.dart';
import 'package:harvest_guardian/widgets/community_post.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shimmer/shimmer.dart';

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
  Map<String, String> userProfilePics = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _getData();
    _fetchUserProfilePics();
    _setupBlogsListener();
  }

  @override
  void dispose() {
    DatabaseReference blogsRef = FirebaseDatabase.instance.ref().child('Blogs');
    blogsRef.onValue.listen((event) {}).cancel();
    super.dispose();
  }

  Future<void> _fetchUserProfilePics() async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('Users');
    try {
      var snapshot = await usersRef.once();

      var data = snapshot.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          userProfilePics.clear();
          data.forEach((uid, userData) {
            userProfilePics[userData['email']] =
                userData['photoUrl'] ?? Constants.defaultProfileImgUrl;
          });
        });
      } else {
        Fluttertoast.showToast(msg: "Error fetching user profile pictures");
      }
    } catch (error) {
      if (mounted) {
        Fluttertoast.showToast(
            msg: "Error fetching user profile pictures: $error");
      }
    }
  }

  Future<void> _handleRefresh() async {
    try {
      List<Blogs> newData = await _getData();
      setState(() {
        blogsData.clear();
        blogsData.addAll(newData);
      });

      Fluttertoast.showToast(msg: "Blog refreshed successfully");
    } catch (error) {
      Fluttertoast.showToast(msg: "Error refreshing data: $error");
    }
  }

  Future<List<Blogs>> _getData() async {
    DatabaseReference reference = FirebaseDatabase.instance.ref();
    setState(() {
      loading = true;
    });
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
        newData.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by timestamp

        if (mounted) {
          setState(() {
            loading = false;
          });
        }
        return newData;
      } else {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
        Fluttertoast.showToast(msg: "No Posts Uploaded Yet");
        return [];
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
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
          int votes = commentValue['votes'] ?? 0;
          List<String> votedUsers =
              List<String>.from(commentValue['votedUsers'] ?? []);

          extractedComments.add(BlogComment(
            commentText: commentText,
            timestamp: timestamp,
            userEmail: userEmail,
            votes: votes,
            votedUsers: votedUsers,
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
        newData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        if (mounted) {
          setState(() {
            blogsData = newData;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            blogsData = [];
          });
        }
      }
    }, onError: (error) {
      Fluttertoast.showToast(msg: "Error fetching blog posts: $error");
    });
  }

  Future<void> deleteImageFromFirebaseStorage(String imageUrl) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference imageRef = storage.refFromURL(imageUrl);
      await imageRef.delete();
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to delete image from storage: $e");
    }
  }

  void deletePost(Blogs data) {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

    databaseReference
        .child('Blogs')
        .child(data.postId)
        .remove()
        .then((_) async {
      await deleteImageFromFirebaseStorage(data.image);

      blogsData.removeWhere((blog) => blog.postId == data.postId);

      Fluttertoast.showToast(msg: "Post successfully deleted");
    }).catchError((error) {
      Fluttertoast.showToast(msg: "Failed to delete post: $error");
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
        child: loading
            ? _buildShimmerLoading()
            : blogsData.isEmpty
                ? _buildNoPostsMessage()
                : ListView.builder(
                    itemCount: blogsData.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              child: Comments(
                                blogPost: SinglePost(
                                  data: blogsData[index],
                                  isCommentScreen: true,
                                  userProfilePics: userProfilePics,
                                ),
                              ),
                              type: PageTransitionType.topToBottom,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            if (FirebaseAuth.instance.currentUser?.email ==
                                blogsData[index].userEmail)
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text(
                                            "Are you sure you want to delete this post?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("No"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              deletePost(blogsData[index]);
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Yes"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Delete",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SinglePost(
                              data: blogsData[index],
                              isCommentScreen: false,
                              userProfilePics: userProfilePics,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: blogsData.isNotEmpty
          ? FloatingActionButton.extended(
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
                ).then((_) {
                  _handleRefresh();
                });
              },
            )
          : null,
    );
  }

  Widget _buildNoPostsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_rounded,
            color: Constants.primaryColor,
            size: 120,
          ),
          SizedBox(height: 20),
          Text(
            'No Posts Yet',
            style: TextStyle(
              color: Constants.primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Join the conversation and be the first to post!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff58a67b),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton.icon(
            icon: Icon(Icons.add_circle_outline, color: Colors.white),
            label: Text(
              'Create Your First Post',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 8,
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageTransition(
                  child: const AddBlogPost(),
                  type: PageTransitionType.fade,
                ),
              ).then((_) {
                _handleRefresh();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(2, (_) => _buildShimmerSection()),
      ),
    );
  }

  Widget _buildShimmerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 300, // Adjust height based on image size
            color: Colors.grey[300]!,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 250, // Adjust width based on title length
                  height: 24,
                  color: Colors.grey[300]!,
                ),
              ),
              const SizedBox(height: 5),
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 350, // Adjust width based on description length
                  height: 36,
                  color: Colors.grey[300]!,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: ClipOval(
                      child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 100,
                          height: 20,
                          color: Colors.grey[300]!,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 100,
                          height: 20,
                          color: Colors.grey[300]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),
                  _buildShimmerLikeCommentShare(),
                  const SizedBox(width: 20),
                  _buildShimmerLikeCommentShare(),
                  const SizedBox(width: 20),
                  _buildShimmerLikeCommentShare(),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerLikeCommentShare() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[300]!,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 30,
            height: 10,
            color: Colors.grey[300]!,
          ),
        ),
      ],
    );
  }
}
