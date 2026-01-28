
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/printing_service.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';
import 'package:kasir_app/src/features/products/bloc/product_bloc.dart';
import 'package:kasir_app/src/features/products/bloc/product_event.dart';
import 'package:kasir_app/src/features/products/bloc/product_state.dart';
import 'package:kasir_app/src/features/transaction/bloc/cart_bloc.dart';
import 'package:kasir_app/src/features/transaction/bloc/transaction_bloc.dart';
import 'dart:async';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  BuildContext? _loadingDialogContext;
  final PrintingService _printingService = getIt<PrintingService>();

  @override
  void initState() {
    super.initState();
    _printingService.state.addListener(_onPrinterStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPrinterStateChanged()); // Initial check
  }

  @override
  void dispose() {
    _printingService.state.removeListener(_onPrinterStateChanged);
    super.dispose();
  }

  void _onPrinterStateChanged() {
    if (!mounted) return;
    final printerState = _printingService.state.value;
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar(); // Hide any previous snackbar

    if (printerState.status == PrinterStatus.disconnected || printerState.status == PrinterStatus.error) {
      String message = printerState.errorMessage ?? 'Printer tidak terhubung.';
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (printerState.status == PrinterStatus.connected) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Printer terhubung.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
    // No explicit notification for 'connecting' as it's typically transient
  }

  Future<void> _handleTransactionSuccess(BuildContext context, TransactionModel transaction) async {
    if (_loadingDialogContext != null && _loadingDialogContext!.mounted) {
      Navigator.pop(_loadingDialogContext!); // Close loading dialog
      _loadingDialogContext = null; // Clear the context
    }

    // 2. Tampilkan dialog untuk cetak struk
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Transaksi Berhasil'),
          content: const Text('Apakah Anda ingin mencetak struk?'),
          actions: [
            TextButton(
              onPressed: () {
                if (dialogContext.mounted) { // Add this check
                  Navigator.pop(dialogContext);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi Berhasil!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context); // Get messenger here
                if (dialogContext.mounted) { // Add this check
                  Navigator.pop(dialogContext);
                }
                try {
                  await getIt<PrintingService>().printReceipt(transaction);
                  if (!context.mounted) return; // Add this check
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Struk dikirim ke printer.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  if (!context.mounted) return; // Add this check
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal mencetak: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Ya, Cetak'),
            ),
          ],
        );
      },
    );

    // 3. Kosongkan keranjang dan muat ulang produk
    context.read<CartBloc>().add(ClearCart());
    context.read<ProductBloc>().add(LoadProducts());
    return; // Explicitly return Future<void>
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CartBloc(),
        ),
        BlocProvider(
          create: (context) => TransactionBloc(
            getIt<TransactionRepository>(),
          ),
        ),
      ],
      child: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionInProgress) {
            debugPrint('TransactionInProgress state received');
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                _loadingDialogContext = dialogContext; // Capture the dialog context
                return const Center(child: CircularProgressIndicator());
              },
            );
          }
          if (state is TransactionSuccess) {
            debugPrint('TransactionSuccess state received');
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _handleTransactionSuccess(context, state.transaction);
            });
          }
          if (state is TransactionFailure) {
            debugPrint('TransactionFailure state received: ${state.error}');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_loadingDialogContext != null && _loadingDialogContext!.mounted) {
                Navigator.pop(_loadingDialogContext!); // Close loading dialog using captured context
                _loadingDialogContext = null; // Clear the context
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Transaksi Gagal: ${state.error}'), backgroundColor: Colors.red),
              );
            });
          }
        },
        child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F7),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withAlpha(26),

              actions: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthenticationAuthenticated && state.user.role == UserRole.admin) {
                            return Row(
                              children: [
                                // Commented out the printer settings button:
                                // IconButton(
                                //   icon: const Icon(Icons.print_outlined, color: Colors.black),
                                //   tooltip: 'Pengaturan Printer',
                                //   onPressed: () => context.go('/settings/printer'),
                                // ),
                                IconButton(
                                  icon: const Icon(Icons.group, color: Colors.black),
                                  tooltip: 'Manajemen Pengguna',
                                  onPressed: () => context.go('/users'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.bar_chart, color: Colors.black),
                                  tooltip: 'Laporan Penjualan',
                                  onPressed: () => context.go('/reports'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.inventory, color: Colors.black),
                                  tooltip: 'Manajemen Produk',
                                  onPressed: () => context.go('/products'),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthenticationAuthenticated) {
                            return IconButton(
                              icon: const Icon(Icons.logout, color: Colors.black),
                              tooltip: 'Logout',
                              onPressed: () {
                                context.read<AuthBloc>().add(LoggedOut());
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) { // Mobile view
                  return Column(
                    children: [
                      Expanded(
                        flex: 2, // Give more space to products
                        child: ProductGrid(),
                      ),
                      Expanded(
                        flex: 1, // Give less space to cart, but still dynamic
                        child: CartPanel(),
                      )
                    ],
                  );
                }
                // Desktop/Tablet view
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ProductGrid(),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFE0E0E0)),
                    Expanded(
                      flex: 1,
                      child: CartPanel(),
                    ),
                  ],
                );
              },
            ),
        ),
      ),
    );
  }
}

