import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  bool _saving = false;

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();

    final user = widget.user;

    _nameController = TextEditingController(text: user?.name ?? '');

    _locationController = TextEditingController(text: user?.location ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    final controller = widget.controller;

    try {
      final bool success;

      if (isEdit) {
        final updatedUser = widget.user!.copyWith(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
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
          createdAt: now,
          updatedAt: now,
          deviceId: '',
          status: Status.notScheduled,
        );

        success = await controller.addUser(newUser);
      }

      if (!mounted) return;

      if (success) {
        context.pop(true);
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
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------------------------------------------------
                // HEADER
                // -------------------------------------------------------------
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_rounded
                            : Icons.person_add_alt_1_rounded,
                        color: colors.onPrimaryContainer,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? "تعديل المستخدم" : "إضافة مستخدم",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            isEdit
                                ? "تعديل بيانات المستخدم"
                                : "أدخل بيانات المستخدم",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: "إغلاق",
                      onPressed: _saving ? null : () => context.pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // BASIC INFORMATION
                // -------------------------------------------------------------
                _buildSectionTitle(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: "بيانات المستخدم",
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    context,
                    label: "الاسم",
                    hint: "أدخل اسم المستخدم",
                    icon: Icons.person_outline_rounded,
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

                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationController,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    context,
                    label: "العنوان",
                    hint: "مثال: حمص، دمشق...",
                    icon: Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "العنوان مطلوب";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // -------------------------------------------------------------
                // SAVE
                // -------------------------------------------------------------
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _saving
                      ? Container(
                          key: const ValueKey("saving"),
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : FilledButton.icon(
                          key: const ValueKey("save"),
                          onPressed: _saveUser,
                          icon: Icon(
                            isEdit
                                ? Icons.save_rounded
                                : Icons.person_add_alt_1_rounded,
                          ),
                          label: Text(
                            isEdit ? "حفظ التعديلات" : "إضافة المستخدم",
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TITLE
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 19, color: colors.primary),

        const SizedBox(width: 7),

        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }
}
