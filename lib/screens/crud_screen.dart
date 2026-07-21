import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/models/product.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/repositories/fatora_product_repository.dart';
import 'package:naji/core/repositories/fatora_repository.dart';
import 'package:naji/core/repositories/payment_repository.dart';
import 'package:naji/core/repositories/product_repository.dart';
import 'package:naji/core/repositories/user_repository.dart';
import 'package:naji/locator/locator.dart';
import 'package:uuid/uuid.dart';

class CrudScreen extends StatefulWidget {
  const CrudScreen({super.key});

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final FatoraRepository _fatoraRepository;
  late final UserRepository _userRepository;
  late final PaymentRepository _paymentRepository;
  late final ProductRepository _productRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fatoraRepository = getIt<FatoraRepository>();
    _userRepository = getIt<UserRepository>();
    _paymentRepository = getIt<PaymentRepository>();
    _productRepository = getIt<ProductRepository>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار CRUD'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المستخدمون'),
            Tab(text: 'الفواتير'),
            Tab(text: 'المدفوعات'),
            Tab(text: 'المنتجات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserCrudTab(userRepository: _userRepository),
          _InvoiceCrudTab(
            invoiceRepository: _fatoraRepository,
            userRepository: _userRepository,
            productRepository: _productRepository,
            fatoraProductRepository: getIt<FatoraProductRepository>(),
          ),
          _PaymentCrudTab(
            paymentRepository: _paymentRepository,
            userRepository: _userRepository,
          ),
          _ProductCrudTab(productRepository: _productRepository),
        ],
      ),
    );
  }
}

class _UserCrudTab extends StatefulWidget {
  final UserRepository userRepository;

  const _UserCrudTab({required this.userRepository});

  @override
  State<_UserCrudTab> createState() => _UserCrudTabState();
}

