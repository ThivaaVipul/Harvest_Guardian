// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/comments.dart';
import 'package:harvest_guardian/utils/blogs.dart';
import 'package:harvest_guardian/widgets/like_button.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';

class SinglePost extends StatefulWidget {
  final Blogs data;
  final bool isCommentScreen;
  const SinglePost(
      {super.key, required this.data, required this.isCommentScreen});

  @override
  State<SinglePost> createState() => _SinglePostState();
}

class _SinglePostState extends State<SinglePost> {
  final currentUser = FirebaseAuth.instance.currentUser;
  late bool isLiked;
  int likeCount = 0;
  int commentCount = 0;
  late bool showHeart;
  double heartSize = 100.0;

  @override
  void initState() {
    super.initState();
    _updateLikeCount();
    _updateCommentCount();
    isLiked = widget.data.likes.contains(currentUser?.email);
    showHeart = false;
  }

  void shareToWhatsApp() async {
    try {
      await FlutterShare.share(
        title: widget.data.title,
        text: "*${widget.data.title}* ${widget.data.desc}",
        linkUrl: widget.data.image,
        chooserTitle: 'Share via',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sharing: $e');
    }
  }

  String formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    String formattedDate = DateFormat('yyyy/MM/dd - HH:mm').format(dateTime);

    return formattedDate;
  }

  void toggleLike() async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

    setState(() {
      isLiked = !isLiked;
    });

    if (isLiked) {
      // Add the current user's email to the 'likes' list
      await databaseReference
          .child('Blogs')
          .child(widget.data.postId)
          .child('likes')
          .push()
          .set(currentUserEmail);

      if (mounted) {
        setState(() {
          showHeart = true;
          heartSize = 100.0;
        });
      }

      Future.delayed(
        const Duration(milliseconds: 1500),
        () {
          if (mounted) {
            setState(() {
              showHeart = false;
              heartSize = 0.0;
            });
          }
        },
      );
    } else {
      // Remove the current user's email from the 'likes' list
      final snapshot = await databaseReference
          .child('Blogs')
          .child(widget.data.postId)
          .child('likes')
          .orderByValue()
          .equalTo(currentUserEmail)
          .get();

      if (snapshot.value != null) {
        (snapshot.value as Map).forEach((key, _) {
          databaseReference
              .child('Blogs')
              .child(widget.data.postId)
              .child('likes')
              .child(key)
              .remove();
        });
      }
    }

    // Fetch updated likes data from Firebase
    var snapshot = await databaseReference
        .child("Blogs")
        .child(widget.data.postId)
        .child("likes")
        .once();

    var data = snapshot.snapshot.value;
    List<String> updatedLikes = _parseLikes(data);

    setState(() {
      widget.data.likes = updatedLikes;
    });

    _updateLikeCount();
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

  void _updateLikeCount() {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    databaseReference
        .child('Blogs')
        .child(widget.data.postId)
        .child('likes')
        .onValue
        .listen((event) {
      if (mounted) {
        if (event.snapshot.value != null) {
          setState(() {
            likeCount = (event.snapshot.value as Map).length;
          });
        } else {
          setState(() {
            likeCount = 0;
          });
        }
      }
    });
  }

  void _updateCommentCount() {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    databaseReference
        .child('Blogs')
        .child(widget.data.postId)
        .child('comments')
        .onValue
        .listen((event) {
      if (mounted) {
        if (event.snapshot.value != null) {
          setState(() {
            commentCount = (event.snapshot.value as Map).length;
          });
        } else {
          setState(() {
            commentCount = 0;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Constants.primaryColor, width: 1),
      ),
      margin: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Hero(
                tag: 'imageHero_${widget.data.postId}',
                child: GestureDetector(
                  onDoubleTap: toggleLike,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          return Scaffold(
                            backgroundColor: Colors.white,
                            appBar: AppBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              leading: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Constants.primaryColor,
                                  size: 35,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              title: Text(
                                widget.data.title,
                                style: TextStyle(
                                  color: Constants.primaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            body: Center(
                              child: Image.network(
                                widget.data.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image(
                      width: MediaQuery.of(context).size.width,
                      height: 250.0,
                      image: NetworkImage(widget.data.image),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              if (showHeart)
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 70,
                  top: 250.0 / 2 - 50,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: showHeart ? 1.0 : 0.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: showHeart ? heartSize : 100.0,
                      height: showHeart ? heartSize : 100.0,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 100,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.title,
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.data.desc,
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'By : ${widget.data.userEmail}',
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'On : ${formatTimestamp(widget.data.timestamp)}',
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              Column(
                children: [
                  const SizedBox(height: 20),
                  LikeButton(isLiked: isLiked, onTap: toggleLike),
                  Text(
                    likeCount.toString(),
                    style: TextStyle(color: Constants.primaryColor),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      if (!widget.isCommentScreen) {
                        Navigator.pushReplacement(
                          context,
                          PageTransition(
                              child: Comments(
                                blogPost: SinglePost(
                                  data: widget.data,
                                  isCommentScreen: true,
                                ),
                              ),
                              type: PageTransitionType.topToBottom),
                        );
                      }
                    },
                    child: Icon(
                      Icons.comment,
                      size: 25,
                      color: Constants.primaryColor,
                    ),
                  ),
                  Text(
                    commentCount.toString(),
                    style: TextStyle(color: Constants.primaryColor),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: shareToWhatsApp,
                child: Icon(
                  Icons.share,
                  size: 25,
                  color: Constants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
