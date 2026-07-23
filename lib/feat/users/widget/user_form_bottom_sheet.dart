import 'package:flutter/material.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/feat/users/controllers/users_controller.dart';

class UserFormBottomSheet extends StatefulWidget {
  final User? user;
  final UsersController controller;

  const UserFormBottomSheet({super.key, this.user, required this.controller});

  @override
  State<UserFormBottomSheet> createState() => _UserFormBottomSheetState();
}

class _UserFormBottomSheetState extends State<UserFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _totalController;

  bool _saving = false;
  late UserType _type;

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();

    final user = widget.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _totalController = TextEditingController(
      text: user != null ? user.total.toStringAsFixed(2) : '0',
    );

    _type = user?.type ?? UserType.buyer;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final total = double.tryParse(_totalController.text.trim()) ?? 0;
    final controller = widget.controller;

    try {
      final bool success;

      if (isEdit) {
        final updatedUser = widget.user!.copyWith(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          total: total,
          type: _type,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          status: Status.notScheduled,
        );

        success = await controller.updateUser(updatedUser);
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;

        final newUser = User(
          unified: '',
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          total: total,
          type: _type,
          createdAt: now,
          updatedAt: now,
          deviceId: '',
          status: Status.notScheduled,
        );

        success = await controller.addUser(newUser);
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.error ?? "حدث خطأ غير متوقع")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEdit ? "تعديل المستخدم" : "إضافة مستخدم",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "الاسم",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final trimmed = value?.trim();
                  if (trimmed == null || trimmed.isEmpty) {
                    return "الاسم مطلوب";
                  }
                  if (trimmed.length < 2) {
                    return "الاسم قصير";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "العنوان",
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "العنوان مطلوب";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "الرصيد",
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                validator: (value) {
                  final trimmed = value?.trim();
                  if (trimmed == null || trimmed.isEmpty) {
                    return "الرصيد مطلوب";
                  }
                  if (double.tryParse(trimmed) == null) {
                    return "قيمة غير صحيحة";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text("نوع المستخدم", style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<UserType>(
                      value: UserType.buyer,
                      groupValue: _type,
                      title: const Text("مشتري"),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _type = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserType>(
                      value: UserType.seller,
                      groupValue: _type,
                      title: const Text("بائع"),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _type = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _saving
                    ? const Padding(
                        key: ValueKey('loading'),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : SizedBox(
                        key: const ValueKey('button'),
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: Icon(isEdit ? Icons.save : Icons.person_add),
                          label: Text(
                            isEdit ? "حفظ التعديلات" : "إضافة المستخدم",
                          ),
                          onPressed: _saveUser,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
