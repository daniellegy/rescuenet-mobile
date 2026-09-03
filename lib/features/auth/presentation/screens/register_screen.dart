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

  // Mantiene el campo de rol neutral hasta que se toque
  bool _roleInteracted = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _curpRegex = RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z\d]\d$');
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final _nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$');

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

  bool get _isNameValid =>
      _nameRegex.hasMatch(_nameController.text.trim()) &&
      _nameController.text.trim().isNotEmpty;
  bool get _isPhoneValid => _phoneMaskFormatter.getUnmaskedText().length == 10;
  bool get _isEmailValid => _emailRegex.hasMatch(_emailController.text.trim());
  bool get _isPasswordValid => _passwordController.text.length >= 6;
  bool get _isConfirmPasswordValid =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _passwordController.text;
  bool get _isCurpValid =>
      _curpRegex.hasMatch(_curpController.text.trim().toUpperCase());

  // Maneja la neutralidad y sincroniza el color del texto
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    required bool isValid,
    required bool isEmpty,
    bool isNeutral = false,
    String? hintText,
    Widget? suffixIcon,
  }) {
    Color borderColor = (isEmpty || isNeutral)
        ? Colors.grey
        : (isValid ? Colors.green.shade600 : Colors.red);
    Color iconColor = (isEmpty || isNeutral)
        ? Colors.grey.shade600
        : (isValid ? Colors.green.shade600 : Colors.red);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: borderColor),
      floatingLabelStyle: TextStyle(color: borderColor),
      prefixIcon: Icon(prefixIcon, color: iconColor),
      suffixIcon:
          suffixIcon ??
          ((isEmpty || isNeutral)
              ? null
              : Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: iconColor,
                )),
      border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 2.0),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2.0),
      ),
    );
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
              'Declaro que los gastos derivados corren por mi cuenta u originados por financiamiento colectivo ajeno a la app. Al aceptar, asumo la responsabilidad operativa de los rescates que acepte.',
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
    // Si la validación falla, lanzamos el aviso y salimos temprano
    if (_formKey.currentState?.validate() != true) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Por favor, completa correctamente todos los campos obligatorios.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Si llega aquí, es porque el formulario es válido
    if (_selectedRole == 'Voluntario') {
      final acepto = await _mostrarManifiestoVoluntario();
      if (!acepto) {
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  onChanged: (_) => setState(() {}),
                  decoration: _buildInputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icons.person,
                    isValid: _isNameValid,
                    isEmpty: _nameController.text.isEmpty,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    if (!_nameRegex.hasMatch(value)) {
                      return 'Ingresa un nombre válido (sin números)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [_phoneMaskFormatter],
                  onChanged: (_) => setState(() {}),
                  decoration: _buildInputDecoration(
                    labelText: 'Teléfono',
                    hintText: '(123) 456-7890',
                    prefixIcon: Icons.phone,
                    isValid: _isPhoneValid,
                    isEmpty: _phoneController.text.isEmpty,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El teléfono es obligatorio';
                    }
                    if (_phoneMaskFormatter.getUnmaskedText().length < 10) {
                      return 'Faltan números (deben ser 10 dígitos)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: _buildInputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icons.email,
                    isValid: _isEmailValid,
                    isEmpty: _emailController.text.isEmpty,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El correo es obligatorio';
                    }
                    if (!_emailRegex.hasMatch(value)) {
                      return 'Ingresa un formato de correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: _buildInputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icons.lock,
                    isValid: _isPasswordValid,
                    isEmpty: _passwordController.text.isEmpty,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: _passwordController.text.isEmpty
                            ? Colors.grey
                            : (_isPasswordValid
                                  ? Colors.green.shade600
                                  : Colors.red),
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    if (value.length < 6) {
                      return 'Debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: _buildInputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: Icons.lock_outline,
                    isValid: _isConfirmPasswordValid,
                    isEmpty: _confirmPasswordController.text.isEmpty,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: _confirmPasswordController.text.isEmpty
                            ? Colors.grey
                            : (_isConfirmPasswordValid
                                  ? Colors.green.shade600
                                  : Colors.red),
                      ),
                      onPressed: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: _buildInputDecoration(
                    labelText: '¿Cómo deseas participar?',
                    prefixIcon: Icons.volunteer_activism,
                    isValid: true,
                    isEmpty: false,
                    isNeutral:
                        !_roleInteracted, // Se alica la neutralidad hasta que el usuario interactúe
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Cliente',
                      child: Text('Reportar casos'),
                    ),
                    DropdownMenuItem(
                      value: 'Voluntario',
                      child: Text('Voluntario de rescate'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _roleInteracted = true; // Registra la interaccion
                        _selectedRole = newValue;
                        if (_selectedRole != 'Voluntario') {
                          _curpController.clear();
                        }
                      });
                    }
                  },
                ),
                if (_selectedRole == 'Voluntario') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _curpController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    maxLength: 18,
                    onChanged: (_) => setState(() {}),
                    decoration: _buildInputDecoration(
                      labelText: 'CURP',
                      prefixIcon: Icons.badge,
                      isValid: _isCurpValid,
                      isEmpty: _curpController.text.isEmpty,
                    ).copyWith(counterText: ""),
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