class _UserCrudTabState extends State<_UserCrudTab> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _totalController = TextEditingController();
  final _unifiedController = TextEditingController();
  UserType _selectedType = UserType.buyer;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await widget.userRepository.getAll();
    setState(() => _users = users);
  }

  Future<void> _createUser() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء ملء جميع الحقول')));
      return;
    }

    final user = User(
      unified: const Uuid().v4(),
      name: _nameController.text,
      location: _locationController.text,
      total: double.tryParse(_totalController.text) ?? 0,
      type: _selectedType,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      deviceId: 'test-device',
      status: Status.notScheduled,
    );

    await widget.userRepository.create(user);
    _nameController.clear();
    _locationController.clear();
    _totalController.clear();
    _unifiedController.clear();
    _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء المستخدم بنجاح')));
    }
  }

  Future<void> _updateUser(User user) async {
    final updatedUser = user.copyWith(
      name: _nameController.text.isNotEmpty ? _nameController.text : user.name,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : user.location,
      total: _totalController.text.isNotEmpty
          ? double.tryParse(_totalController.text) ?? user.total
          : user.total,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await widget.userRepository.update(updatedUser);
    _nameController.clear();
    _locationController.clear();
    _totalController.clear();
    _unifiedController.clear();
    _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تحديث المستخدم بنجاح')));
    }
  }

  Future<void> _deleteUser(String unified) async {
    await widget.userRepository.delete(unified);
    _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المستخدم بنجاح')));
    }
  }

  void _editUser(User user) {
    _nameController.text = user.name;
    _locationController.text = user.location;
    _totalController.text = user.total.toString();
    _unifiedController.text = user.unified;
    _selectedType = user.type;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'الموقع'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _totalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الإجمالي'),
                ),
                const SizedBox(height: 12),
                DropdownButton<UserType>(
                  value: _selectedType,
                  isExpanded: true,
                  items: UserType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == UserType.buyer ? 'مشتري' : 'بائع',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _unifiedController.text.isEmpty
                            ? _createUser
                            : () => _updateUser(
                                _users.firstWhere(
                                  (u) => u.unified == _unifiedController.text,
                                ),
                              ),
                        child: Text(
                          _unifiedController.text.isEmpty ? 'إنشاء' : 'تحديث',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _nameController.clear();
                        _locationController.clear();
                        _totalController.clear();
                        _unifiedController.clear();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'عدد المستخدمين: ${_users.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ..._users.map(
          (user) => Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(user.name),
              subtitle: Text('${user.location} - ${user.total}'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _editUser(user),
                    child: const Text('تعديل'),
                  ),
                  PopupMenuItem(
                    onTap: () => _deleteUser(user.unified),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _totalController.dispose();
    _unifiedController.dispose();
    super.dispose();
  }
}

class _InvoiceCrudTab extends StatefulWidget {
  final FatoraRepository invoiceRepository;
  final UserRepository userRepository;
  final ProductRepository productRepository;
  final FatoraProductRepository fatoraProductRepository;

  const _InvoiceCrudTab({
    required this.invoiceRepository,
    required this.userRepository,
    required this.productRepository,
    required this.fatoraProductRepository,
  });

  @override
  State<_InvoiceCrudTab> createState() => _InvoiceCrudTabState();
}

class _InvoiceCrudTabState extends State<_InvoiceCrudTab> {
  final _totalController = TextEditingController();
  final _noteController = TextEditingController();
  final _unifiedController = TextEditingController();
  final _quantityController = TextEditingController();

  InvoiceType _selectedType = InvoiceType.sale;
  int _selectedDate = DateTime.now().millisecondsSinceEpoch;
  List<Fatora> _invoices = [];
  List<User> _users = [];
  List<Product> _products = [];
  String? _selectedUserId;
  String? _selectedProductId;
  bool _isLoadingUsers = false;
  bool _isLoadingProducts = false;

  // Track products being added to current invoice
  List<Map<String, dynamic>> _invoiceProducts = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadInvoices();
    _loadProducts();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await widget.userRepository.getAll();
      if (mounted) {
        setState(() {
          _users = users;
          if (_users.isNotEmpty && _selectedUserId == null) {
            _selectedUserId = _users.first.unified;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل المستخدمين: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _loadInvoices() async {
    final invoices = await widget.invoiceRepository.getAll();
    setState(() => _invoices = invoices);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await widget.productRepository.getAll();
      if (mounted) {
        setState(() {
          _products = products;
          if (_products.isNotEmpty && _selectedProductId == null) {
            _selectedProductId = _products.first.unified;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل المنتجات: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  void _addProductToInvoice() {
    if (_selectedProductId == null || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار منتج وإدخال الكمية')),
      );
      return;
    }

    final product = _products.firstWhere(
      (e) => e.unified == _selectedProductId,
    );

    final quantity = double.tryParse(_quantityController.text) ?? 0;

    final index = _invoiceProducts.indexWhere(
      (e) => (e['product'] as Product).unified == product.unified,
    );

    if (index != -1) {
      _invoiceProducts[index]['quantity'] =
          (_invoiceProducts[index]['quantity'] as double) + quantity;
    } else {
      _invoiceProducts.add({'product': product, 'quantity': quantity});
    }

    _quantityController.clear();

    setState(() {});
  }

  void _updateInvoiceTotal() {
    final total = _invoiceProducts.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as double),
    );
    _totalController.text = total.toStringAsFixed(2);
  }

  void _removeProductFromInvoice(int index) {
    setState(() {
      _invoiceProducts.removeAt(index);
    });
    _updateInvoiceTotal();
  }

  Future<void> _createInvoice() async {
    if (_selectedUserId == null || _invoiceProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة منتجات للفاتورة')),
      );
      return;
    }

    final invoiceTotal = _invoiceProducts.fold<double>(0, (sum, item) {
      final product = item['product'] as Product;
      final quantity = item['quantity'] as double;

      return sum + (product.price * quantity);
    });
    final invoice = Fatora(
      unified: const Uuid().v4(),
      userUnified: _selectedUserId!,
      writer: 'test-writer',
      total: invoiceTotal,
      date: _selectedDate,
      type: _selectedType,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      deviceId: 'test-device',
      status: Status.notScheduled,
    );

    await widget.invoiceRepository.create(invoice);

    // Add products to fatora_products
    for (final item in _invoiceProducts) {
      final product = item['product'] as Product;
      final fatoraProduct = FatoraProduct(
        unified: const Uuid().v4(),
        fatoraUnified: invoice.unified,
        productUnified: product.unified,
        productName: product.name,
        price: product.price,
        quantity: item['quantity'] as double,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'test-device',
        status: Status.notScheduled,
      );
      await widget.fatoraProductRepository.create(fatoraProduct);
    }

    _totalController.clear();
    _noteController.clear();
    _unifiedController.clear();
    _quantityController.clear();
    _selectedDate = DateTime.now().millisecondsSinceEpoch;
    _invoiceProducts.clear();
    if (_users.isNotEmpty) {
      _selectedUserId = _users.first.unified;
    }
    _loadInvoices();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء الفاتورة بنجاح')));
    }
  }

  void _editInvoice(Fatora invoice) {
    _selectedUserId = invoice.userUnified;
    _totalController.text = invoice.total.toString();
    _noteController.text = invoice.note ?? '';
    _unifiedController.text = invoice.unified;
    _selectedType = invoice.type;
    _selectedDate = invoice.date;
    setState(() {});
  }

  Future<void> _deleteInvoice(String unified) async {
    await widget.invoiceRepository.delete(unified);
    _loadInvoices();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الفاتورة بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isLoadingUsers)
                  const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DropdownButton<String>(
                    value: _selectedUserId,
                    isExpanded: true,
                    hint: const Text('اختر المستخدم'),
                    items: _users
                        .map(
                          (user) => DropdownMenuItem<String>(
                            value: user.unified,
                            child: Text(
                              '${user.name} (${user.type == UserType.buyer ? 'مشتري' : 'بائع'})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedUserId = value),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'الملاحظات (اختياري)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButton<InvoiceType>(
                  value: _selectedType,
                  isExpanded: true,
                  items: InvoiceType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == InvoiceType.sale ? 'بيع' : 'شراء',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat('yyyy-MM-dd').format(
                      DateTime.fromMillisecondsSinceEpoch(_selectedDate),
                    ),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.fromMillisecondsSinceEpoch(
                        _selectedDate,
                      ),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(
                        () => _selectedDate = date.millisecondsSinceEpoch,
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'إضافة منتجات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (_isLoadingProducts)
                  const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DropdownButton<String>(
                    value: _selectedProductId,
                    isExpanded: true,
                    hint: const Text('اختر المنتج'),
                    items: _products
                        .map(
                          (product) => DropdownMenuItem<String>(
                            value: product.unified,
                            child: Text('${product.name} (${product.price})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedProductId = value),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة المنتج'),
                  onPressed: _addProductToInvoice,
                ),
                const SizedBox(height: 20),
                if (_invoiceProducts.isNotEmpty) ...[
                  const Text(
                    'منتجات الفاتورة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ..._invoiceProducts.asMap().entries.map((entry) {
                    int index = entry.key;
                    final item = entry.value;
                    final product = item['product'] as Product;
                    final quantity = item['quantity'] as double;
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        'الكمية: $quantity × السعر: ${product.price}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeProductFromInvoice(index),
                      ),
                      dense: true,
                    );
                  }),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _totalController.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'لم تضف منتجات بعد',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createInvoice,
                        child: const Text('إنشاء الفاتورة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _totalController.clear();
                        _noteController.clear();
                        _unifiedController.clear();
                        _quantityController.clear();
                        _selectedDate = DateTime.now().millisecondsSinceEpoch;
                        _invoiceProducts.clear();
                        if (_users.isNotEmpty) {
                          _selectedUserId = _users.first.unified;
                        }
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'عدد الفواتير: ${_invoices.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ..._invoices.map(
          (invoice) => Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text('${invoice.total} - ${invoice.type.name}'),
              subtitle: Text(
                DateFormat(
                  'yyyy-MM-dd',
                ).format(DateTime.fromMillisecondsSinceEpoch(invoice.date)),
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _editInvoice(invoice),
                    child: const Text('تعديل'),
                  ),
                  PopupMenuItem(
                    onTap: () => _deleteInvoice(invoice.unified),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _totalController.dispose();
    _noteController.dispose();
    _unifiedController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}

class _PaymentCrudTab extends StatefulWidget {
  final PaymentRepository paymentRepository;
  final UserRepository userRepository;

  const _PaymentCrudTab({
    required this.paymentRepository,
    required this.userRepository,
  });

  @override
  State<_PaymentCrudTab> createState() => _PaymentCrudTabState();
}

class _PaymentCrudTabState extends State<_PaymentCrudTab> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int _selectedDate = DateTime.now().millisecondsSinceEpoch;
  List<Payment> _payments = [];
  List<User> _users = [];
  String? _selectedUserId;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadPayments();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await widget.userRepository.getAll();
      if (mounted) {
        setState(() {
          _users = users;
          if (_users.isNotEmpty && _selectedUserId == null) {
            _selectedUserId = _users.first.unified;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل المستخدمين: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _loadPayments() async {
    final payments = await widget.paymentRepository.getAll();
    setState(() => _payments = payments);
  }

  Future<void> _createPayment() async {
    if (_selectedUserId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء ملء جميع الحقول')));
      return;
    }

    final payment = Payment(
      unified: const Uuid().v4(),
      userUnified: _selectedUserId!,
      amount: double.tryParse(_amountController.text) ?? 0,
      date: _selectedDate,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      deviceId: 'test-device',
      status: Status.notScheduled,
    );

    await widget.paymentRepository.create(payment);
    _amountController.clear();
    _noteController.clear();
    _selectedDate = DateTime.now().millisecondsSinceEpoch;
    if (_users.isNotEmpty) {
      _selectedUserId = _users.first.unified;
    }
    _loadPayments();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء المدفوعة بنجاح')));
    }
  }

  Future<void> _deletePayment(String unified) async {
    await widget.paymentRepository.delete(unified);
    _loadPayments();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المدفوعة بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isLoadingUsers)
                  const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DropdownButton<String>(
                    value: _selectedUserId,
                    isExpanded: true,
                    hint: const Text('اختر المستخدم'),
                    items: _users
                        .map(
                          (user) => DropdownMenuItem<String>(
                            value: user.unified,
                            child: Text(
                              '${user.name} (${user.type == UserType.buyer ? 'مشتري' : 'بائع'})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedUserId = value),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat('yyyy-MM-dd').format(
                      DateTime.fromMillisecondsSinceEpoch(_selectedDate),
                    ),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.fromMillisecondsSinceEpoch(
                        _selectedDate,
                      ),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(
                        () => _selectedDate = date.millisecondsSinceEpoch,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createPayment,
                        child: const Text('إنشاء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _amountController.clear();
                        _noteController.clear();
                        _selectedDate = DateTime.now().millisecondsSinceEpoch;
                        if (_users.isNotEmpty) {
                          _selectedUserId = _users.first.unified;
                        }
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'عدد المدفوعات: ${_payments.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ..._payments.map(
          (payment) => Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text('${payment.amount}'),
              subtitle: Text(
                DateFormat(
                  'yyyy-MM-dd',
                ).format(DateTime.fromMillisecondsSinceEpoch(payment.date)),
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _deletePayment(payment.unified),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class _ProductCrudTab extends StatefulWidget {
  final ProductRepository productRepository;

  const _ProductCrudTab({required this.productRepository});

  @override
  State<_ProductCrudTab> createState() => _ProductCrudTabState();
}

class _ProductCrudTabState extends State<_ProductCrudTab> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _unifiedController = TextEditingController();
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await widget.productRepository.getAll();
    setState(() => _products = products);
  }

  Future<void> _createProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء ملء جميع الحقول')));
      return;
    }

    final product = Product(
      unified: const Uuid().v4(),
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      deviceId: 'test-device',
      status: Status.notScheduled,
    );

    await widget.productRepository.create(product);
    _nameController.clear();
    _priceController.clear();
    _unifiedController.clear();
    _loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء المنتج بنجاح')));
    }
  }

  void _editProduct(Product product) {
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _unifiedController.text = product.unified;
    setState(() {});
  }

  Future<void> _deleteProduct(String unified) async {
    await widget.productRepository.delete(unified);
    _loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المنتج بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'السعر'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createProduct,
                        child: const Text('إنشاء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _nameController.clear();
                        _priceController.clear();
                        _unifiedController.clear();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'عدد المنتجات: ${_products.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ..._products.map(
          (product) => Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(product.name),
              subtitle: Text('${product.price}'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _editProduct(product),
                    child: const Text('تعديل'),
                  ),
                  PopupMenuItem(
                    onTap: () => _deleteProduct(product.unified),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unifiedController.dispose();
    super.dispose();
  }
}
