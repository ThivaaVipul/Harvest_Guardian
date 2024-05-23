class BlogComment {
  final String commentText;
  final int timestamp;
  final String userEmail;
  final int votes;
  final List<String> votedUsers;

  BlogComment({
    required this.commentText,
    required this.timestamp,
    required this.userEmail,
    required this.votes,
    required this.votedUsers,
  });
}
