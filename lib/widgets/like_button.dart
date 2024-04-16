import 'package:flutter/material.dart';
import 'package:harvest_guardian/constants.dart';

class LikeButton extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onTap;
  const LikeButton({super.key, required this.isLiked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? Colors.red : Constants.primaryColor,
        size: 25,
      ),
    );
  }
}