import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_app/categories_screen.dart';
import 'package:supabase_app/order_status_screen.dart';
import 'package:supabase_app/settings_screen.dart';
import 'package:supabase_app/wish_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'theme_controller.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  bool _isDisposed = false;
  final themeController = Get.put(ThemeController());
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response =
          await Supabase.instance.client.from('products').select('''
        *, 
        categories(name),
        wishlist: wishlist!left(
          id
        ).eq(user_id, ${user.id})
    ''').order('created_at', ascending: false);
      // ... rest of the code ...
      if (!mounted || _isDisposed) return;

      setState(() {
        products = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      print('Error loading products: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // Mark as disposed
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;

      // Navigate to login and clear navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  // void _onItemTapped(int index) {
  //   setState(() => _selectedIndex = index);
  //   // Add navigation logic for different sections
  //   switch (index) {
  //     case 0:
  //       Navigator.of(context).push(
  //         MaterialPageRoute(builder: (_) => const ShoppingPage()),
  //       );
  //       break;
  //     case 1:
  //       Navigator.of(context).push(
  //         MaterialPageRoute(builder: (_) => const CategoriesScreen()),
  //       );
  //       break;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      //////drawer section
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Store'.tr,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Welcome!'.tr,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.shopping_bag_rounded),
                title: Text("Epurcheshop"),
                onTap: () => _scaffoldKey.currentState?.closeDrawer(),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: Text('Categories'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: Text('Wishlist'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WishlistScreen(),
                    ),
                  );
                },
              ), // In your navigation drawer or bottom bar
              ListTile(
                leading: const Icon(Icons.swap_horizontal_circle_sharp),
                title: Text('My Orders'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrderStatusScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: Text('Cart'.tr),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                  leading: Icon(Icons.settings),
                  title: Text("settings".tr),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ));
                  }),
              ListTile(
                  leading: Icon(Icons.info),
                  title: Text("About Us".tr),
                  onTap: () {})
            ],
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                icon: Icon(Icons.keyboard_double_arrow_right_outlined)),
            SizedBox(
              width: 5,
            ),
            Text(
              'EpurcheShop',
              style: GoogleFonts.alegreyaSansSc(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: const Text('2'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.pushNamed(context, '/wishlist'),
          ),
          IconButton(onPressed: _signOut, icon: Icon(Icons.logout))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mounted && !_isDisposed) {
            await _loadProducts();
          }
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? const Center(child: Text('No products found'))
                : _buildProductGrid(),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home),
      //       label: 'Home',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.category),
      //       label: 'Categories',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.person),
      //       label: 'Profile',
      //     ),
      //   ],
      // ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: product['images'] != null &&
                            product['images'].isNotEmpty
                        ? Hero(
                            tag: product['id'],
                            child: Image.network(
                              product['images'][0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderIcon(),
                            ),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                ),

                // Product Details
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'].toString().tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 16),
                          Text(
                            ' ${product['rating']?.toStringAsFixed(1) ?? '4.5'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Wishlist Button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  product['wishlist'] != null &&
                          (product['wishlist'] as List).isNotEmpty
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.redAccent,
                ),
                onPressed: () => _toggleWishlist(product['id']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[100],
      child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
    );
  }

  Future<void> _toggleWishlist(String productId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || !mounted || _isDisposed) return;

    try {
      final wishlistResponse = await Supabase.instance.client
          .from('wishlist')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', productId);

      if (wishlistResponse.isEmpty) {
        await Supabase.instance.client.from('wishlist').insert({
          'user_id': user.id,
          'product_id': productId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await Supabase.instance.client
            .from('wishlist')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);
      }
      if (mounted && !_isDisposed) {
        _loadProducts();
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
