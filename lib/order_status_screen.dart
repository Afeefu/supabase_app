import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  List<Map<String, dynamic>> _orders = [];
  final Map<String, String> _productNames = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Fetch orders with items
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('id, created_at, total_amount, status, items')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      // 2. Collect all unique product IDs
      final productIds = <String>{};
      for (final order in ordersResponse) {
        final items = order['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final productId = item['product_id']?.toString();
          if (productId != null) {
            productIds.add(productId);
          }
        }
      }

      // 3. Fetch product names in batch
      if (productIds.isNotEmpty) {
        final productsResponse = await Supabase.instance.client
            .from('products')
            .select('id, name')
            .inFilter('id', productIds.toList());

        _productNames.addAll({
          for (var product in productsResponse)
            product['id'].toString():
                product['name']?.toString() ?? 'Unknown Product'
        });
      }

      setState(() {
        _orders = List<Map<String, dynamic>>.from(ordersResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _orders.isEmpty
                  ? Center(child: Text('No orders found'.tr))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fixed Row with constrained text
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Order #${order['id']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        order['status']
                                            .toString()
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color:
                                              _getStatusColor(order['status']),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor:
                                          _getStatusColor(order['status'])
                                              .withOpacity(0.2),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Placed on: ${DateTime.parse(order['created_at']).toLocal()}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Total: \$${order['total_amount'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (order['items'] is List)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Items:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      ...(order['items'] as List).map((item) {
                                        final productId =
                                            item['product_id']?.toString();
                                        final productName =
                                            _productNames[productId] ??
                                                'Product $productId';
                                        final productPrice =
                                            (item['products']?['price'] as num?)
                                                    ?.toDouble() ??
                                                0.0;

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Text(
                                            '• ${item['quantity']}x $productName - \$${productPrice.toStringAsFixed(2)}',
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
