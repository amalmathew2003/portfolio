import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/floating_cursors.dart';
import '../core/app_controller.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/social_links.dart';

class _Channel {
  const _Channel(this.icon, this.label, this.value, this.href, this.copyable);
  final IconData icon;
  final String label, value, href;
  final bool copyable;
}

const _channels = <_Channel>[
  _Channel(LucideIcons.mail, 'EMAIL DIRECT', SocialLinks.email, SocialLinks.emailMailto, true),
  _Channel(LucideIcons.gitBranch, 'GITHUB PROFILE', SocialLinks.githubDisplay, SocialLinks.githubUrl, false),
  _Channel(
    LucideIcons.externalLink,
    'LINKEDIN NETWORK',
    SocialLinks.linkedInDisplay,
    SocialLinks.linkedInUrl,
    false,
  ),
];

Future<void> _open(String href) => launchUrl(
  Uri.parse(href),
  mode: href.startsWith('http') ? LaunchMode.externalApplication : LaunchMode.platformDefault,
);

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final md = Bp.md(context);
    final lg = Bp.lg(context);

    final left = Container(
      width: double.infinity,
      padding: EdgeInsets.all(md ? 48 : 32),
      decoration: BoxDecoration(
        color: C.bgAlt,
        border: Border.all(color: wh(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text('DIRECT CHANNELS', style: sectionLabel()),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: wh(0.06))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final c in _channels) _ChannelRow(channel: c)],
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 32),
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: wh(0.06))),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 13, color: C.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'KERALA, INDIA • OPEN TO GLOBAL REMOTE OPPORTUNITIES',
                    style: mono(12, color: const Color(0xFF777777)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final right = Container(
      width: double.infinity,
      padding: EdgeInsets.all(md ? 48 : 32),
      decoration: const BoxDecoration(
        color: C.accent,
        boxShadow: [BoxShadow(color: Color.fromRGBO(230, 57, 70, 0.3), blurRadius: 40, offset: Offset(0, 12))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('CREATIVE DIRECTION', style: mono(12, color: wh(0.7), ls: 0.25)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('MAKE IT\nFEEL REAL.', style: anton(md ? 48 : 36, ls: -0.025, h: 0.92)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: Text(
                    "Whether you're bootstrapping a brand-new cross-platform MVP or scaling an existing Flutter codebase with clean architecture, let's ship something memorable.",
                    style: inter(14, color: wh(0.8), h: 1.625),
                  ),
                ),
              ),
            ],
          ),
          Hov(
            cursor: CursorMode.hover,
            onTap: () => _open(SocialLinks.emailSubject),
            builder: (context, h) => AnimatedContainer(
              duration: kMs300,
              curve: kTw,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: h ? Colors.white : C.bg,
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 25, offset: Offset(0, 20), spreadRadius: -5),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ATxt('SEND A MESSAGE', anton(18, color: h ? Colors.black : Colors.white, ls: 0.05), duration: kMs300),
                  const SizedBox(width: 12),
                  AIcon(LucideIcons.send, 16, h ? Colors.black : Colors.white, duration: kMs300),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return SectionBox(
      bg: C.bg,
      background: const [FloatingCursors()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(bottom: 12), child: LabelRow('05 / START A CONVERSATION')),
                Text.rich(
                  TextSpan(
                    style: anton(Bp.clampVw(context, 48, 9, 144), ls: -0.01, h: 0.9),
                    children: const [
                      TextSpan(text: "LET'S WORK\n"),
                      TextSpan(
                        text: 'TOGETHER.',
                        style: TextStyle(color: C.accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          lg
              ? Grid(columns: 12, gap: 40, stretch: true, items: [GridItem(7, left), GridItem(5, right)])
              : Column(children: [left, const SizedBox(height: 40), right]),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatefulWidget {
  const _ChannelRow({required this.channel});
  final _Channel channel;

  @override
  State<_ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<_ChannelRow> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(const ClipboardData(text: SocialLinks.email));
    setState(() => _copied = true);
    app.showCopiedToast();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.channel;
    final sm = Bp.sm(context);
    final md = Bp.md(context);

    return Hov(
      builder: (context, h) {
        final info = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: kMs150,
              curve: kTw,
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: h ? C.accent : wh(0.08))),
              child: Icon(c.icon, size: 16, color: C.accent),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(c.label, style: mono(10, color: const Color(0xFF777777), ls: 0.1)),
                  ),
                  Hov(
                    cursor: CursorMode.hover,
                    onTap: () => _open(c.href),
                    builder: (context, lh) =>
                        ATxt(c.value.toUpperCase(), anton(md ? 20 : 18, color: lh ? C.accent : Colors.white, ls: 0.05)),
                  ),
                ],
              ),
            ),
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.copyable) ...[
              Hov(
                cursor: CursorMode.hover,
                onTap: _copy,
                builder: (context, bh) => AnimatedContainer(
                  duration: kMs150,
                  curve: kTw,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(border: Border.all(color: bh ? Colors.white : wh(0.12))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _copied
                        ? [
                            const Icon(LucideIcons.check, size: 12, color: C.accent),
                            const SizedBox(width: 6),
                            Text('COPIED', style: mono(12, color: C.accent, ls: 0.05)),
                          ]
                        : [
                            const Icon(LucideIcons.copy, size: 12, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('COPY', style: mono(12, ls: 0.05)),
                          ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Hov(
              cursor: CursorMode.hover,
              onTap: () => _open(c.href),
              builder: (context, bh) => AnimatedContainer(
                duration: kMs150,
                curve: kTw,
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: h ? C.accent : Colors.transparent,
                  border: Border.all(color: h ? C.accent : wh(0.08)),
                ),
                child: ATranslate(
                  offset: Offset(h ? 2 : 0, 0),
                  child: AIcon(LucideIcons.arrowRight, 14, h ? Colors.white : C.muted),
                ),
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: wh(0.06))),
          ),
          child: sm
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: info),
                    const SizedBox(width: 16),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 16), actions],
                ),
        );
      },
    );
  }
}
