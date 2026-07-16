import 'package:flutter/material.dart';

class UrgencyFilterMenu extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const UrgencyFilterMenu({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.9,
        ), // Utilizando sintaxis optimizada de Flutter 3.44+
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip('Todos', 'todos', Colors.blue),
          const SizedBox(height: 8),
          _buildFilterChip('Alta', 'alta', Colors.red),
          const SizedBox(height: 8),
          _buildFilterChip('Media', 'media', Colors.orange),
          const SizedBox(height: 8),
          _buildFilterChip('Baja', 'baja', Colors.amber),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final bool isSelected = currentFilter == value;
    return ChoiceChip(
      label: SizedBox(
        width: 46,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.transparent,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      onSelected: (bool selected) {
        if (selected) {
          onFilterChanged(value);
        }
      },
    );
  }
}
