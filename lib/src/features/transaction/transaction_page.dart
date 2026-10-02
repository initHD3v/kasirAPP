
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_app/src/core/service_locator.dart';
import 'package:kasir_app/src/core/services/printing_service.dart';
import 'package:kasir_app/src/core/services/qris_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kasir_app/src/data/models/product_model.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';
import 'package:kasir_app/src/data/models/transaction_model.dart';
import 'package:kasir_app/src/data/models/user_model.dart';
import 'package:kasir_app/src/data/repositories/transaction_repository.dart';
import 'package:kasir_app/src/data/repositories/product_repository.dart'; // New import
import 'package:kasir_app/src/features/auth/bloc/auth_bloc.dart';
import 'package:kasir_app/src/features/products/bloc/product_bloc.dart';
import 'package:kasir_app/src/features/products/bloc/product_event.dart';
import 'package:kasir_app/src/features/products/bloc/product_state.dart';
import 'package:kasir_app/src/features/transaction/bloc/cart_bloc.dart';
import 'package:kasir_app/src/features/transaction/bloc/transaction_bloc.dart';
import 'package:kasir_app/src/shared/widgets/printer_status_widget.dart'; // New import
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart'; // New import

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  BuildContext? _loadingDialogContext;
  final PrintingService _printingService = getIt<PrintingService>();
  final GlobalKey<ProductGridState> _mobileGridKey = GlobalKey<ProductGridState>();
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _printingService.state.addListener(_onPrinterStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPrinterStateChanged()); // Initial check
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
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
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Image.asset('assets/images/logo.png', width: 40, height: 40), // Your app logo
              const SizedBox(width: 10),
              const Text('Tentang MDKASIR'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'MDKASIR adalah solusi Point-of-Sale (POS) modern yang dirancang untuk membantu bisnis Anda mengelola transaksi dengan efisien dan mudah.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 10), // Added spacing
                const Text( // New line for updates
                  'Pembaruan Terbaru (v1.1.0): Pembayaran QRIS manual (Dana/GoPay), 30 produk bawaan, UI portrait HP baru, dan perbaikan stabilitas.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 15),
                Text(
                  'Versi Aplikasi: ${_packageInfo.version} (${_packageInfo.buildNumber})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Pengembang:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('Hidayat Fauzi'),
                const Text('Email: hidayatfauzi6@gmail.com'),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  '© 2026 MDKASIR - Developer Team',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Text(
                  'Semua hak cipta dilindungi.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTransactionSuccess(BuildContext context, TransactionModel transaction) async {
    if (_loadingDialogContext != null && _loadingDialogContext!.mounted) {
      Navigator.pop(_loadingDialogContext!); // Close loading dialog
      _loadingDialogContext = null; // Clear the context
    }

    // Kembali ke grid jika halaman pembayaran penuh sedang terbuka.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
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
                if (dialogContext.mounted) {
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
                final messenger = ScaffoldMessenger.of(context);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                try {
                  await getIt<PrintingService>().printReceipt(transaction);
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Struk dikirim ke printer.'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  if (!context.mounted) return;
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
    return;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionInProgress) {
          debugPrint('TransactionInProgress state received');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              _loadingDialogContext = dialogContext;
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
              Navigator.pop(_loadingDialogContext!);
              _loadingDialogContext = null;
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
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      tooltip: 'Cari produk',
                      onPressed: () =>
                          _mobileGridKey.currentState?.toggleSearch(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.black),
                      tooltip: 'Tentang Aplikasi',
                      onPressed: _showAboutDialog,
                    ),
                    const SizedBox(width: 8),
                    // Repositioned PrinterStatusWidget
                    const PrinterStatusWidget(),
                    const SizedBox(width: 8), // Spacing between printer status and logout
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
              if (constraints.maxWidth < 600) {
                // HP portrait: grid penuh + tombol Bayar; keranjang jadi halaman penuh.
                return Column(
                  children: [
                    Expanded(
                      child: ProductGrid(
                        key: _mobileGridKey,
                        showSearchIcon: false,
                      ),
                    ),
                    const _PayBar(),
                  ],
                );
              }
              // Desktop/Tablet view
              return const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ProductGrid(),
                  ),
                  VerticalDivider(width: 1, color: Color(0xFFE0E0E0)),
                  Expanded(
                    flex: 1,
                    child: CartPanel(),
                  ),
                ],
              );
            },
          ),
      ),
    );
  }
}

