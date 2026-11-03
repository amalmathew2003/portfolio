import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_controller.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/credentials.dart';
import '../data/social_links.dart';

class CredentialsSection extends StatelessWidget {
  const CredentialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final lg = Bp.lg(context);
    final areaKey = app.key('credentials-area');

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(bottom: 12), child: LabelRow('MILESTONES & CERTIFICATIONS')),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text.rich(
            TextSpan(
              style: anton(Bp.clampVw(context, 40, 6, 96), h: 0.9),
              children: const [
                TextSpan(text: 'THE WORK.\n'),
                TextSpan(
                  text: 'THE RECOGNITION.',
                  style: TextStyle(color: C.accent),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Text(
              'Continuous technical expansion across mobile architecture, reactive programming, cloud platforms, and computer applications fundamentals.',
              style: inter(14, color: C.muted, h: 1.625),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: Hov(
            cursor: CursorMode.hover,
            onTap: () => launchUrl(Uri.parse(SocialLinks.cvDownloadUrl)),
            builder: (context, h) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: h ? op(C.accent, 0.1) : C.bg,
                border: Border.all(color: h ? C.accent : wh(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('[ VERIFIED CREDENTIALS ]', style: mono(10, color: C.accent, ls: 0.1)),
                      Icon(LucideIcons.arrowUpRight, size: 14, color: h ? C.accent : C.muted),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Download Amal Mathew's verified CV & credentials record.",
                    style: mono(12, color: h ? Colors.white : const Color(0xFF9A9A9A)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    final right = Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: wh(0.08))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < credentials.length; i++) _CredentialRow(item: credentials[i], index: i)],
      ),
    );

    return SectionBox(
      bg: C.bgAlt,
      child: Container(
        key: areaKey,
        child: lg
            ? Grid(
                columns: 12,
                gap: 64,
                items: [
                  GridItem(5, Sticky(top: 128, areaKey: areaKey, child: left)),
                  GridItem(7, right),
                ],
              )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [left, const SizedBox(height: 64), right]),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.item, required this.index});
  final Credential item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);
    return Reveal(
      whenVisible: true,
      dy: 20,
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: index * 80),
      child: Hov(
        builder: (context, h) => Stack(
          children: [
            AnimatedContainer(
              duration: kMs300,
              curve: kTw,
              padding: EdgeInsets.fromLTRB(h ? 16 : 0, md ? 32 : 24, 0, md ? 32 : 24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: wh(0.08))),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: ATxt(
                                  '0${index + 1} • ${item.subtitle}'.toUpperCase(),
                                  mono(10, color: h ? C.accent : const Color(0xFF777777), ls: 0.1),
                                ),
                              ),
                              Row(
                                children: [
                                  Flexible(child: Text(item.title.toUpperCase(), style: anton(md ? 24 : 20, ls: 0.05))),
                                  const SizedBox(width: 8),
                                  ATranslate(
                                    offset: Offset(h ? 2 : 0, h ? -2 : 0),
                                    child: AnimatedOpacity(
                                      opacity: h ? 1 : 0,
                                      duration: kMs150,
                                      child: const Icon(LucideIcons.arrowUpRight, size: 14, color: C.accent),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      AScale(
                        scale: h ? 1.05 : 1,
                        child: Text(item.year, style: anton(md ? 36 : 30, color: C.accent, h: 1.0)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // left red hover bar (scale-y 0 → 1)
            Positioned(
              left: 0,
              top: 0,
              bottom: 1,
              width: 2,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: h ? 1.0 : 0.0),
                duration: kMs300,
                curve: kTw,
                builder: (context, sc, child) => Transform.scale(scaleY: sc, child: child),
                child: const ColoredBox(color: C.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
