import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';
import 'package:kasir_app/src/data/models/product_model.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddItem>(_onAddItem);
    on<RemoveItem>(_onRemoveItem);
    on<IncrementItemQuantity>(_onIncrementItemQuantity);
    on<DecrementItemQuantity>(_onDecrementItemQuantity);
    on<ClearCart>(_onClearCart);
    on<ReorderCartItems>(_onReorderCartItems); // Register the new event handler
  }

  void _onAddItem(AddItem event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final int index = updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (index != -1) {
      // Jika produk sudah ada, tambah jumlahnya
      final existingItem = updatedItems[index];
      updatedItems[index] = existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      // Jika produk belum ada, tambahkan ke keranjang dengan cost saat ini
      updatedItems.add(CartItem(product: event.product, quantity: 1, costAtSale: event.product.cost));
    }
    _updateState(emit, updatedItems);
  }

  void _onRemoveItem(RemoveItem event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items)..remove(event.item);
    _updateState(emit, updatedItems);
  }

  void _onIncrementItemQuantity(IncrementItemQuantity event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final int index = updatedItems.indexOf(event.item);
    if (index != -1) {
      final existingItem = updatedItems[index];
      updatedItems[index] = existingItem.copyWith(quantity: existingItem.quantity + 1);
      _updateState(emit, updatedItems);
    }
  }

  void _onDecrementItemQuantity(DecrementItemQuantity event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final int index = updatedItems.indexOf(event.item);
    if (index != -1) {
      final existingItem = updatedItems[index];
      if (existingItem.quantity > 1) {
        updatedItems[index] = existingItem.copyWith(quantity: existingItem.quantity - 1);
      } else {
        // Jika jumlahnya 1, hapus item dari keranjang
        updatedItems.removeAt(index);
      }
      _updateState(emit, updatedItems);
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    _updateState(emit, []);
  }

  void _onReorderCartItems(ReorderCartItems event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    
    // Adjust newIndex if it's moving to a lower index
    int newIndexAdjusted = event.newIndex; // Create a mutable copy

    // Adjust newIndex if it's moving to a lower index
    if (event.oldIndex < newIndexAdjusted) { // Use the mutable copy
      newIndexAdjusted -= 1; // Modify the mutable copy
    }

    final CartItem item = updatedItems.removeAt(event.oldIndex);
    updatedItems.insert(event.newIndex, item);

    _updateState(emit, updatedItems);
  }

  // Method helper untuk menghitung total dan emit state baru
  void _updateState(Emitter<CartState> emit, List<CartItem> items) {
    final double subtotal = items.fold(0, (sum, item) => sum + item.subtotal);
    
    final double total = subtotal;
    emit(CartState(items: items, subtotal: subtotal, total: total));
  }
}