class ProductGrid extends StatefulWidget {
  const ProductGrid({super.key});

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> with SingleTickerProviderStateMixin { // Add SingleTickerProviderStateMixin
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  bool _isReordering = false; // New state to track reorder mode
  late AnimationController _animationController; // For the wiggle effect

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    context.read<ProductBloc>().add(const LoadProducts()); // Initial load of products
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            onChanged: (query) {
              _debouncer.run(() {
                // Update the search query locally and trigger a rebuild
                setState(() {
                  // No need to dispatch LoadProducts with query anymore, just update local state
                });
              });
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              if (state is ProductLoading || state is ProductInitial) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ProductLoaded) {
                final String currentSearchQuery = _searchController.text.toLowerCase();
                final List<Product> displayedProducts = state.products.where((product) {
                  return product.name.toLowerCase().contains(currentSearchQuery);
                }).toList();

                if (displayedProducts.isEmpty) {
                  return const Center(child: Text('Tidak ada produk ditemukan.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Changed from 3 to 4
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.7, // Changed from 0.8 to 0.7
                  ),
                  itemCount: displayedProducts.length,
                  itemBuilder: (context, index) {
                    final product = displayedProducts[index];
                    return ProductCard(product: product);
                  },
                );
              } else if (state is ProductError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              return const Center(child: Text('State tidak diketahui.'));
            },
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<CartBloc>().add(AddItem(product));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: () {
                  if (product.imageUrl == null || product.imageUrl!.isEmpty) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
                    );
                  }

                  // Check if the string starts with a common base64 image header
                  // A typical JPEG base64 string starts with "/9j/"
                  // A typical PNG base64 string starts with "iVBORw0KGgo"
                  // A typical GIF base64 string starts with "R0lGOD"
                  // For simplicity, let's just check for the common JPEG header as seen in the logs.
                  // A more robust solution might involve trying to parse it as URI first.
                  if (product.imageUrl!.startsWith('/9j/')) {
                    try {
                      final imageData = base64Decode(product.imageUrl!);
                      return Image.memory(
                        imageData,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image, size: 40)),
                      );
                    } catch (e) {
                      debugPrint('Error decoding base64 image: $e');
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, size: 40)),
                      );
                    }
                  } else if (product.imageUrl!.startsWith('http://') || product.imageUrl!.startsWith('https://')) {
                    return Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image, size: 40)),
                    );
                  } else {
                    // Fallback for unrecognized image format
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
                    );
                  }
                }(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(product.price),
                    style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartPanel extends StatefulWidget {
  const CartPanel({super.key}); // Add constructor

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final TextEditingController _amountPaidController = TextEditingController();
  double _change = 0.0; // State to hold the calculated change

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Keranjang',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (cartState.items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => context.read<CartBloc>().add(ClearCart()),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                  label: const Text('Kosongkan'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure content stretches horizontally
                children: [
                  cartState.items.isEmpty
                      ? const Center(child: Text('Keranjang kosong.'))
                      : ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(), // Handled by parent SingleChildScrollView
                          itemCount: cartState.items.length,
                          itemBuilder: (context, index) {
                            final item = cartState.items[index];
                            return CartItemTile(
                              key: ValueKey(item.product.id),
                              item: item,
                            );
                          },
                          onReorder: (oldIndex, newIndex) {
                            context.read<CartBloc>().add(ReorderCartItems(oldIndex, newIndex));
                          },
                        ),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  CartTotalRow(label: 'Subtotal', amount: cartState.subtotal),
                  const SizedBox(height: 8),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(cartState.total),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _amountPaidController,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Bayar',
                      hintText: 'Masukkan jumlah pembayaran',
                      prefixIcon: const Icon(Icons.payments_outlined, color: Colors.indigo),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.indigo, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                      final parsedAmount = double.tryParse(cleanValue) ?? 0.0;

                      setState(() {
                        _change = parsedAmount - cartState.total;
                      });

                      if (parsedAmount > 0) {
                        final formattedText = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(parsedAmount);
                        if (_amountPaidController.text != formattedText) {
                          _amountPaidController.value = TextEditingValue(
                            text: formattedText,
                            selection: TextSelection.collapsed(offset: formattedText.length),
                          );
                        }
                      } else {
                        if (_amountPaidController.text.isNotEmpty) {
                          _amountPaidController.value = TextEditingValue(
                            text: '',
                            selection: TextSelection.collapsed(offset: 0),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kembalian',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(_change),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: cartState.items.isEmpty || _amountPaidController.text.isEmpty || _change < 0
                ? null
                : () {
                    final cleanText = _amountPaidController.text.replaceAll(RegExp(r'[^\d]'), '');
                    final parsedAmountForConfirmation = double.tryParse(cleanText) ?? 0.0;
                    _showPaymentConfirmation(context, cartState, parsedAmountForConfirmation);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('PROSES PEMBAYARAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmation(BuildContext context, CartState cartState, double amountPaid) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Belanja: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(cartState.total)}'),
              Text('Jumlah Bayar: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amountPaid)}'),
              Text('Kembalian: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(_change)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<TransactionBloc>().add(
                      ProcessTransaction(
                        cartItems: cartState.items,
                        totalAmount: cartState.total,
                        amountPaid: amountPaid,
                        change: _change,
                        cashierId: context.read<AuthBloc>().state is AuthenticationAuthenticated
                            ? (context.read<AuthBloc>().state as AuthenticationAuthenticated).user.id
                            : '',
                      ),
                    );
                _amountPaidController.clear(); // Clear the text field
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }
}

class CartItemTile extends StatelessWidget {
  final CartItem item;
  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.shopping_basket_outlined, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Rp ${item.product.price.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 24, color: Colors.redAccent),
                  onPressed: () {
                    context.read<CartBloc>().add(DecrementItemQuantity(item));
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 24, color: Colors.green),
                  onPressed: () {
                    context.read<CartBloc>().add(IncrementItemQuantity(item));
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CartTotalRow extends StatelessWidget {
  final String label;
  final double amount;
  const CartTotalRow({super.key, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        Text('Rp ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
      ],
    );
  }
}

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({this.milliseconds = 500});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
