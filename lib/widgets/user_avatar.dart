import 'package:flutter/material.dart';
import 'dart:io';

/// A widget that displays a user avatar with proper error handling
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final File? imageFile;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 60,
    this.imageFile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildAvatar(context),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (imageFile != null) {
      // Use local file image with error handling
      return ClipOval(
        child: Image.file(
          imageFile!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Use network image with proper error handling
      return _buildNetworkImageAvatar(context);
    } else {
      // Default avatar
      return _buildDefaultAvatar();
    }
  }

  Widget _buildNetworkImageAvatar(BuildContext context) {
    // Add cache-busting parameter to prevent HTTP 412 errors
    String cacheBustedUrl = imageUrl!;
    if (!cacheBustedUrl.contains('?')) {
      cacheBustedUrl += '?timestamp=${DateTime.now().millisecondsSinceEpoch}';
    } else {
      cacheBustedUrl += '&timestamp=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return ClipOval(
      child: Image.network(
        cacheBustedUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: radius * 2,
            height: radius * 2,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: radius,
        color: Colors.grey[600],
      ),
    );
  }
}

/// Extension of UserAvatar with additional File parameter
class UserAvatarWithFile extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final File? imageFile;
  final VoidCallback? onTap;

  const UserAvatarWithFile({
    super.key,
    this.imageUrl,
    this.radius = 60,
    this.imageFile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      imageUrl: imageUrl,
      radius: radius,
      imageFile: imageFile,
      onTap: onTap,
    );
  }
}
