import 'package:flutter/material.dart';

class AuthorInfo extends StatelessWidget {

  const AuthorInfo({ super.key, required this.user });

   @override
   Widget build(BuildContext context) {
       return Row(children: [CircleAvatar()],);
  }
}