/// Bilah bawah HP portrait: ringkas. Keranjang kosong → hilang total agar
/// grid lega. Ada isi → 1 baris info + tombol Bayar.
class _PayBar extends StatelessWidget {
  const _PayBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isEmpty) return const SizedBox.shrink();
        final count = cartState.items.fold<int>(0, (sum, i) => sum + i.quantity);
        final totalText = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp',
          decimalDigits: 0,
        ).format(cartState.total);
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count item',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(totalText,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  },
                  icon: const Icon(Icons.shopping_basket_outlined, size: 18),
                  label: const Text('Bayar',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Halaman keranjang/pembayaran layar penuh (HP portrait).
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: Colors.white,
      ),
      body: const CartPanel(),
    );
  }
}

class ProductGrid extends StatefulWidget {
  const ProductGrid({super.key, this.showSearchIcon = true});

  /// Ikon search di dalam grid. Matikan jika toggle search sudah ada di AppBar.
  final bool showSearchIcon;

  @override
  State<ProductGrid> createState() => ProductGridState();
}

class ProductGridState extends State<ProductGrid> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  late TabController _tabController;
  List<String> _categories = [];
  String? _selectedCategory;
  late Future<void> _categoriesFuture; // New: Future to track category loading
  bool _searchOpen = false;

  bool _isReordering = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    // Initialize _categoriesFuture and handle TabController setup in its .then()
    _categoriesFuture = _loadCategories().then((_) {
      // Ensure the widget is still mounted before accessing context or setState
      if (!mounted) return;

      // Initialize _tabController here after categories are loaded
      _tabController = TabController(length: _categories.length, vsync: this);
      _tabController.addListener(_onTabChanged);

      // Trigger initial load of products after categories and TabController are ready
      _selectedCategory = _tabController.index == 0 ? null : _categories[_tabController.index];
      context.read<ProductBloc>().add(LoadProducts(
        query: _searchController.text,
        category: _selectedCategory,
      ));
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _tabController.index == 0 ? null : _categories[_tabController.index];
        context.read<ProductBloc>().add(LoadProducts(
          query: _searchController.text,
          category: _selectedCategory,
        ));
      });
    }
  }

  Future<void> _loadCategories() async {
    final productRepository = getIt<ProductRepository>();
    final fetchedCategories = await productRepository.getUniqueCategories();
    if (mounted) {
      setState(() {
        _categories = ['Semua Produk', ...fetchedCategories]; // Add "All Products" as the first option
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _tabController.removeListener(_onTabChanged); // Make sure listener is removed before dispose
    _tabController.dispose();
    super.dispose();
  }

  void closeSearch() {
    _searchController.clear();
    setState(() => _searchOpen = false);
    context.read<ProductBloc>().add(LoadProducts(
          query: '',
          category: _selectedCategory,
        ));
  }

  /// Dipanggil dari tombol search di AppBar.
  void toggleSearch() {
    if (_searchOpen) {
      closeSearch();
    } else {
      setState(() => _searchOpen = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_searchOpen)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: closeSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (query) {
                _debouncer.run(() {
                  context.read<ProductBloc>().add(LoadProducts(
                        query: query,
                        category: _selectedCategory, // Pass selected category
                      ));
                });
              },
            ),
          )
        else if (widget.showSearchIcon)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Cari produk',
              onPressed: () => setState(() => _searchOpen = true),
            ),
          ),
        // Wrap TabBar and product grid in a FutureBuilder
        FutureBuilder<void>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading categories: ${snapshot.error}'));
            } else {
              // Once categories are loaded, render the TabBar and products
              return Expanded( // Wrap the rest of the content in Expanded
                child: Column(
                  children: [
                    PreferredSize(
                      preferredSize: const Size.fromHeight(kToolbarHeight),
                      child: AppBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        flexibleSpace: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              labelColor: Colors.indigo,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.indigo,
                              tabs: _categories.map((category) => Tab(text: category)).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<ProductBloc, ProductState>(
                        builder: (context, state) {
                          if (state is ProductLoading || state is ProductInitial) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (state is ProductLoaded) {
                            final List<Product> displayedProducts = state.products;

                            if (displayedProducts.isEmpty) {
                              return const Center(child: Text('Tidak ada produk ditemukan.'));
                            }
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                // Responsif: target lebar kartu ~170dp, min 2 kolom (HP portrait),
                                // lebih banyak di tablet/desktop.
                                final columns =
                                    (constraints.maxWidth / 170).floor().clamp(2, 6);
                                return GridView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 8.0,
                                    mainAxisSpacing: 8.0,
                                    childAspectRatio: 0.7,
                                  ),
                                  itemCount: displayedProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = displayedProducts[index];
                                    return ProductCard(product: product);
                                  },
                                );
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
                ),
              );
            }
          },
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

                  // URL jaringan langsung ditampilkan; selain itu coba sebagai
                  // base64 (JPEG "/9j/", PNG "iVBOR...", GIF "R0lGOD", dsb).
                  if (product.imageUrl!.startsWith('http://') || product.imageUrl!.startsWith('https://')) {
                    return Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image, size: 40)),
                    );
                  }
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
  String _paymentMethod = 'Tunai';
  double? _lastAutofillTotal; // Total terakhir yang diisi otomatis
  String _lastFieldText = '';

  @override
  void initState() {
    super.initState();
    // Sinkronkan _change + rebuild tombol untuk SEMUA perubahan field,
    // termasuk autofill programmatic (onChanged TextField tidak dijamin
    // terpanggil untuk perubahan programmatic).
    _amountPaidController.addListener(_syncChangeWithField);
  }

  void _syncChangeWithField() {
    if (!mounted) return;
    final text = _amountPaidController.text;
    final total = context.read<CartBloc>().state.total;
    final parsed = double.tryParse(text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
    final newChange = parsed - total;
    // Rebuild juga saat teks berubah walau nominal kembalian sama,
    // agar tombol PROSES PEMBAYARAN aktif tepat setelah autofill.
    if (newChange != _change || text != _lastFieldText) {
      _lastFieldText = text;
      setState(() => _change = newChange);
    }
  }

  @override
  void dispose() {
    _amountPaidController.removeListener(_syncChangeWithField);
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;

    // Autofill Jumlah Bayar = total. Hanya timpa jika field kosong atau masih
    // bernilai hasil autofill sebelumnya (user belum mengubah manual).
    if (cartState.items.isEmpty) {
      _change = 0;
      _lastAutofillTotal = null;
    } else {
      final currentParsed = double.tryParse(
            _amountPaidController.text.replaceAll(RegExp(r'[^\d]'), ''),
          ) ??
          0.0;
      final untouched = _amountPaidController.text.isEmpty ||
          currentParsed == (_lastAutofillTotal ?? currentParsed);
      if (untouched && _lastAutofillTotal != cartState.total) {
        _lastAutofillTotal = cartState.total;
        final total = cartState.total;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final formatted = NumberFormat.currency(
            locale: 'id_ID',
            symbol: '',
            decimalDigits: 0,
          ).format(total);
          _amountPaidController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        });
      } else if (!untouched) {
        _change = currentParsed - cartState.total;
      }
    }

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
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Tunai', label: Text('Tunai'), icon: Icon(Icons.payments_outlined)),
                      ButtonSegment(value: 'QRIS', label: Text('QRIS'), icon: Icon(Icons.qr_code)),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (selection) {
                      setState(() => _paymentMethod = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_paymentMethod == 'Tunai') ...[
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
                  ], // end Tunai section
                  if (_paymentMethod == 'QRIS') ...[
                    const Text(
                      'Pembayaran via QRIS (Dana/GoPay). QR dibuat dengan nominal otomatis — konfirmasi manual setelah cek aplikasi Dana/GoPay.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
          if (_paymentMethod == 'Tunai')
            Builder(
              builder: (buttonContext) {
                final paidNow = double.tryParse(
                      _amountPaidController.text.replaceAll(RegExp(r'[^\d]'), ''),
                    ) ??
                    0.0;
                final canPay = cartState.items.isNotEmpty &&
                    _amountPaidController.text.isNotEmpty &&
                    paidNow >= cartState.total;
                return ElevatedButton(
                  onPressed: canPay
                      ? () {
                          _showPaymentConfirmation(
                              context, cartState, paidNow);
                        }
                      : null,
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
                );
              },
            ),
          if (_paymentMethod == 'QRIS')
            ElevatedButton(
              onPressed: cartState.items.isEmpty
                  ? null
                  : () => _showQrisDialog(context, cartState),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('TAMPILKAN QRIS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showQrisDialog(BuildContext context, CartState cartState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _QrisPaymentDialog(
        total: cartState.total,
        onConfirmed: (paymentLabel) {
          Navigator.pop(dialogContext);
          context.read<TransactionBloc>().add(
                ProcessTransaction(
                  cartItems: cartState.items,
                  totalAmount: cartState.total,
                  amountPaid: cartState.total,
                  change: 0,
                  cashierId: context.read<AuthBloc>().state is AuthenticationAuthenticated
                      ? (context.read<AuthBloc>().state as AuthenticationAuthenticated).user.id
                      : '',
                  paymentMethod: paymentLabel,
                ),
              );
          _amountPaidController.clear();
        },
      ),
    );
  }
}

class _QrisPaymentDialog extends StatefulWidget {
  final double total;
  final void Function(String paymentLabel) onConfirmed;

  const _QrisPaymentDialog({required this.total, required this.onConfirmed});

  @override
  State<_QrisPaymentDialog> createState() => _QrisPaymentDialogState();
}

class _QrisPaymentDialogState extends State<_QrisPaymentDialog> {
  final _qris = QrisService();
  bool _loading = true;
  String? _danaStatic;
  String? _gopayStatic;
  String _wallet = 'Dana';
  String? _dynamicPayload;
  String? _error;
  late DateTime _expiry;
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _expiry = DateTime.now().add(const Duration(minutes: 5));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _expiry.difference(DateTime.now());
      if (left.isNegative) {
        _timer?.cancel();
        if (mounted) Navigator.pop(context);
        return;
      }
      setState(() => _remaining = left);
    });
    _load();
  }

  Future<void> _load() async {
    final dana = await _qris.getStaticQrDana();
    final gopay = await _qris.getStaticQrGopay();
    if (!mounted) return;
    setState(() {
      _danaStatic = dana;
      _gopayStatic = gopay;
      if (dana == null && gopay != null) _wallet = 'GoPay';
      _loading = false;
    });
    _rebuild();
  }

  void _rebuild() {
    final statis = _wallet == 'Dana' ? _danaStatic : _gopayStatic;
    if (statis == null) {
      setState(() {
        _dynamicPayload = null;
        _error = 'QRIS $_wallet belum diatur. Atur di Pengaturan → QRIS.';
      });
      return;
    }
    try {
      setState(() {
        _dynamicPayload = _qris.toDynamic(statis, widget.total);
        _error = null;
      });
    } on FormatException {
      setState(() {
        _dynamicPayload = null;
        _error = 'Payload QRIS $_wallet tidak valid. Periksa Pengaturan → QRIS.';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountText = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(widget.total);
    final mm = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return AlertDialog(
      title: const Text('Bayar via QRIS'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              )
            else ...[
              if (_danaStatic != null && _gopayStatic != null)
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Dana', label: Text('Dana')),
                    ButtonSegment(value: 'GoPay', label: Text('GoPay')),
                  ],
                  selected: {_wallet},
                  onSelectionChanged: (s) {
                    setState(() => _wallet = s.first);
                    _rebuild();
                  },
                ),
              const SizedBox(height: 12),
              Text(amountText,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text('Berlaku $mm:$ss', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              if (_dynamicPayload != null)
                QrImageView(data: _dynamicPayload!, size: 220)
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              const Text(
                'Customer scan QR ini dengan nominal otomatis. Setelah cek pembayaran masuk di aplikasi Dana/GoPay, tap tombol di bawah.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _dynamicPayload == null
              ? null
              : () => widget.onConfirmed('QRIS $_wallet'),
          child: const Text('Sudah Dibayar'),
        ),
      ],
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
            Expanded(
              child: Row(
                children: [
                  Flexible( // Quantity controls and text are flexible
                    flex: 2, // Give it some flexibility
                    child: Row(
                      // Removed mainAxisSize.min to allow children to expand within Flexible
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<CartBloc>().add(DecrementItemQuantity(item));
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(Icons.remove_circle_outline, size: 24, color: Colors.redAccent),
                          ),
                        ),
                        Expanded( // Quantity text can expand within this flexible block
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            context.read<CartBloc>().add(IncrementItemQuantity(item));
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(Icons.add_circle_outline, size: 24, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8), // Spacer
                  Expanded( // Subtotal takes remaining space
                    flex: 1, // Give more flex to subtotal as it can be wider
                    child: Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
