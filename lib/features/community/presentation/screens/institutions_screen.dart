import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class InstitutionsScreen extends StatelessWidget {
  const InstitutionsScreen({super.key});

  Future<void> _launchUrl(
    BuildContext context,
    String scheme,
    String path,
  ) async {
    final cleanPath = scheme == 'tel'
        ? path.replaceAll(RegExp(r'\s+'), '')
        : path;
    final Uri uri = Uri(scheme: scheme, path: cleanPath);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo abrir la aplicación correspondiente para: $cleanPath',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _launchMap(BuildContext context, String address) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la aplicación de mapas.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Construye un contenedor agrupado que separa visualmente cada sección
  Widget _buildSectionGroup(
    BuildContext context, {
    required String title,
    required Color titleColor,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: titleColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: titleColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInstitutionCard(
    BuildContext context, {
    required String name,
    required String description,
    required IconData icon,
    Color iconColor = Colors.blue,
    String? phone,
    String? phone2,
    String? email,
    String? address,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF222222) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.15),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            if (phone != null || email != null || address != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              if (phone != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: Text(phone, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _launchUrl(context, 'tel', phone),
                ),
              if (phone2 != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: Text(phone2, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _launchUrl(context, 'tel', phone2),
                ),
              if (email != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.email, color: Colors.orange),
                  title: Text(email, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _launchUrl(context, 'mailto', email),
                ),
              if (address != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(address, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(
                    Icons.navigation_rounded,
                    size: 18,
                    color: Colors.blueAccent,
                  ),
                  onTap: () => _launchMap(context, address),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto a Instituciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/map');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Rescate y Fauna Silvestre
          _buildSectionGroup(
            context,
            title: 'Rescate de Emergencia y Fauna Silvestre',
            titleColor: Colors.red,
            children: [
              _buildInstitutionCard(
                context,
                name: 'Bomberos / Protección Civil',
                description:
                    'Animales atrapados en pozos, barrancas, accidentes viales, o riesgo inminente de muerte.',
                icon: Icons.local_fire_department,
                iconColor: Colors.red,
                phone: '911',
                phone2: '222 245 7392',
              ),
              _buildInstitutionCard(
                context,
                name: 'PROFEPA (Delegación Puebla)',
                description:
                    'Tráfico ilegal, rescate de fauna silvestre (aves rapaces, reptiles, grandes felinos, etc.).',
                icon: Icons.forest,
                iconColor: Colors.green,
                phone: '800 776 3372',
                phone2: '222 246 6702',
                email: 'denuncias@profepa.gob.mx',
                address:
                    'Calle 5 Poniente #1303, Edificio Papillón, Col. Centro, Puebla',
              ),
            ],
          ),

          // Autoridades Municipales
          _buildSectionGroup(
            context,
            title: 'Autoridades Municipales',
            titleColor: Colors.blue,
            children: [
              _buildInstitutionCard(
                context,
                name: 'Puebla Capital',
                description:
                    'Dirección de Protección Animal. Rescate en vía pública, reportes de maltrato, agresiones y bienestar.',
                icon: Icons.account_balance,
                phone: '222 233 4611',
                phone2: '222 432 0194',
                address:
                    'Zona Sur: Calle Mirasoles #14, Col. Bugambilias\nZona Norte: Calle 62 Poniente #525',
              ),
              _buildInstitutionCard(
                context,
                name: 'San Pedro Cholula',
                description:
                    'Departamento de Protección Animal. Recolección de animales enfermos o lastimados en vía pública.',
                icon: Icons.account_balance,
                phone: '222 777 2900',
                email: 'ecologia_medioambiente@cholula.gob.mx',
                address:
                    'Prolongación Miguel Alemán #2905, Barrio de la Magdalena',
              ),
              _buildInstitutionCard(
                context,
                name: 'San Andrés Cholula',
                description:
                    'Centro de Bienestar Animal. Atención de reportes ciudadanos.',
                icon: Icons.account_balance,
                address:
                    'Calle 3 Oriente #204, Col. Centro (Centro Administrativo CABS)',
              ),
              _buildInstitutionCard(
                context,
                name: 'Cuautlancingo',
                description:
                    'Centro de Bienestar Animal. Resguardo y bienestar animal municipal.',
                icon: Icons.account_balance,
                phone: '222 285 1362',
                phone2: '222 530 0220',
                address: 'Junta Auxiliar de San Lorenzo Almecatla',
              ),
            ],
          ),

          // Denuncias Penales
          _buildSectionGroup(
            context,
            title: 'Denuncias por Maltrato Animal (Penal)',
            titleColor: Colors.purple,
            children: [
              _buildInstitutionCard(
                context,
                name: 'Fiscalía General del Estado',
                description:
                    'Actos de crueldad animal tipificados como delito grave (lesiones severas o muerte intencionada).',
                icon: Icons.gavel,
                iconColor: Colors.purple,
                phone: '222 211 7800',
                email: 'fge@fiscalia.puebla.gob.mx',
                address: 'Blvd. Héroes del 5 de Mayo 31 Oriente s/n',
              ),
              _buildInstitutionCard(
                context,
                name: 'Instituto de Bienestar Animal (IBA)',
                description:
                    'Regulación a nivel estatal, asesoría, supervisión de resguardos y adopciones.',
                icon: Icons.health_and_safety,
                iconColor: Colors.teal,
                phone: '221 431 3246',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
