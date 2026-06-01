import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Formulario de Registro en construcción...',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                // context.pop() te regresa a la pantalla anterior (Login)
                context.pop();
              },
              child: const Text('Regresar al Login'),
            ),
          ],
        ),
      ),
    );
  }
}
