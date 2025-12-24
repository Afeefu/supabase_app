import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_app/order_management_screen.dart';
import 'package:supabase_app/product_management_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<XFile> _selectedImages = [];
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name')
          .order('name', ascending: true);
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showError(context, 'Failed to load categories: ${e.toString()}');
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
      );
      setState(() => _selectedImages.addAll(pickedFiles));
    } catch (e) {
      _showError(context, 'Error selecting images: ${e.toString()}');
    }
  }

  Future<List<String>> _uploadImages() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final List<String> imageUrls = [];

    if (user == null) throw Exception('User not authenticated');

    try {
      for (final file in _selectedImages) {
        final bytes = await file.readAsBytes();
        final fileExtension = path.extension(file.path);
        // Include user ID in file path
        final fileName =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}$fileExtension';

        await supabase.storage.from('products').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                contentType: file.mimeType,
                upsert: false,
              ),
            );

        final publicUrl =
            supabase.storage.from('products').getPublicUrl(fileName);

        imageUrls.add(publicUrl);
      }
      return imageUrls;
    } catch (e) {
      _showError(context, 'Image upload failed: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _submitProduct() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError(context, 'Authentication required');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showError(context, 'Please select at least one image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrls = await _uploadImages();

      await Supabase.instance.client.from('products').insert({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'category_id': _selectedCategory,
        'images': imageUrls,
        'created_at': DateTime.now().toIso8601String(),
        'owner_id': user.id, // Add owner reference
      });

      _showSuccess(context, 'Product added successfully!');
      _resetForm();
    } catch (e) {
      _showError(context, 'Failed to add product: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedImages.clear();
      _selectedCategory = null;
    });
  }

  // Updated functions now accept BuildContext as parameter.
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Product',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Tooltip(
              message: 'manage orders',
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(color: Colors.white),
              child: IconButton(
                icon: const Icon(Icons.list_alt),
                tooltip: 'View Orders',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrderManagementScreen()),
                ),
              )),
          Tooltip(
              message: 'Manage products',
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(color: Colors.white),
              child: IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: 'Manage Products',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProductManagementScreen()),
                ),
              )),
          Tooltip(
              message: 'logout',
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(color: Colors.white),
              child: IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isLoading ? null : _submitProduct,
              )),
          Tooltip(
              message: 'save product',
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(color: Colors.white),
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _isLoading ? null : _signOut,
              )),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageGrid(),
                    const SizedBox(height: 20),
                    _buildImagePickerButton(),
                    const SizedBox(height: 20),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Required field'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required field';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

////////build image grid builds an icon holder for the products images. It also includes a close button to remove the image from the grid. It uses a GridView.builder to create a grid of images. The grid is set to 3 columns and has a fixed cross-axis spacing and main-axis spacing. The grid items are created using a Stack widget that contains an Image.file widget for the product image and a Positioned widget for the close button. The grid items are also wrapped in a Stack widget that contains an Image.file widget for the product image and a Positioned widget for the close button.
  /// The grid items are also wrapped in a Stack widget that contains an Image.
  /// file widget for the product image and a Positioned widget for the close button.
  /// The grid items are also wrapped in a Stack widget that contains an Image.file
  Widget _buildImageGrid() {
    return _selectedImages.isEmpty
        ? Container(
            height: 150,
            color: Colors.grey[200],
            child: const Center(child: Text('No images selected')),
          )
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Image.file(
                    File(_selectedImages[index].path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          );
  }

  Widget _buildImagePickerButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_photo_alternate),
      label: const Text('Add Images'),
      onPressed: _pickImages,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Select Category'),
        ),
        ..._categories.map((category) => DropdownMenuItem(
              value: category['id'].toString(),
              child: Text(category['name']),
            )),
      ],
      onChanged: (value) => setState(() {
        _selectedCategory = value;
      }),
      validator: (value) => value == null ? 'Required field' : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
