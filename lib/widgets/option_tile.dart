import 'package:flutter/material.dart';

import '../theme.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
    this.revealed = false,
    this.isCorrect = false,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool revealed;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    Color border = const Color(0xFF334155);
    Color fill = const Color(0xFF0B1220);
    Color badge = const Color(0xFF334155);
    Color badgeFg = const Color(0xFF94A3B8);

    if (revealed && isCorrect) {
      border = const Color(0xFF34D399);
      fill = const Color(0x1A34D399);
      badge = const Color(0xFF059669);
      badgeFg = Colors.white;
    } else if (revealed && selected && !isCorrect) {
      border = const Color(0xFFF87171);
      fill = const Color(0x1AF87171);
      badge = const Color(0xFFDC2626);
      badgeFg = Colors.white;
    } else if (selected) {
      border = ciscoBlue;
      fill = const Color(0x330A66C2);
      badge = ciscoBlue;
      badgeFg = Colors.white;
    }

    final letter = String.fromCharCode(65 + index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: selected ? 2 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badge,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: badgeFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
