import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/report_repository.dart';
import '../../domain/models/canal_mensaje_model.dart';

class CanalChatSheet extends ConsumerStatefulWidget {
  final int reporteId;
  final VoidCallback onCanalCerrado;

  const CanalChatSheet({
    super.key,
    required this.reporteId,
    required this.onCanalCerrado,
  });

  @override
  ConsumerState<CanalChatSheet> createState() => _CanalChatSheetState();
}

class _CanalChatSheetState extends ConsumerState<CanalChatSheet> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  IO.Socket? _socket;
  List<CanalMensajeModel> _mensajes = [];
  bool _isLoadingInicial = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMensajes(mostrarLoading: true);
    _iniciarConexionWebSocket();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _iniciarConexionWebSocket() {
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final uri = Uri.tryParse(apiUrl);
    final socketUrl = uri != null
        ? '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}'
        : apiUrl;

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('Conectado al WebSocket del servidor');
      _socket?.emit('join_canal', widget.reporteId);
    });

    _socket?.on('reconnect', (_) {
      debugPrint(
        'Reconectado al WebSocket. Reuniéndose a la sala del canal...',
      );
      _socket?.emit('join_canal', widget.reporteId);
    });

    _socket?.on('nuevo_mensaje', (data) {
      if (mounted) {
        final nuevoMensaje = CanalMensajeModel.fromJson(data);
        setState(() {
          if (!_mensajes.any((m) => m.id == nuevoMensaje.id)) {
            _mensajes.add(nuevoMensaje);
          }
        });
        _irAlFinal();
        _marcarUltimoMensajeComoLeido(nuevoMensaje.id);
      }
    });

    _socket?.onDisconnect((_) => debugPrint('Desconectado del WebSocket'));
  }

  Future<void> _marcarUltimoMensajeComoLeido(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('canal_leido_${widget.reporteId}', id);
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
      await ref
          .read(reportRepositoryProvider)
          .cerrarCanalManual(widget.reporteId);
      widget.onCanalCerrado();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

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
        await _marcarUltimoMensajeComoLeido(mensajes.last.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
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
      final response = await ref
          .read(reportRepositoryProvider)
          .enviarMensajeCanal(widget.reporteId, texto);
      final nuevoMensaje = CanalMensajeModel.fromJson(response);
      if (mounted) {
        setState(() {
          if (!_mensajes.any((m) => m.id == nuevoMensaje.id)) {
            _mensajes.add(nuevoMensaje);
          }
        });
        _irAlFinal();
      }
      _mensajeController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollSheetController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blueGrey,
                      ),
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
                      IconButton(
                        icon: const Icon(Icons.lock_outline),
                        tooltip: 'Cerrar canal',
                        onPressed: _confirmarYCerrarCanal,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.amber.shade900.withValues(alpha: 0.2)
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.amber.shade700
                          : Colors.amber.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: isDark
                            ? Colors.amber.shade400
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recuerda que la comunicación se cortará cuando el caso sea resuelto.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.amber.shade200
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
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
                            return _BurbujaMensaje(mensaje: msg, esMio: esMio);
                          },
                        ),
                ),
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
                              fillColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
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
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: esMio
              ? Colors.blue.shade700
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
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
                    color: isDark
                        ? Colors.blueGrey.shade300
                        : Colors.blueGrey.shade700,
                  ),
                ),
              ),
            Text(
              mensaje.contenido,
              style: TextStyle(
                fontSize: 14,
                color: esMio
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              mensaje.horaFormateada,
              style: TextStyle(
                fontSize: 10,
                color: esMio
                    ? Colors.white70
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
