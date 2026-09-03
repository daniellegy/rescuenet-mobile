// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// enum LostDogSort { recientes, antiguos, masVista, porEstado }

// class LostDogPost {
//   const LostDogPost({
//     required this.name,
//     required this.breed,
//     required this.lastSeen,
//     required this.zone,
//     required this.createdAt,
//     required this.estado,
//     this.imageUrl,
//     this.reward,
//     this.contact,
//     this.isVerified = false,
//   });

//   final String name;
//   final String breed;
//   final String lastSeen;
//   final String zone;
//   final DateTime createdAt;
//   final String estado;
//   final String? imageUrl;
//   final String? reward;
//   final String? contact;
//   final bool isVerified;

//   Color get estadoColor {
//     switch (estado.toLowerCase()) {
//       case 'en búsqueda':
//         return Colors.deepOrange;
//       default:
//         return Colors.blueGrey;
//     }
//   }

//   String get timeAgo {
//     final diff = DateTime.now().difference(createdAt);
//     if (diff.inDays > 0) {
//       return 'hace ${diff.inDays} d';
//     }
//     if (diff.inHours > 0) {
//       return 'hace ${diff.inHours} h';
//     }
//     if (diff.inMinutes > 0) {
//       return 'hace ${diff.inMinutes} min';
//     }
//     return 'hace un momento';
//   }
// }

// class LostDogsScreen extends ConsumerStatefulWidget {
//   const LostDogsScreen({super.key});

//   @override
//   ConsumerState<LostDogsScreen> createState() => _LostDogsScreenState();
// }

// class _LostDogsScreenState extends ConsumerState<LostDogsScreen> {
//   LostDogSort _ordenActual = LostDogSort.recientes;

//   final List<LostDogPost> _posts = [
//     LostDogPost(
//       name: 'Luna',
//       breed: 'Mestiza mediana',
//       lastSeen: 'Cuautlacingo en la iglesia del centro',
//       zone: 'Zona Centro',
//       createdAt: DateTime.now().subtract(Duration(hours: 3)),
//       estado: 'En búsqueda',
//       reward: '\$1,500 recompensa',
//       contact: '55 1234 5678',
//       isVerified: true,
//     ),
//     LostDogPost(
//       name: 'Toby',
//       breed: 'Pug',
//       lastSeen: 'Burger king del centro historico',
//       zone: 'Col. Jardines',
//       createdAt: DateTime.now().subtract(Duration(days: 1)),
//       estado: 'En búsqueda',
//       reward: 'Se agradece compartir',
//       contact: '55 9876 5432',
//     ),
//     LostDogPost(
//       name: 'Mila',
//       breed: 'Labrador blanco',
//       lastSeen: 'Frente a la pollyworks',
//       zone: 'Zona Norte',
//       createdAt: DateTime.now().subtract(Duration(days: 2, hours: 4)),
//       estado: 'En búsqueda',
//       reward: '\$3,000 recompensa',
//       contact: '55 4444 8899',
//     ),
//   ];

//   List<LostDogPost> _ordenarPosts(List<LostDogPost> posts) {
//     final lista = List<LostDogPost>.from(posts);

//     switch (_ordenActual) {
//       case LostDogSort.recientes:
//         lista.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//         break;
//       case LostDogSort.antiguos:
//         lista.sort((a, b) => a.createdAt.compareTo(b.createdAt));
//         break;
//       case LostDogSort.masVista:
//         lista.sort((a, b) => a.name.compareTo(b.name));
//         break;
//       case LostDogSort.porEstado:
//         lista.sort(
//           (a, b) =>
//               b.estadoColor.toARGB32().compareTo(a.estadoColor.toARGB32()),
//         );
//         break;
//     }

//     return lista;
//   }

//   Future<void> _openRegisterDogSheet() async {
//     final nameController = TextEditingController();
//     final breedController = TextEditingController();
//     final zoneController = TextEditingController();
//     final locationController = TextEditingController();
//     final contactController = TextEditingController();
//     final rewardController = TextEditingController();
//     final notesController = TextEditingController();
//     const String estado = 'En búsqueda';

