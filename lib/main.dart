import 'package:flutter/material.dart';

import 'services/import_service.dart';
import 'services/invoice_service.dart';
import 'services/payment_service.dart';
import 'services/product_service.dart';
import 'services/sync_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final userService = UserService();
  final productService = ProductService();
  final invoiceService = InvoiceService();
  final paymentService = PaymentService();
  final importService = ImportService();
  final syncService = SyncService();

  runApp(
    MyApp(
      userService: userService,
      productService: productService,
      invoiceService: invoiceService,
      paymentService: paymentService,
      importService: importService,
      syncService: syncService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final UserService userService;
  final ProductService productService;
  final InvoiceService invoiceService;
  final PaymentService paymentService;
  final ImportService importService;
  final SyncService syncService;

  const MyApp({
    super.key,
    required this.userService,
    required this.productService,
    required this.invoiceService,
    required this.paymentService,
    required this.importService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        userService: userService,
        productService: productService,
        invoiceService: invoiceService,
        paymentService: paymentService,
        importService: importService,
        syncService: syncService,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final UserService userService;
  final ProductService productService;
  final InvoiceService invoiceService;
  final PaymentService paymentService;
  final ImportService importService;
  final SyncService syncService;

  const MyHomePage({
    super.key,
    required this.title,
    required this.userService,
    required this.productService,
    required this.invoiceService,
    required this.paymentService,
    required this.importService,
    required this.syncService,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _inputController = TextEditingController();
  String _output = '';

  void _insertData() async {
    final input = _inputController.text;
    if (input.isNotEmpty) {
      await widget.userService.createUser();
      setState(() {
        _output = 'User created with input: $input';
      });
    }
  }

  void _updateData() async {
    final input = _inputController.text;
    if (input.isNotEmpty) {
      await widget.userService.updateUser();
      setState(() {
        _output = 'User updated with input: $input';
      });
    }
  }

  void _importData() async {
    await widget.importService.importJson();
    setState(() {
      _output = 'Data imported successfully';
    });
  }

  void _syncData() async {
    await widget.syncService.syncUser();
    setState(() {
      _output = 'Data synchronized successfully';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(labelText: 'Enter data'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _insertData,
              child: const Text('Insert Data'),
            ),
            ElevatedButton(
              onPressed: _updateData,
              child: const Text('Update Data'),
            ),
            ElevatedButton(
              onPressed: _importData,
              child: const Text('Import Data'),
            ),
            ElevatedButton(
              onPressed: _syncData,
              child: const Text('Sync Data'),
            ),
            const SizedBox(height: 16),
            Text(_output, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
