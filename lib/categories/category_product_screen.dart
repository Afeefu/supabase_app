import 'package:flutter/material.dart';
import 'package:supabase_app/product_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;

  const CategoryProductsScreen({super.key, required this.categoryId});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String categoryName = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadCategoryProducts();
  }

  Future<void> _loadCategoryProducts() async {
    try {
      // Get category name
      final categoryResponse = await Supabase.instance.client
          .from('categories')
          .select('name')
          .eq('id', widget.categoryId)
          .single();

      // Get products for this category
      final productsResponse = await Supabase.instance.client
          .from('products')
          .select('''
            *, 
            categories(name),
            wishlist: wishlist!product_id (user_id)
          ''')
          .eq('category_id', widget.categoryId)
          .order('created_at', ascending: false);

      if (!mounted || _isDisposed) return;

      setState(() {
        categoryName = categoryResponse['name'];
        products = List<Map<String, dynamic>>.from(productsResponse);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      print('Error loading category products: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text('No products in this category'))
              : _buildProductGrid(),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ),
      ),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                product['images'][0],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('\$${product['price'].toStringAsFixed(2)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
