import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  late Future<Map<String, dynamic>> _orderDetails;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _orderDetails = _fetchOrderDetails();
  }

  Future<Map<String, dynamic>> _fetchOrderDetails() async {
    final response = await _supabase.from('orders').select('''
          id,
          total_amount,
          delivery_address,
          items,
          created_at
        ''').eq('id', widget.orderId).single();

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Confirmation'.tr),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _orderDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading order: ${snapshot.error}'));
          }

          final order = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Thank you for your order!'.tr,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text('Order ID: ${order['id']}',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 10),
                  Text('Order Date: ${_formatDate(order['created_at'])}'),
                  const SizedBox(height: 20),
                  const Divider(),
                  Text('Delivery Address:'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(order['delivery_address']),
                  const SizedBox(height: 20),
                  Text('Order Items:'.tr,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  // Fixed height container for the items list to prevent overflow
                  SizedBox(
                    height: 200, // Fixed height for the items list
                    child: ListView.builder(
                      itemCount: (order['items'] as List).length,
                      itemBuilder: (context, index) {
                        final item = order['items'][index];
                        return ListTile(
                          title: Text(item['product_id']),
                          trailing: Text('Qty: ${item['quantity']}'),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            'you will recive a message via WhatsApp or a phone call once the order is confirmed.'
                                .tr),
                      )
                    ],
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:'.tr,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('\$${order['total_amount'].toString()}',
                          style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                      child: Text('Continue Shopping'.tr),
                    ),
                  ),
                  const SizedBox(height: 16), // Extra padding at bottom
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
