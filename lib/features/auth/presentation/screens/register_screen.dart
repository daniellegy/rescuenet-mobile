import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Agrega esta línea
import '../providers/auth_provider.dart'; // Agrega esta línea

// Cambia StatefulWidget por ConsumerStatefulWidget
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

// Cambia State por ConsumerState
class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); // Nuevo controlador

  String _selectedRole = 'Cliente';

  // Configuración de la máscara para el teléfono
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {"#": RegExp(r'[0-9]')}, // Solo permite números
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // No olvides limpiarlo
    super.dispose();
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

                // 1. NOMBRE COMPLETO
                TextFormField(
                  controller: _nameController,
                  textCapitalization:
                      TextCapitalization.words, // Mayúsculas automáticas
                  textInputAction:
                      TextInputAction.next, // Botón "Siguiente" en el teclado
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    // Regex para asegurar que solo sean letras y espacios
                    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
                      return 'Ingresa un nombre válido (sin números)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 2. TELÉFONO ENMASCARADO
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    _phoneMaskFormatter,
                  ], // Inyectamos la máscara
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '(LADA) 123-4567',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El teléfono es obligatorio';
                    }
                    // Verificamos la longitud de la máscara sin contar los símbolos
                    if (_phoneMaskFormatter.getUnmaskedText().length < 10) {
                      return 'Faltan números (deben ser 10 dígitos)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. CORREO ELECTRÓNICO (Regex mejorado)
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
                    if (value == null || value.isEmpty) {
                      return 'El correo es obligatorio';
                    }
                    // Expresión regular oficial para correos
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Ingresa un formato de correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. CONTRASEÑA
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
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

                // 5. CONFIRMAR CONTRASEÑA
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction:
                      TextInputAction.done, // Botón "Hecho" en el teclado
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    // Comprobamos que coincida con el primer campo
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 6. SELECTOR DE ROL
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
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // BOTÓN DE REGISTRO
                FilledButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        await ref
                            .read(authProvider.notifier)
                            .register(
                              nombre: _nameController.text,
                              telefono: _phoneMaskFormatter.getUnmaskedText(),
                              email: _emailController.text,
                              password: _passwordController.text,
                              rolId: _selectedRole == 'Voluntario'
                                  ? 2
                                  : 1, // 1 es Reportante
                            );
                        // No necesitas usar GoRouter aquí porque el guardia de rutas
                        // te redirigirá automáticamente al mapa al cambiar el authState.
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
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
