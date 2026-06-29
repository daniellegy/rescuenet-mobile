import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _curpController = TextEditingController();

  String _selectedRole = 'Cliente';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _curpRegex = RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z\d]\d$');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _curpController.dispose();
    super.dispose();
  }

  Future<bool> _mostrarManifiestoVoluntario() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.gavel_rounded, color: Colors.brown),
                SizedBox(width: 8),
                Text(
                  'Manifiesto de Voluntario',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            content: const Text(
              'Declaro que los gastos derivados corren por mi cuenta u originados por financiamiento colectivo ajeno a la app. Al aceptar, asumo la responsabilidad ética y operativa de los rescates que acepte.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Acepto la responsabilidad'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _ejecutarRegistro() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == 'Voluntario') {
        final acepto = await _mostrarManifiestoVoluntario();
        if (!acepto) return;

        // MODIFICADO: Solicitud de permisos Push oportuna sólo para Voluntarios
        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (e) {
          debugPrint('Error al solicitar permisos FCM en registro: $e');
        }
      }

      try {
        await ref
            .read(authProvider.notifier)
            .register(
              nombre: _nameController.text,
              telefono: _phoneMaskFormatter.getUnmaskedText(),
              email: _emailController.text,
              password: _passwordController.text,
              rolId: _selectedRole == 'Voluntario' ? 2 : 1,
              curp: _selectedRole == 'Voluntario'
                  ? _curpController.text.trim().toUpperCase()
                  : null,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Únete a RescueNet',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa tus datos para empezar a ayudar.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'El nombre es obligatorio';
                    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ \s]+$').hasMatch(value))
                      return 'Ingresa un nombre válido (sin números)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_phoneMaskFormatter],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '(LADA) 123-4567',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'El teléfono es obligatorio';
                    if (_phoneMaskFormatter.getUnmaskedText().length < 10)
                      return 'Faltan números (deben ser 10 dígitos)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'El correo es obligatorio';
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value))
                      return 'Ingresa un formato de correo válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'La contraseña es obligatoria';
                    if (value.length < 6)
                      return 'Debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Confirma tu contraseña';
                    if (value != _passwordController.text)
                      return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: '¿Cómo deseas participar?',
                    prefixIcon: Icon(Icons.volunteer_activism),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Cliente',
                      child: Text('Solo quiero reportar casos'),
                    ),
                    DropdownMenuItem(
                      value: 'Voluntario',
                      child: Text('Quiero ser Voluntario de rescate'),
                    ),
                  ],
                  onChanged: (String? newValue) =>
                      setState(() => _selectedRole = newValue!),
                ),
                if (_selectedRole == 'Voluntario') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _curpController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    maxLength: 18,
                    decoration: const InputDecoration(
                      labelText: 'CURP',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                    validator: (value) {
                      if (_selectedRole == 'Voluntario') {
                        if (value == null || value.trim().isEmpty) {
                          return 'El CURP es obligatorio para voluntarios';
                        }
                        if (!_curpRegex.hasMatch(value.trim().toUpperCase())) {
                          return 'El formato del CURP es inválido';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _ejecutarRegistro,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Registrarme',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
