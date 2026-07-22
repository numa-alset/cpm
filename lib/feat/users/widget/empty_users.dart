import 'package:flutter/material.dart';

class EmptyUsers extends StatelessWidget {
  const EmptyUsers({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_outline, size: 80),

          SizedBox(height: 12),

          Text("No users found"),
        ],
      ),
    );
  }
}
