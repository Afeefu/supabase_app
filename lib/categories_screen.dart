import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_app/categories/category_product_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  bool _isDisposed = false;
  // List images = [
  //   'images/smartphone.png',
  //   'images/clothes.png',
  //   'images/books.jpg',
  //   'images/beauty.png',
  //   'images/fittness.jpg',
  //   'images/toysandpresents.jpg',
  //   'images/homefurniture.png'
  // ];
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name, description')
          .order('created_at', ascending: true);

      if (!mounted || _isDisposed) return;

      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      print('Error loading categories: $e');
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
        automaticallyImplyLeading: false,
        title: Text(
          'Categories'.tr,
          style: GoogleFonts.alegreyaSans(
              color: Colors.black,
              letterSpacing: 0.5,
              fontSize: 20,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) =>
                  _buildCategoryItem(categories[index]),
            ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return ListTile(
      leading: Image.asset('images/${category['name'].toLowerCase()}.png'),
      title: Text(
        '${category['name']}'.tr,
        style: GoogleFonts.alegreyaSans(),
      ),
      subtitle: Text('${category['description']}'.tr),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(
              categoryId: category['id'].toString(),
            ),
          ),
        );
      },
    );
  }
}
