import 'package:harvest_guardian/utils/blog_comment.dart';

class Blogs {
  String desc, title, image, postId, userEmail;
  int timestamp;
  List<String> likes;
  List<BlogComment> comments;
  Blogs(
      {required this.desc,
      required this.title,
      required this.image,
      required this.postId,
      required this.likes,
      required this.comments,
      required this.timestamp,
      required this.userEmail});
}
