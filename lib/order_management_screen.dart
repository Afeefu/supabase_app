import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final List<Map<String, dynamic>> _orders = [];
  final Map<String, String> _productNames = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final List<String> _statusOptions = [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      // Load orders with user emails
      final ordersResponse =
          await Supabase.instance.client.from('orders').select('''
      id, 
      created_at, 
      total_amount,
      status,
      delivery_name,
      delivery_phone,
      items,
      user_id (email)
    ''').order('created_at', ascending: false);

      // Extract all product IDs from all orders
      final productIds = <String>{};
      for (final order in ordersResponse) {
        final items = order['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final productId = item['product_id']?.toString();
          if (productId != null) productIds.add(productId);
        }
      }

      // Batch load product names
      if (productIds.isNotEmpty) {
        final productsResponse = await Supabase.instance.client
            .from('products')
            .select('id, name')
            .inFilter('id', productIds.toList());

        _productNames.clear();
        _productNames.addAll({
          for (var p in productsResponse)
            p['id'].toString(): p['name']?.toString() ?? 'Unknown Product'
        });
      }

      setState(() {
        _orders.clear();
        _orders.addAll(List<Map<String, dynamic>>.from(ordersResponse));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load orders: ${e.toString()}');
    }
  }

  Future<void> _updateOrderStatus(dynamic orderId, String newStatus) async {
    try {
      // Show loading indicator
      _showLoadingDialog();

      // Debug: Print the values being sent
      print(
          '🔄 Updating order $orderId (type: ${orderId.runtimeType}) to status: $newStatus');

      // Check if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      print('✅ User authenticated: ${user.id}');

      // Convert orderId to the correct type
      dynamic convertedOrderId;
      if (orderId is String) {
        // Try to parse as int first, then as UUID string
        final intId = int.tryParse(orderId);
        if (intId != null) {
          convertedOrderId = intId;
          print('🔄 Converted string ID to int: $convertedOrderId');
        } else {
          // Keep as string (for UUID)
          convertedOrderId = orderId;
          print('🔄 Keeping as string (UUID): $convertedOrderId');
        }
      } else {
        convertedOrderId = orderId;
        print(
            '🔄 Using original ID type: $convertedOrderId (${convertedOrderId.runtimeType})');
      }

      // Perform the update
      final response = await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', convertedOrderId)
          .select(); // Add select to get the updated row back

      print('✅ Update response: $response');
      print('✅ Response length: ${response.length}');

      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.isEmpty) {
        throw Exception(
            'No order found with ID: $orderId. The order may have been deleted or the ID format is incorrect.');
      }

      // Update local state
      setState(() {
        final index = _orders.indexWhere(
            (order) => order['id'].toString() == orderId.toString());
        if (index != -1) {
          _orders[index]['status'] = newStatus;
        }
      });

      _showSuccess('Order status updated successfully!');
    } on PostgrestException catch (e) {
      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      print('❌ PostgrestException: ${e.message}');
      print('❌ Details: ${e.details}');
      print('❌ Hint: ${e.hint}');
      print('❌ Code: ${e.code}');

      String errorMessage = 'Database error: ${e.message}';
      if (e.code == '42501') {
        errorMessage =
            'Permission denied. You may not have rights to update orders.';
      } else if (e.code == '23503') {
        errorMessage = 'Invalid order ID or foreign key constraint violation.';
      } else if (e.code == '22P02') {
        errorMessage = 'Invalid ID format. Please check the order ID type.';
      }

      _showError(errorMessage);
    } on AuthException catch (e) {
      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      print('❌ AuthException: ${e.message}');
      _showError('Authentication error: ${e.message}');
    } catch (e) {
      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      print('❌ General Exception: ${e.toString()}');
      print('❌ Exception type: ${e.runtimeType}');
      _showError('Failed to update order status: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Updating order status...'),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredOrders => _orders.where((order) {
        final email =
            order['user_id']?['email']?.toString().toLowerCase() ?? '';
        final orderId = order['id'].toString().toLowerCase();
        return email.contains(_searchQuery.toLowerCase()) ||
            orderId.contains(_searchQuery.toLowerCase());
      }).toList();

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
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
        title: Text('Order Management'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search orders'.tr,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? Center(child: Text('No orders found'.tr))
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildOrderHeader(order),
                                    const SizedBox(height: 12),
                                    _buildOrderItems(order),
                                    const SizedBox(height: 12),
                                    _buildStatusSelector(order),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(Map<String, dynamic> order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order['id']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                'Customer: ${order['user_id']?['email'] ?? 'Unknown'}',
                style: TextStyle(color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (order['delivery_name'] != null)
                Text(
                  'Recipient: ${order['delivery_name']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              if (order['delivery_phone'] != null)
                Text(
                  'Contact: ${order['delivery_phone']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Chip(
            label: Text(
              order['status'].toString().toUpperCase(),
              style: TextStyle(
                color: _statusColor(order['status']),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: _statusColor(order['status']).withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems(Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...(order['items'] as List<dynamic>).map((item) {
          final productId = item['product_id']?.toString();
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Text('${item['quantity']}x'),
            ),
            title: Text(
              _productNames[productId] ?? 'Unknown Product',
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              'Price: \$${item['products']?['price']?.toStringAsFixed(2) ?? '0.00'}',
            ),
          );
        }),
        const Divider(),
        Text(
          'Total: \$${order['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector(Map<String, dynamic> order) {
    return DropdownButtonFormField<String>(
      value: order['status'],
      decoration: const InputDecoration(
        labelText: 'Update Status',
        border: OutlineInputBorder(),
      ),
      items: _statusOptions
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status.toUpperCase()),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null && value != order['status']) {
          _updateOrderStatus(order['id'], value);
        }
      },
    );
  }
}
