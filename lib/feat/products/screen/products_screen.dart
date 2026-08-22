// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:naji/core/models/enum_status.dart';
// import 'package:naji/core/models/product.dart';
// import 'package:naji/core/services/id_service.dart';
// import 'package:naji/core/services/product_service.dart';
// import 'package:naji/feat/products/controller/products_controller.dart';
// import 'package:provider/provider.dart';
//
// class ProductsScreen extends StatelessWidget {
//   const ProductsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) =>
//           ProductsController(productService: GetIt.I<ProductService>())
//             ..loadProducts(),
//       child: const _ProductsView(),
//     );
//   }
// }
//
// class _ProductsView extends StatelessWidget {
//   const _ProductsView();
//
//   Future<bool> _confirmDelete(BuildContext context) async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (dialogContext) => AlertDialog(
//             title: const Text("حذف المنتج"),
//             content: const Text(
//               "هل أنت متأكد أنك تريد حذف هذا المنتج؟ لا يمكن التراجع عن هذا الإجراء.",
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(dialogContext, false),
//                 child: const Text("إلغاء"),
//               ),
//               FilledButton(
//                 style: FilledButton.styleFrom(backgroundColor: Colors.red),
//                 onPressed: () => Navigator.pop(dialogContext, true),
//                 child: const Text("حذف"),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }
//
//   void _showAddEditDialog(BuildContext context, {Product? product}) {
//     final isEditing = product != null;
//     final nameController = TextEditingController(text: product?.name ?? '');
//
//     // تعريف متحكمات السعرين
//     final priceSyController = TextEditingController(
//       text: product != null ? product.priceSy.toString() : '0',
//     );
//     final priceDollarController = TextEditingController(
//       text: product != null ? product.priceDollar.toString() : '0',
//     );
//
//     final formKey = GlobalKey<FormState>();
//
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: Text(isEditing ? "تعديل منتج" : "إضافة منتج جديد"),
//         content: Form(
//           key: formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: nameController,
//                   decoration: const InputDecoration(
//                     labelText: "اسم المنتج",
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.inventory_2_outlined),
//                   ),
//                   validator: (value) =>
//                       value == null || value.trim().isEmpty ? "مطلوب" : null,
//                 ),
//                 const SizedBox(height: 16),
//
//                 // حقل السعر بالليرة السورية
//                 TextFormField(
//                   controller: priceSyController,
//                   keyboardType: const TextInputType.numberWithOptions(
//                     decimal: true,
//                   ),
//                   decoration: const InputDecoration(
//                     labelText: "السعر (ل.س)",
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.money),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) return "مطلوب";
//                     final parsed = double.tryParse(value);
//                     if (parsed == null || parsed < 0) return "سعر غير صالح";
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//
//                 // حقل السعر بالدولار
//                 TextFormField(
//                   controller: priceDollarController,
//                   keyboardType: const TextInputType.numberWithOptions(
//                     decimal: true,
//                   ),
//                   decoration: const InputDecoration(
//                     labelText: "السعر (\$)",
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.attach_money),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) return "مطلوب";
//                     final parsed = double.tryParse(value);
//                     if (parsed == null || parsed < 0) return "سعر غير صالح";
//                     return null;
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text("إلغاء"),
//           ),
//           FilledButton(
//             onPressed: () async {
//               if (formKey.currentState!.validate()) {
//                 final now = DateTime.now().millisecondsSinceEpoch;
//
//                 final newProduct = Product(
//                   unified: product?.unified ?? IdService.generate(),
//                   name: nameController.text.trim(),
//                   priceSy: double.parse(priceSyController.text.trim()),
//                   priceDollar: double.parse(priceDollarController.text.trim()),
//                   createdAt: product?.createdAt ?? now,
//                   updatedAt: now,
//                   status: Status.notScheduled,
//                   deviceId: product?.deviceId ?? 'default_device',
//                 );
//
//                 final success = await context
//                     .read<ProductsController>()
//                     .saveProduct(newProduct, isEditing: isEditing);
//
//                 if (success && dialogContext.mounted) {
//                   Navigator.pop(dialogContext);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         isEditing
//                             ? "تم تعديل المنتج بنجاح"
//                             : "تمت إضافة المنتج بنجاح",
//                       ),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 }
//               }
//             },
//             child: const Text("حفظ"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = context.watch<ProductsController>();
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddEditDialog(context),
//         child: const Icon(Icons.add),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Custom Header & Search Bar
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   TextField(
//                     onChanged: controller.search,
//                     decoration: InputDecoration(
//                       hintText: "بحث عن منتج...",
//                       prefixIcon: const Icon(Icons.search),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey.shade100,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Main Content
//             Expanded(
//               child: RefreshIndicator(
//                 onRefresh: controller.loadProducts,
//                 child: controller.isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : controller.error != null
//                     ? CustomScrollView(
//                         physics: const AlwaysScrollableScrollPhysics(),
//                         slivers: [
//                           SliverFillRemaining(
//                             hasScrollBody: false,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(
//                                   Icons.error_outline,
//                                   color: Colors.red,
//                                   size: 48,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   controller.error!,
//                                   style: const TextStyle(color: Colors.red),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 ElevatedButton(
//                                   onPressed: controller.loadProducts,
//                                   child: const Text("إعادة المحاولة"),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       )
//                     : controller.products.isEmpty
//                     ? CustomScrollView(
//                         physics: const AlwaysScrollableScrollPhysics(),
//                         slivers: [
//                           SliverFillRemaining(
//                             hasScrollBody: false,
//                             child: Center(
//                               child: Text(
//                                 "لا توجد منتجات مطابقة",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )
//                     : ListView.builder(
//                         physics: const AlwaysScrollableScrollPhysics(),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 8,
//                         ),
//                         itemCount: controller.products.length,
//                         itemBuilder: (context, index) {
//                           final product = controller.products[index];
//
//                           return Card(
//                             margin: const EdgeInsets.only(bottom: 8),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               side: BorderSide(color: Colors.grey.shade200),
//                             ),
//                             child: ListTile(
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 12,
//                               ),
//                               leading: CircleAvatar(
//                                 backgroundColor:
//                                     theme.colorScheme.primaryContainer,
//                                 child: Icon(
//                                   Icons.inventory_2,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               title: Text(
//                                 product.name,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               // إظهار السعرين للمنتج
//                               subtitle: Padding(
//                                 padding: const EdgeInsets.only(top: 8.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       "السعر: ${product.priceSy.toStringAsFixed(2)} ل.س",
//                                       style: const TextStyle(
//                                         color: Colors.green,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       "السعر: ${product.priceDollar.toStringAsFixed(2)} \$",
//                                       style: const TextStyle(
//                                         color: Colors.blue,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   IconButton(
//                                     icon: const Icon(
//                                       Icons.edit_outlined,
//                                       color: Colors.blue,
//                                     ),
//                                     onPressed: () => _showAddEditDialog(
//                                       context,
//                                       product: product,
//                                     ),
//                                   ),
//                                   IconButton(
//                                     icon: const Icon(
//                                       Icons.delete_outline,
//                                       color: Colors.red,
//                                     ),
//                                     onPressed: () async {
//                                       final confirm = await _confirmDelete(
//                                         context,
//                                       );
//                                       if (confirm && context.mounted) {
//                                         final success = await context
//                                             .read<ProductsController>()
//                                             .deleteProduct(product.unified);
//                                         if (success && context.mounted) {
//                                           ScaffoldMessenger.of(
//                                             context,
//                                           ).showSnackBar(
//                                             const SnackBar(
//                                               content: Text(
//                                                 "تم حذف المنتج بنجاح",
//                                               ),
//                                               backgroundColor: Colors.green,
//                                             ),
//                                           );
//                                         }
//                                       }
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
