import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';

class CertCard extends StatelessWidget {
  const CertCard({
    super.key,
    required this.cert,
    required this.s,
    required this.ptCount,
    required this.enCount,
    required this.unseenPt,
    required this.unseenEn,
    required this.onStart,
    this.exam = false,
  });

  final String cert;
  final S s;
  final int ptCount;
  final int enCount;
  final int unseenPt;
  final int unseenEn;
  final void Function(String lang) onStart;
  final bool exam;

  @override
  Widget build(BuildContext context) {
    final palette = CertPalette.of(cert);
    final title = s.certTitle(cert);
    late final String badge;
    late final String full;
    late final String level;
    late final String focus;
    late final IconData icon;
    switch (cert) {
      case 'ccst':
        badge = s.entryLevel;
        full = s.ccstFull;
        level = s.ccstLevel;
        focus = s.ccstFocus;
        icon = Icons.headset_mic_outlined;
      case 'ccnp':
        badge = s.professional;
        full = s.ccnpFull;
        level = s.ccnpLevel;
        focus = s.ccnpFocus;
        icon = Icons.security_outlined;
      default:
        badge = s.associate;
        full = s.ccnaFull;
        level = s.ccnaLevel;
        focus = s.ccnaFocus;
        icon = Icons.lan_outlined;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: palette.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        full,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  icon,
                  size: 36,
                  color: palette.accent.withValues(alpha: 0.75),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFF334155))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    s.countsLine(ptCount, enCount),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFF334155))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$level  ·  $focus',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
            ),
            const SizedBox(height: 4),
            Text(
              '${s.unseenLine(unseenPt)} (PT)  ·  ${s.unseenLine(unseenEn)} (EN)',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.button,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: ptCount == 0 ? null : () => onStart('pt'),
                    child: Text(s.startPt(exam: exam)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: enCount == 0 ? null : () => onStart('en'),
                    child: Text(s.startEn(exam: exam)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
