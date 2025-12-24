import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> cartItems = [];
  double totalAmount = 0.0;

  // Payment method selection
  String _selectedPaymentMethod = 'cash_on_delivery';

  final List<Map<String, String>> _paymentMethods = [
    {
      'id': 'cash_on_delivery',
      'title': 'Cash on Delivery',
      'subtitle': 'Pay when you receive your order',
      'icon': '💵',
      'description': 'Safe and convenient - pay only when your order arrives'
    },
    {
      'id': 'online_payment',
      'title': 'Online Payment',
      'subtitle': 'Pay now with credit/debit card',
      'icon': '💳',
      'description': 'Secure online payment via Stripe'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartItems();
  }

  Future<void> _loadProducts() async {
    try {
      final response =
          await Supabase.instance.client.from('products').select('id, price');
      setState(() => products = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadCartItems() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Updated query without the non-existent category column
      final cartResponse =
          await Supabase.instance.client.from('cart').select('''
        product_id, 
        quantity,
        products (price, name, category_id)
      ''').eq('user_id', user.id);

      setState(() {
        cartItems = List<Map<String, dynamic>>.from(cartResponse);
        totalAmount = _calculateTotal(cartItems);
      });
    } catch (e) {
      print('Error loading cart items: $e');

      // Fallback: try without category_id if it also doesn't exist
      try {
        final user = Supabase.instance.client.auth.currentUser;
        final fallbackResponse =
            await Supabase.instance.client.from('cart').select('''
          product_id, 
          quantity,
          products (price, name)
        ''').eq('user_id', user!.id);

        setState(() {
          cartItems = List<Map<String, dynamic>>.from(fallbackResponse);
          totalAmount = _calculateTotal(cartItems);
        });
      } catch (fallbackError) {
        print('Fallback error loading cart items: $fallbackError');
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading cart items. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout'.tr)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                _buildOrderSummaryCard(),

                const SizedBox(height: 24),

                // Delivery Information Section
                Text(
                  'Delivery Information'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                _buildDeliveryForm(),

                const SizedBox(height: 24),

                // Payment Method Section
                Text(
                  'Payment Method'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                _buildPaymentMethodSelection(),

                // Payment Info Card
                if (_selectedPaymentMethod == 'online_payment')
                  _buildPaymentInfoCard(),

                const SizedBox(height: 32),

                // Place Order Button
                _buildPlaceOrderButton(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Order Summary'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cartItems.isEmpty) ...[
              Text('Loading cart items...'.tr),
            ] else ...[
              ...cartItems.map((item) {
                final productName =
                    item['products']?['name'] ?? 'Unknown Product';
                final price =
                    (item['products']?['price'] as num?)?.toDouble() ?? 0.0;
                final quantity = item['quantity'] as int;
                final itemTotal = price * quantity;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('$productName x$quantity'),
                      ),
                      Text('\$${itemTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryForm() {
    return Column(
      children: [
        // Name Field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name'.tr,
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Phone Field
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number'.tr,
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number'.tr;
            }
            if (!RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$')
                .hasMatch(value)) {
              return 'Enter a valid phone number'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Address Field
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Street Address'.tr,
            hintText: 'Building number, street name'.tr,
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // City and State Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City'.tr,
                  hintText: 'Sanaa, Ibb, etc.'.tr,
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city'.tr;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State/Province'.tr,
                  hintText: 'Optional'.tr,
                  prefixIcon: const Icon(Icons.map),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // State is optional for Yemen
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Postal Code Field
        TextFormField(
          controller: _postalCodeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Postal Code'.tr,
            hintText: 'Optional'.tr,
            prefixIcon: const Icon(Icons.local_post_office),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Postal code is optional for Yemen
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      children: _paymentMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method['id'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 3 : 1,
          color: isSelected ? Colors.blue.shade50 : null,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPaymentMethod = method['id']!;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Radio<String>(
                    value: method['id']!,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    method['icon']!,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['title']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? Colors.blue.shade700 : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method['subtitle']!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method['description']!,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Colors.blue.shade700,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Secure payment processing via Stripe',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
            ),
            Text(
              '• Accepts Visa, Mastercard, American Express, and more',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
            ),
            Text(
              '• Your payment information is encrypted and secure',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
            ),
            Text(
              '• Amount: \$${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    String buttonText;
    Color buttonColor;
    IconData buttonIcon;

    if (_selectedPaymentMethod == 'cash_on_delivery') {
      buttonText = _isSubmitting
          ? 'Placing Order...'
          : 'Place Order (Cash on Delivery)'.tr;
      buttonColor = Colors.green;
      buttonIcon = Icons.check_circle;
    } else {
      buttonText = _isSubmitting
          ? 'Processing Payment...'
          : 'Pay Now (\$${totalAmount.toStringAsFixed(2)})'.tr;
      buttonColor = Colors.blue;
      buttonIcon = Icons.payment;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitOrder,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(buttonIcon),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create full address string for storage
      final fullAddress = _buildFullAddress();

      // Create the order first
      final orderResponse =
          await Supabase.instance.client.from('orders').insert({
        'user_id': user.id,
        'items': cartItems,
        'total_amount': totalAmount,
        'payment_method':
            _selectedPaymentMethod == 'cash_on_delivery' ? 'cash' : 'card',
        'payment_status': _selectedPaymentMethod == 'cash_on_delivery'
            ? 'pending'
            : 'processing',
        'delivery_name': _nameController.text,
        'delivery_phone': _phoneController.text,
        'delivery_address': fullAddress,
        'delivery_city': _cityController.text,
        'delivery_state': _stateController.text,
        'delivery_postal_code': _postalCodeController.text,
        'status': 'pending'
      }).select();

      final orderId = orderResponse.first['id'];

      // Handle different payment methods
      if (_selectedPaymentMethod == 'cash_on_delivery') {
        // Clear cart and navigate for cash on delivery
        await _clearCartAndNavigate(orderId);
      } else {
        // Process online payment
        await _processOnlinePayment(orderId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _buildFullAddress() {
    final parts = <String>[];

    if (_addressController.text.isNotEmpty) {
      parts.add(_addressController.text);
    }
    if (_cityController.text.isNotEmpty) {
      parts.add(_cityController.text);
    }
    if (_stateController.text.isNotEmpty) {
      parts.add(_stateController.text);
    }
    if (_postalCodeController.text.isNotEmpty) {
      parts.add(_postalCodeController.text);
    }

    return parts.join(', ');
  }

  Future<void> _clearCartAndNavigate(String orderId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Clear the cart
        await Supabase.instance.client
            .from('cart')
            .delete()
            .eq('user_id', user.id);
      }

      if (!mounted) return;

      // Navigate to confirmation screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(orderId: orderId),
        ),
      );
    } catch (e) {
      print('Error clearing cart: $e');
      // Still navigate even if cart clearing fails
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(orderId: orderId),
          ),
        );
      }
    }
  }

  Future<void> _processOnlinePayment(String orderId) async {
    try {
      print('🚀 Starting online payment process for order: $orderId');

      // Show loading dialog
      _showLoadingDialog('Creating payment...');

      // Create payment intent via Edge Function
      final paymentIntentResponse =
          await Supabase.instance.client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': (totalAmount * 100).round(), // Convert to cents
          'currency': 'usd',
          'order_id': orderId,
          'customer_info': {
            'name': _nameController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'postal_code': _postalCodeController.text,
          },
        },
      );

      print(
          '💳 Payment intent response status: ${paymentIntentResponse.status}');

      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      if (paymentIntentResponse.status != 200) {
        throw Exception(
            'Failed to create payment intent: ${paymentIntentResponse.data}');
      }

      final paymentIntentData = paymentIntentResponse.data;
      final clientSecret = paymentIntentData['client_secret'];
      final paymentIntentId = paymentIntentData['id'];

      print('✅ Payment intent created: $paymentIntentId');

      // Update order with payment intent ID
      await Supabase.instance.client
          .from('orders')
          .update({'payment_intent_id': paymentIntentId}).eq('id', orderId);

      print('📝 Order updated with payment intent ID');

      // Initialize payment sheet with complete address
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your Store Name',
          style: ThemeMode.system,
          billingDetails: stripe.BillingDetails(
            name: _nameController.text,
            phone: _phoneController.text,
            address: stripe.Address(
              line1: _addressController.text.isNotEmpty
                  ? _addressController.text
                  : 'N/A', // Required field
              line2: null, // Optional
              city: _cityController.text.isNotEmpty
                  ? _cityController.text
                  : 'Unknown', // Required field
              state: _stateController.text.isNotEmpty
                  ? _stateController.text
                  : null, // Optional
              postalCode: _postalCodeController.text.isNotEmpty
                  ? _postalCodeController.text
                  : null, // Optional
              country: 'YE', // Required - Yemen country code
            ),
          ),
        ),
      );

      print('🎨 Payment sheet initialized');

      // Present payment sheet
      await stripe.Stripe.instance.presentPaymentSheet();

      print('✅ Payment sheet completed successfully');

      // Payment successful - update order status
      await _updatePaymentStatus(orderId, 'completed');

      print('📊 Payment status updated to completed');

      // Show success message
      _showSuccessMessage('Payment completed successfully!');

      // Wait a moment for the message to show
      await Future.delayed(const Duration(milliseconds: 500));

      // Clear cart and navigate
      await _clearCartAndNavigate(orderId);
    } on stripe.StripeException catch (e) {
      print('❌ Stripe exception: ${e.error.code} - ${e.error.message}');

      // Hide loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (e.error.code == stripe.FailureCode.Canceled) {
        print('🚫 Payment canceled by user');
        // User canceled payment - still navigate to confirmation
        _showMessage(
            'Payment canceled. You can complete payment later from the order confirmation page.',
            isError: false);

        // Wait a moment for the message to show
        await Future.delayed(const Duration(milliseconds: 1000));

        // Navigate to confirmation even if payment was canceled
        await _clearCartAndNavigate(orderId);
      } else {
        print('💥 Payment failed: ${e.error.message}');
        // Payment failed
        await _updatePaymentStatus(orderId, 'failed');

        _showMessage(
            'Payment failed: ${e.error.message}. You can try again from the order confirmation page.',
            isError: true);

        // Wait a moment for the message to show
        await Future.delayed(const Duration(milliseconds: 1500));

        // Still navigate to confirmation page
        await _clearCartAndNavigate(orderId);
      }
    } catch (e) {
      print('💥 General error in payment process: $e');

      // Hide loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      await _updatePaymentStatus(orderId, 'failed');

      _showMessage(
          'Payment error: ${e.toString()}. You can try again from the order confirmation page.',
          isError: true);

      // Wait a moment for the message to show
      await Future.delayed(const Duration(milliseconds: 1500));

      // Still navigate to confirmation page
      await _clearCartAndNavigate(orderId);
    }
  }

  Future<void> _updatePaymentStatus(String orderId, String status) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'payment_status': status}).eq('id', orderId);
      print('✅ Payment status updated to: $status');
    } catch (e) {
      print('❌ Error updating payment status: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.orange,
        duration: Duration(seconds: isError ? 4 : 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _calculateTotal(List<dynamic> cartItems) {
    double total = 0.0;

    for (final item in cartItems) {
      final price = (item['products']?['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = item['quantity'] as int;
      total += price * quantity;
    }

    return total;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }
}
