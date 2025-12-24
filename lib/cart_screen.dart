import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_app/checkout_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Future<List<Map<String, dynamic>>> _cartItems = Future.value([]);
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || !mounted) return;

      final response = await _supabase.from('cart').select('''
            id, quantity, 
            products (id, name, price, images)
          ''').eq('user_id', user.id).order('updated_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _cartItems = Future.value(List<Map<String, dynamic>>.from(response));
      });
    } catch (e) {
      print('Error loading cart items: $e');
      if (mounted) {
        setState(() => _cartItems = Future.value([]));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shopping Cart'.tr)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading cart items'.tr));
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(child: Text('Your cart is empty'.tr));
          }

          final total = items.fold<double>(
            0,
            (sum, item) =>
                sum +
                (double.parse(item['products']['price'].toString()) *
                    item['quantity']),
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildCartItem(item, context);
                  },
                ),
              ),
              _buildTotalSection(context, total),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, BuildContext context) {
    final images = item['products']['images'] as List<dynamic>?;
    final price = double.tryParse(item['products']['price'].toString()) ?? 0.0;

    return ListTile(
      leading: images?.isNotEmpty == true
          ? Image.network(
              images!.first.toString(),
              width: 50,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported),
            )
          : const Icon(Icons.image_not_supported),
      title: Text(item['products']['name']?.toString().tr ?? 'Unknown Product'),
      subtitle: Text('\$${price.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => _updateQuantity(item, -1, context),
          ),
          Text(item['quantity'].toString()),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _updateQuantity(item, 1, context),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context, double total) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:'.tr, style: Theme.of(context).textTheme.titleLarge),
              Text('\$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              ),
              child: Text('Proceed to Checkout'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateQuantity(
      Map<String, dynamic> item, int delta, BuildContext context) async {
    try {
      final currentQuantity = (item['quantity'] as int?) ?? 0;
      final newQuantity = currentQuantity + delta;
      if (newQuantity < 1) return;

      await _supabase
          .from('cart')
          .update({'quantity': newQuantity}).eq('id', item['id']);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart updated')),
      );

      await _loadCartItems();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString()}')),
        );
      }
    }
  }
}
