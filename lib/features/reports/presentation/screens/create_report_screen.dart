import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/report_repository.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final double lat;
  final double lng;
  final String imagePath;

  const CreateReportScreen({
    super.key,
    required this.lat,
    required this.lng,
    required this.imagePath,
  });

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();
  String _especie = 'Perro';
  bool _isLoading = false;

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(reportRepositoryProvider);
      await repository.createReport(
        lat: widget.lat,
        lng: widget.lng,
        especie: _especie,
        color: _colorController.text,
        imagePath: widget.imagePath,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte creado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completar Reporte')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.imagePath),
                        height: 250,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _especie,
                      decoration: const InputDecoration(
                        labelText: 'Especie',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Perro', 'Gato']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _especie = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _colorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Color Dominante',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa el color' : null,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _submitReport,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar Reporte'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
