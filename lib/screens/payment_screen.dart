import "package:flutter/material.dart";

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payment")),
      body: Center(
        child: Text("Payment Screen", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
