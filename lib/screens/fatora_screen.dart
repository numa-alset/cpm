import "package:flutter/material.dart";

class FatoraScreen extends StatelessWidget {
  const FatoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fatora")),
      body: Center(
        child: Text("Fatora Screen", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
