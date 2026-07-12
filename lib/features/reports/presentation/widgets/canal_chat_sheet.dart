import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/report_repository.dart';
import '../../domain/models/canal_mensaje_model.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class CanalChatSheet extends ConsumerStatefulWidget {
  final int reporteId;
  final VoidCallback onCanalCerrado;
  const CanalChatSheet({super.key, required this.reporteId, required this.onCanalCerrado,});

  @override
  ConsumerState<CanalChatSheet> createState() => _CanalChatSheetState();
}

class _CanalChatSheetState extends ConsumerState<CanalChatSheet> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CanalMensajeModel> _mensajes = [];
  bool _isLoadingInicial = true;
  bool _isSending = false;
  String? _error;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _cargarMensajes(mostrarLoading: true);
    // Polling simple cada 5s mientras el sheet esté abierto
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _cargarMensajes(mostrarLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmarYCerrarCanal() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar canal de comunicación'),
        content: const Text(
          'Esta acción cerrará el chat para ambas partes de forma '
          'permanente. Si quieren seguir en contacto, intercambien '
          'sus números antes de continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cerrar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await ref.read(reportRepositoryProvider).cerrarCanalManual(widget.reporteId);
      widget.onCanalCerrado(); // Dispara el callback hacia la pantalla padre
      if (mounted) Navigator.pop(context); // Cierra el modal/sheet actual
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
  // ==========================================


  Future<void> _cargarMensajes({required bool mostrarLoading}) async {
    if (mostrarLoading) setState(() => _isLoadingInicial = true);
    try {
      final data = await ref
          .read(reportRepositoryProvider)
          .obtenerMensajesCanal(widget.reporteId);
      final mensajes = data.map((m) => CanalMensajeModel.fromJson(m)).toList();
      if (mounted) {
        setState(() {
          _mensajes = mensajes;
          _error = null;
        });
        _irAlFinal();
      }
      if (mensajes.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('canal_leido_${widget.reporteId}', mensajes.last.id);
        }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted && mostrarLoading) {
        setState(() => _isLoadingInicial = false);
      }
    }
  }

  void _irAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(reportRepositoryProvider)
          .enviarMensajeCanal(widget.reporteId, texto);
      _mensajeController.clear();
      await _cargarMensajes(mostrarLoading: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final miUsuarioId = authState.userId;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollSheetController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle visual
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Canal de comunicación',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
// ==========================================
                      // MODIFICACIÓN (Zona C): Botón de candado para cerrar canal
                      // ==========================================
                      IconButton(
                        icon: const Icon(Icons.lock_outline),
                        tooltip: 'Cerrar canal',
                        onPressed: _confirmarYCerrarCanal,
                      ),
                      // ==========================================

                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Leyenda de advertencia
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recuerda que la comunicación se cortará cuando el caso sea resuelto.',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // Lista de mensajes
                Expanded(
                  child: _isLoadingInicial
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null && _mensajes.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          : _mensajes.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aún no hay mensajes.\nEscribe el primero para iniciar la conversación.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  itemCount: _mensajes.length,
                                  itemBuilder: (context, index) {
                                    final msg = _mensajes[index];
                                    final esMio = msg.autorId == miUsuarioId;
                                    return _BurbujaMensaje(
                                      mensaje: msg,
                                      esMio: esMio,
                                    );
                                  },
                                ),
                ),

                // Campo de texto para enviar
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mensajeController,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _enviarMensaje(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isSending ? null : _enviarMensaje,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BurbujaMensaje extends StatelessWidget {
  final CanalMensajeModel mensaje;
  final bool esMio;

  const _BurbujaMensaje({required this.mensaje, required this.esMio});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: esMio ? Colors.blue.shade700 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(esMio ? 14 : 2),
            bottomRight: Radius.circular(esMio ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!esMio && mensaje.nombreAutor != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  mensaje.nombreAutor!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ),
            Text(
              mensaje.contenido,
              style: TextStyle(
                fontSize: 14,
                color: esMio ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              mensaje.horaFormateada,
              style: TextStyle(
                fontSize: 10,
                color: esMio ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}