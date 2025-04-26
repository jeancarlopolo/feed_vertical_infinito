import 'package:flutter/material.dart';

class AuthorInfo extends StatelessWidget {
  const AuthorInfo({
    super.key,
    required this.authorHandle,
    required this.authorDisplayName,
    required this.authorAvatar,
  });
  final String authorHandle;
  final String authorDisplayName;
  final String authorAvatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(backgroundImage: NetworkImage(authorAvatar)),
        Text(authorDisplayName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(authorHandle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
