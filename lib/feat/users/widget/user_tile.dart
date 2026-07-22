import 'package:flutter/material.dart';
import 'package:naji/core/models/user.dart';

class UserTile extends StatelessWidget {
  final User user;

  const UserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        // navigate later
      },

      leading: CircleAvatar(child: Text(user.name[0])),

      title: Text(user.name),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.location),

          Text(user.type == UserType.buyer ? "Buyer" : "Seller"),
        ],
      ),

      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Balance"),

          Text(
            user.total.toStringAsFixed(2),
            style: TextStyle(
              color: user.total >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
