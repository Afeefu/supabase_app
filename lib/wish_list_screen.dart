import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_app/product_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _wishlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response =
          await Supabase.instance.client.from('wishlist').select('''
          id, created_at,
          products!fk_wishlist_product (id, name, price, images)
        ''').eq('user_id', user.id).order('created_at', ascending: false);

      setState(() {
        _wishlistItems = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading wishlist: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('wishlist')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);

      _loadWishlist();
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Wishlist'.tr)),
      body: RefreshIndicator(
        onRefresh: _loadWishlist,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wishlistItems.isEmpty
                ? Center(child: Text('No items in wishlist'.tr))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _wishlistItems.length,
                    itemBuilder: (context, index) {
                      final item = _wishlistItems[index]['products'];
                      return _buildWishlistItem(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildWishlistItem(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product['images'][0],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported),
          ),
        ),
        title: Text(product['name'].toString().tr),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\$${product['price']}'),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                Text('4.5'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeFromWishlist(product['id']),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        ),
      ),
    );
  }
}
