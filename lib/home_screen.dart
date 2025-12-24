// import 'package:flutter/material.dart';
// import 'package:supabase_app/add_product_screen.dart';

// import 'package:supabase_flutter/supabase_flutter.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   Future<List<dynamic>> fetchProducts() async {
//     final response = await Supabase.instance.client.from('products').select();
//     return response as List<dynamic>;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("المتجر")),
//       body: FutureBuilder<List<dynamic>>(
//         future: fetchProducts(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData)
//             return Center(child: CircularProgressIndicator());
//           final products = snapshot.data!;
//           return ListView.builder(
//               itemCount: products.length,
//               itemBuilder: (context, index) {
//                 final product = products[index];
//                 return ListTile(
//                     leading: Image.network(product['image_url'],
//                         width: 50, height: 50, fit: BoxFit.cover),
//                     title: Text(product['name']),
//                     subtitle: Text("${product['price']} USD"));
//               });
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => Navigator.push(
//             context, MaterialPageRoute(builder: (_) => AddProductScreen())),
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }
