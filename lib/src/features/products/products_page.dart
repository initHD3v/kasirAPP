import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kasir_app/src/data/models/product_model.dart';

import 'package:kasir_app/src/features/products/bloc/product_bloc.dart';
import 'package:kasir_app/src/features/products/bloc/product_event.dart';
import 'package:kasir_app/src/features/products/bloc/product_state.dart';
import 'package:uuid/uuid.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  double _fabTop = 0.0;
  double _fabLeft = 0.0;
  final double _fabSize = 56.0; // Default FAB size

  @override
  void initState() {
    super.initState();
    // Initialize with default values, will be updated after first frame
    _fabTop = 0.0;
    _fabLeft = 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Ensure the widget is still mounted before accessing context
        final Size screenSize = MediaQuery.of(context).size;
        setState(() {
          _fabTop = (screenSize.height / 2) - (_fabSize / 2); // Initial center vertical
          _fabLeft = (screenSize.width / 2) - (_fabSize / 2); // Initial center horizontal
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Produk'),
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).go('/'),
          ),
        ),
        body: Stack(
          children: [
            BlocBuilder<ProductBloc, ProductState>(
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
                  return ListView.builder( // Changed to ListView.builder as separator is removed
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: product.imageUrl != null
                                    ? Image.memory(
                                        base64Decode(product.imageUrl!),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.indigo),
                                      ),
                              ),
                              const SizedBox(width: 16.0),
                              // Product Details (Name, Price)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(product.price),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Action Buttons (Edit, Delete)
                              Column(
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
                                    icon: const Icon(Icons.delete_outlined, color: Colors.redAccent),
                                    onPressed: () => _showDeleteConfirmation(context, product.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
            Positioned(
              top: _fabTop, // Use _fabTop for positioning
              left: _fabLeft, // Use _fabLeft for positioning
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _fabTop += details.delta.dy;
                    _fabLeft += details.delta.dx;
                  });
                },
                onPanEnd: (details) {
                  // Ensure the button stays within screen bounds
                  final Size screenSize = MediaQuery.of(context).size;
                  setState(() {
                    _fabTop = _fabTop.clamp(0.0, screenSize.height - _fabSize - 16.0);
                    _fabLeft = _fabLeft.clamp(0.0, screenSize.width - _fabSize - 16.0);
                  });
                },
                child: FloatingActionButton(
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
                ),
              ),
            ),
          ],
        ),
        // floatingActionButton: Builder(builder: (context) { // Removed from here
        //   return FloatingActionButton(
        //     onPressed: () => showDialog(
        //       context: context,
        //       builder: (dialogContext) {
        //         return BlocProvider.value(
        //           value: BlocProvider.of<ProductBloc>(context),
        //           child: const AddEditProductDialog(),
        //         );
        //       },
        //     ),
        //     backgroundColor: Colors.indigo,
        //     child: const Icon(Icons.add, color: Colors.white),
        //   );
        // }),
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
  
  File? _pickedImageFile; // Use File for picked image
  String? _existingImageUrl; // To store existing image URL from product
  final ImagePicker _picker = ImagePicker();

  bool get isEditing => widget.product != null;

  final List<String> _defaultCategories = ['Makanan', 'Minuman', 'A la carte'];
  String? _selectedCategory; // Holds the selected category from the dropdown

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _existingImageUrl = widget.product!.imageUrl; // Store existing image URL
      _selectedCategory = widget.product!.category; // Set selected category from existing product
    } else {
      _selectedCategory = _defaultCategories.first; // Default to first category for new products
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
                  child: (_pickedImageFile == null && _existingImageUrl == null)
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
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori Produk'),
                items: _defaultCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Kategori tidak boleh kosong' : null,
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
                category: _selectedCategory, // Use selected category from dropdown
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