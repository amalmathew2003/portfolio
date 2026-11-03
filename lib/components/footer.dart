import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_controller.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/social_links.dart';
import 'navbar.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);
    final pad = Bp.pad(context);

    final left = Column(
      crossAxisAlignment: md ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Logo(onTap: app.scrollToTop),
        const SizedBox(height: 4),
        Text(
          'FLUTTER DEVELOPER • KERALA, INDIA',
          textAlign: md ? TextAlign.left : TextAlign.center,
          style: mono(11, color: const Color(0xFF777777), ls: 0.1),
        ),
      ],
    );

    final center = Text(
      '© ${DateTime.now().year} AMAL MATHEW. BUILT WITH FLUTTER MINDSET.',
      textAlign: TextAlign.center,
      style: mono(12, color: const Color(0xFF777777), ls: 0.05),
    );

    final right = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        const _SocialBox(icon: LucideIcons.gitBranch, url: SocialLinks.githubUrl),
        const _SocialBox(icon: LucideIcons.externalLink, url: SocialLinks.linkedInUrl),
        const _SocialBox(icon: LucideIcons.mail, url: SocialLinks.emailMailto),
        const _TopButton(),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 48),
      decoration: BoxDecoration(
        color: C.bg,
        border: Border(top: BorderSide(color: wh(0.08))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: md
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    left,
                    Flexible(
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: center),
                    ),
                    right,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [left, const SizedBox(height: 32), center, const SizedBox(height: 32), right],
                ),
        ),
      ),
    );
  }
}

class _SocialBox extends StatelessWidget {
  const _SocialBox({required this.icon, required this.url});
  final IconData icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Hov(
      cursor: CursorMode.hover,
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      builder: (context, h) => AnimatedContainer(
        duration: kMs150,
        curve: kTw,
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: h ? C.accent : wh(0.08))),
        child: AIcon(icon, 16, h ? C.accent : C.muted),
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton();

  @override
  Widget build(BuildContext context) {
    return Hov(
      cursor: CursorMode.hover,
      onTap: app.scrollToTop,
      builder: (context, h) => AnimatedContainer(
        duration: kMs150,
        curve: kTw,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: h ? C.accent : wh(0.12))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ATxt('TOP', mono(12, color: h ? C.accent : Colors.white, ls: 0.05)),
            const SizedBox(width: 6),
            ATranslate(
              offset: Offset(0, h ? -2 : 0),
              child: AIcon(LucideIcons.arrowUp, 13, h ? C.accent : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
