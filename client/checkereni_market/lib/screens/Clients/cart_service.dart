// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'cart_service.dart';

// class CartScreen extends StatelessWidget {
//   const CartScreen({Key? key

// class QuantityButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onPressed;

//   const QuantityButton({
//     Key? key,
//     required this.icon,
//     required this.onPressed,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onPressed,
//       borderRadius: BorderRadius.circular(4),
//       child: Container(
//         width: 30,
//         height: 30,
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.shade300),
//           borderRadius: BorderRadius.circular(4),
//         ),
//         child: Icon(
//           icon,
//           size: 16,
//           color: Colors.green,
//         ),
//       ),
//     );
//   }
// }

// class CheckoutSummary extends StatelessWidget {
//   final double totalAmount;
//   final VoidCallback onCheckout;

//   const CheckoutSummary({
//     Key? key,
//     required this.totalAmount,
//     required this.onCheckout,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 5,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Muhtasari wa Malipo',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('Jumla ya bidhaa:'),
//               Text(
//                 'Tsh ${totalAmount.toStringAsFixed(2)}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           const SizedBox(height: 5),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('Usafirishaji:'),
//               Text(
//                 'Tsh ${(2000.0).toStringAsFixed(2)}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           const Divider(height: 20),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Jumla:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 'Tsh ${(totalAmount + 2000.0).toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.green,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: onCheckout,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 'Lipa Sasa',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Kikapu Changu'),
//         backgroundColor: Colors.green,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete_outline),
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (ctx) => AlertDialog(
//                   title: const Text('Futa Kikapu'),
//                   content: const Text('Unataka kufuta bidhaa zote kwenye kikapu?'),
//                   actions: [
//                     TextButton(
//                       child: const Text('Hapana'),
//                       onPressed: () => Navigator.of(ctx).pop(),
//                     ),
//                     TextButton(
//                       child: const Text('Ndio'),
//                       onPressed: () {
//                         Provider.of<CartService>(context, listen: false).clearCart();
//                         Navigator.of(ctx).pop();
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Consumer<CartService>(
//         builder: (context, cart, child) {
//           if (cart.items.isEmpty) {
//             return const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.shopping_cart_outlined,
//                     size: 100,
//                     color: Colors.grey,
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     'Kikapu chako ni tupu',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     'Ongeza bidhaa kwenye kikapu',
//                     style: TextStyle(
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }
          
//           return Column(
//             children: [
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: cart.items.length,
//                   itemBuilder: (ctx, i) => CartItemWidget(
//                     cartItem: cart.items[i],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               CheckoutSummary(
//                 totalAmount: cart.totalAmount,
//                 onCheckout: () {
//                   // TODO: Implement checkout functionality
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Checkout functionality to be implemented'),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class CartItemWidget extends StatelessWidget {
//   final CartItem cartItem;

//   const CartItemWidget({
//     Key? key,
//     required this.cartItem,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Row(
//           children: [
//             // Product Image
//             Container(
//               width: 70,
//               height: 70,
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: getCropImage(cartItem.crop.name),
//             ),
//             const SizedBox(width: 10),
//             // Product Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     cartItem.crop.name,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Tsh ${cartItem.crop.price.toStringAsFixed(2)}/kg',
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Jumla: Tsh ${cartItem.totalPrice.toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Quantity Controls
//             Column(
//               children: [
//                 Row(
//                   children: [
//                     QuantityButton(
//                       icon: Icons.remove,
//                       onPressed: () {
//                         Provider.of<CartService>(context, listen: false)
//                             .decrementQuantity(cartItem.crop.cropId);
//                       },
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                       child: Text(
//                         '${cartItem.quantity}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     QuantityButton(
//                       icon: Icons.add,
//                       onPressed: () {
//                         Provider.of<CartService>(context, listen: false)
//                             .incrementQuantity(cartItem.crop.cropId);
//                       },
//                     ),
//                   ],
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () {
//                     Provider.of<CartService>(context, listen: false)
//                         .removeItem(cartItem.crop.cropId);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('${cartItem.crop.name} removed from cart'),
//                         duration: const Duration(seconds: 2),
//                       ),
//                     );