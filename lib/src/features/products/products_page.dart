import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/data/repositories/product_repository.dart';
import 'package:kasir_app/src/features/products/bloc/product_bloc.dart';
import 'package:uuid/uuid.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc(
        getIt<ProductRepository>(),
      )..add(LoadProducts()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Produk'),
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).go('/'),
          ),
        ),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductLoaded) {
              if (state.products.isEmpty) {
                return const Center(
                  child: Text('Belum ada produk. Tekan + untuk menambah.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: state.products.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  print('Product: ${product.name}, Image URL: ${product.imageUrl != null ? 'Present' : 'Null'}');
                  if (product.imageUrl != null) {
                    print('Image URL length: ${product.imageUrl!.length}');
                    // Optionally, print a snippet of the base64 string if it's not too long
                    // print('Image URL snippet: ${product.imageUrl!.substring(0, product.imageUrl!.length > 50 ? 50 : product.imageUrl!.length)}...');
                  }
                  return ListTile(
                    leading: product.imageUrl != null
                        ? CircleAvatar(
                            backgroundImage: MemoryImage(base64Decode(product.imageUrl!)),
                            backgroundColor: Colors.grey[200],
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.inventory_2_outlined, color: Colors.indigo),
                          ),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(product.price)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return BlocProvider.value(
                                value: BlocProvider.of<ProductBloc>(context),
                                child: AddEditProductDialog(product: product),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _showDeleteConfirmation(context, product.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            if (state is ProductError) {
              return Center(child: Text('Terjadi Kesalahan: ${state.message}'));
            }
            return const Center(child: Text('State tidak diketahui.'));
          },
        ),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton(
            onPressed: () => showDialog(
              context: context,
              builder: (dialogContext) {
                return BlocProvider.value(
                  value: BlocProvider.of<ProductBloc>(context),
                  child: const AddEditProductDialog(),
                );
              },
            ),
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.add, color: Colors.white),
          );
        }),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Produk'),
          content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                if (dialogContext.mounted) { // Add this check
                  Navigator.of(dialogContext).pop(); // Close the dialog
                }
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                context.read<ProductBloc>().add(DeleteProduct(productId));
                if (dialogContext.mounted) { // Add this check
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class AddEditProductDialog extends StatefulWidget {
  final Product? product;

  const AddEditProductDialog({super.key, this.product});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController(); // New controller for cost
  
  File? _pickedImageFile; // Use File for picked image
  String? _existingImageUrl; // To store existing image URL from product
  final ImagePicker _picker = ImagePicker();

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _existingImageUrl = widget.product!.imageUrl; // Store existing image URL
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final originalBytes = await pickedFile.readAsBytes();

      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: 800,
        minHeight: 600,
        quality: 80,
      );

      if (compressedBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(compressedBytes);

        setState(() {
          _pickedImageFile = tempFile;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Ubah Produk' : 'Tambah Produk'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _pickedImageFile != null
                      ? FileImage(_pickedImageFile!)
                      : (_existingImageUrl != null
                          ? MemoryImage(base64Decode(_existingImageUrl!))
                          : null), // Show existing image or picked image
                  child: _pickedImageFile == null && _existingImageUrl == null
                      ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[800])
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Harga Jual'), // Changed label
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Harga jual tidak boleh kosong' : null,
              ),
              
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Batal'),
          onPressed: () {
            if (context.mounted) { // Add this check
              if (context.mounted) { // Add this check
                Navigator.of(context).pop();
              }
            }
          },
        ),
        ElevatedButton(
          child: const Text('Simpan'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              String? imageUrlBase64;
              if (_pickedImageFile != null) {
                imageUrlBase64 = base64Encode(_pickedImageFile!.readAsBytesSync());
              } else if (isEditing && _existingImageUrl != null) {
                imageUrlBase64 = _existingImageUrl; // Keep existing image if not changed
              }

              final newProduct = Product(
                id: isEditing ? widget.product!.id : const Uuid().v4(),
                name: _nameController.text,
                price: double.parse(_priceController.text),
                cost: isEditing ? widget.product!.cost : 0.0, // Default to 0.0 for new products
                
                imageUrl: imageUrlBase64,
              );

              if (isEditing) {
                context.read<ProductBloc>().add(UpdateProduct(newProduct));
              } else {
                context.read<ProductBloc>().add(AddProduct(newProduct));
              }
              if (context.mounted) { // Add this check
                Navigator.of(context).pop();
              }
            }
          },
        ),
      ],
    );
  }
}