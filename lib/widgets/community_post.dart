// ignore_for_file: use_build_context_synchronously, deprecated_member_use, must_be_immutable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/comments.dart';
import 'package:harvest_guardian/utils/blogs.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:page_transition/page_transition.dart';

class SinglePost extends StatefulWidget {
  final Blogs data;
  final bool isCommentScreen;
  Map<String, String> userProfilePics = {};
  SinglePost(
      {super.key,
      required this.data,
      required this.isCommentScreen,
      required this.userProfilePics});

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
        text: "*${widget.data.title}*\n\n${widget.data.desc}",
        linkUrl: widget.data.image,
        chooserTitle: 'Share via',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error sharing: $e');
    }
  }

  String formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    String formattedDate = DateFormat('dd/MM/yyyy h:mm a').format(dateTime);

    return formattedDate;
  }

  Future<void> toggleLike() async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

    setState(() {
      isLiked = !isLiked;
    });

    if (isLiked) {
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
        const Duration(milliseconds: 1000),
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

    var snapshot = await databaseReference
        .child("Blogs")
        .child(widget.data.postId)
        .child("likes")
        .once();

    var data = snapshot.snapshot.value;
    List<String> updatedLikes = _parseLikes(data);
    if (mounted) {
      setState(() {
        widget.data.likes = updatedLikes;
      });
    }

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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
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
                              child: CachedNetworkImage(
                                imageUrl: widget.data.image,
                                placeholder: (context, url) => Lottie.asset(
                                  'assets/loading_animation_txt.json',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.fill,
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      width: MediaQuery.of(context).size.width,
                      height: 300,
                      fit: BoxFit.cover,
                      imageUrl: widget.data.image,
                      placeholder: (context, url) => Center(
                        child: Lottie.asset(
                          'assets/loading_animation_txt.json',
                          width: 100,
                          height: 100,
                          fit: BoxFit.fill,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              if (showHeart)
                Positioned(
                  left: (MediaQuery.of(context).size.width - heartSize) / 2,
                  top: 300.0 / 2 - 50,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: showHeart ? 1.0 : 0.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: showHeart ? heartSize : 100.0,
                      height: showHeart ? heartSize : 100.0,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
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
                SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget
                          .userProfilePics[widget.data.userEmail]
                          .toString()),
                      radius: 25,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.userEmail,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatTimestamp(widget.data.timestamp),
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  GestureDetector(
                    onTap: toggleLike,
                    child: Icon(
                      widget.data.likes.contains(currentUser?.email)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.data.likes.contains(currentUser?.email)
                          ? Colors.red
                          : Constants.primaryColor,
                      size: 25,
                    ),
                  ),
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
                        Navigator.push(
                          context,
                          PageTransition(
                              child: Comments(
                                blogPost: SinglePost(
                                  data: widget.data,
                                  isCommentScreen: true,
                                  userProfilePics: widget.userProfilePics,
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