//     await showModalBottomSheet<void>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.88,
//           minChildSize: 0.65,
//           maxChildSize: 0.96,
//           builder: (context, scrollController) {
//             return Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//               ),
//               child: SingleChildScrollView(
//                 controller: scrollController,
//                 padding: EdgeInsets.fromLTRB(
//                   20,
//                   16,
//                   20,
//                   MediaQuery.of(context).viewInsets.bottom + 20,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 48,
//                         height: 5,
//                         decoration: BoxDecoration(
//                           color: Colors.black12,
//                           borderRadius: BorderRadius.circular(99),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 18),
//                     const Text(
//                       'Registrar perro perdido',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Prototipo visual: aquí después conectamos fotos, ubicación y envío al backend.',
//                       style: TextStyle(color: Colors.black54),
//                     ),
//                     const SizedBox(height: 20),
//                     TextField(
//                       controller: nameController,
//                       decoration: const InputDecoration(
//                         labelText: 'Nombre del perro',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: breedController,
//                       decoration: const InputDecoration(
//                         labelText: 'Raza o descripción',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: zoneController,
//                       decoration: const InputDecoration(
//                         labelText: 'Zona o colonia',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: locationController,
//                       decoration: const InputDecoration(
//                         labelText: 'Última ubicación vista',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 14,
//                         vertical: 16,
//                       ),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.black26),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: const Text(
//                         'Estado: En búsqueda',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: contactController,
//                       keyboardType: TextInputType.phone,
//                       decoration: const InputDecoration(
//                         labelText: 'Teléfono de contacto',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: rewardController,
//                       decoration: const InputDecoration(
//                         labelText: 'Recompensa (opcional)',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     TextField(
//                       controller: notesController,
//                       maxLines: 4,
//                       decoration: const InputDecoration(
//                         labelText: 'Señas particulares o notas',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 18),
//                     SizedBox(
//                       width: double.infinity,
//                       child: FilledButton.icon(
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                           ScaffoldMessenger.of(this.context).showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Prototipo listo. Después se conectará el guardado.',
//                               ),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.pets_rounded),
//                         label: const Text('Publicar aviso'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final postsOrdenados = _ordenarPosts(_posts);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Perros perdidos'),
//         actions: [
//           PopupMenuButton<LostDogSort>(
//             icon: const Icon(Icons.sort_rounded),
//             tooltip: 'Ordenar avisos',
//             onSelected: (nuevoOrden) {
//               setState(() {
//                 _ordenActual = nuevoOrden;
//               });
//             },
//             itemBuilder: (context) => const [
//               PopupMenuItem(
//                 value: LostDogSort.recientes,
//                 child: Text('Más recientes'),
//               ),
//               PopupMenuItem(
//                 value: LostDogSort.antiguos,
//                 child: Text('Más antiguos'),
//               ),
//               PopupMenuItem(
//                 value: LostDogSort.masVista,
//                 child: Text('Orden alfabético'),
//               ),
//               PopupMenuItem(
//                 value: LostDogSort.porEstado,
//                 child: Text('Por estado'),
//               ),
//             ],
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _openRegisterDogSheet,
//         icon: const Icon(Icons.add_rounded),
//         label: const Text('Registrar perro perdido'),
//       ),
//       body: CustomScrollView(
//         slivers: [
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(18),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.blueGrey.withValues(alpha: 0.18),
//                       blurRadius: 18,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: const Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Avisos de perros perdidos',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Publica un aviso, comparte la última ubicación y ayuda a que vuelva a casa.',
//                       style: TextStyle(color: Colors.white70, height: 1.3),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   _buildStatCard(
//                     'Activos',
//                     '${postsOrdenados.length}',
//                     Colors.red,
//                   ),
//                   const SizedBox(width: 12),

//                   _buildStatCard('Hoy', '1', Colors.green),
//                 ],
//               ),
//             ),
//           ),
//           const SliverToBoxAdapter(child: SizedBox(height: 12)),
//           if (postsOrdenados.isEmpty)
//             const SliverFillRemaining(
//               hasScrollBody: false,
//               child: Center(
//                 child: Text(
//                   'No hay avisos todavía',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//             )
//           else
//             SliverList(
//               delegate: SliverChildBuilderDelegate((context, index) {
//                 final post = postsOrdenados[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   child: Card(
//                     elevation: 2,
//                     clipBehavior: Clip.antiAlias,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: post.estadoColor.withValues(alpha: 0.05),
//                         border: Border(
//                           left: BorderSide(color: post.estadoColor, width: 6),
//                         ),
//                       ),
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 10,
//                         ),
//                         leading: CircleAvatar(
//                           radius: 28,
//                           backgroundColor: post.estadoColor.withValues(
//                             alpha: 0.12,
//                           ),
//                           child: const Icon(Icons.pets_rounded, size: 30),
//                         ),
//                         title: Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 post.name,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         subtitle: Padding(
//                           padding: const EdgeInsets.only(top: 6),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text('${post.breed} • ${post.zone}'),
//                               const SizedBox(height: 4),
//                               Text('Visto por última vez: ${post.lastSeen}'),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'Publicado ${post.timeAgo} • Estado: ${post.estado}',
//                               ),
//                               if (post.reward != null) ...[
//                                 const SizedBox(height: 4),
//                                 Text(post.reward!),
//                               ],
//                             ],
//                           ),
//                         ),
//                         trailing: Icon(
//                           Icons.arrow_forward_ios,
//                           color: post.estadoColor,
//                           size: 18,
//                         ),
//                         onTap: () {
//                           showModalBottomSheet<void>(
//                             context: context,
//                             showDragHandle: true,
//                             builder: (context) {
//                               return Padding(
//                                 padding: const EdgeInsets.all(20),
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       post.name,
//                                       style: const TextStyle(
//                                         fontSize: 22,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     Text('${post.breed} • ${post.zone}'),
//                                     const SizedBox(height: 8),
//                                     Text('Última ubicación: ${post.lastSeen}'),
//                                     const SizedBox(height: 8),
//                                     Text(
//                                       'Contacto: ${post.contact ?? 'Pendiente'}',
//                                     ),
//                                     const SizedBox(height: 8),
//                                     Text('Estado: ${post.estado}'),
//                                     const SizedBox(height: 16),
//                                     SizedBox(
//                                       width: double.infinity,
//                                       child: FilledButton.icon(
//                                         onPressed: () {
//                                           ScaffoldMessenger.of(
//                                             context,
//                                           ).showSnackBar(
//                                             SnackBar(
//                                               content: Text(
//                                                 'Contacto del dueño: ${post.contact ?? 'Pendiente'}',
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                         icon: const Icon(Icons.phone_rounded),
//                                         label: const Text('Contactar dueño'),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 10),
//                                     SizedBox(
//                                       width: double.infinity,
//                                       child: FilledButton(
//                                         onPressed: () =>
//                                             Navigator.of(context).pop(),
//                                         child: const Text('Cerrar'),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 );
//               }, childCount: postsOrdenados.length),
//             ),
//           const SliverToBoxAdapter(child: SizedBox(height: 96)),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String label, String value, Color color) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//         decoration: BoxDecoration(
//           color: color.withValues(alpha: 0.08),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: color.withValues(alpha: 0.15)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               value,
//               style: TextStyle(
//                 color: color,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(label, style: const TextStyle(color: Colors.black54)),
//           ],
//         ),
//       ),
//     );
//   }
// }
