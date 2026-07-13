import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/panic_home_controller.dart';
import 'configuration_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final PanicHomeController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PanicHomeController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(controller.requestStartupPermissions());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isEnabled = controller.protectionEnabled;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            centerTitle: true,
            toolbarHeight: 86,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'App de Pánico por Voz',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF132B4A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Modo de escucha y emergencia',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF5E6B80),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              const _BackgroundDecor(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  children: [
                    const SizedBox(height: 44),
                    _HeroCard(
                      enabled: isEnabled,
                      onToggle: (value) {
                        unawaited(controller.setProtectionEnabled(value));
                      },
                    ),
                    const SizedBox(height: 18),
                    if (controller.statusMessage != null) ...[
                      _NoticeBanner(message: controller.statusMessage!),
                      const SizedBox(height: 16),
                    ],
                    _ActionCard(
                      title: 'Configuración SOS',
                      description:
                          'Edita la frase de emergencia y los contactos en una pantalla aparte.',
                      icon: Icons.settings_rounded,
                      buttonLabel: 'Abrir configuración',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ConfigurationPage(controller: controller),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E4FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_rounded, color: Color(0xFF2F6CE5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF35507B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.enabled, required this.onToggle});

  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143B82), Color(0xFF2F6CE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33153C7D),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.hearing_rounded, color: Colors.white),
              ),
              const Spacer(),
              Switch.adaptive(
                value: enabled,
                onChanged: onToggle,
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.35),
                inactiveThumbColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Escucha SOS',
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            enabled
                ? 'La escucha está activa y lista para detectar la frase de emergencia.'
                : 'Activa la escucha para que la app permanezca atenta a la frase clave.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StatusPill(
                label: enabled ? 'Activa' : 'En pausa',
                icon: enabled
                    ? Icons.shield_rounded
                    : Icons.pause_circle_rounded,
              ),
              const SizedBox(width: 10),
              _StatusPill(
                label: 'Listo para prueba',
                icon: Icons.touch_app_rounded,
                muted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF2F6CE5)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF132B4A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E6B80),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.settings_rounded),
                  label: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: muted
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x112F6CE5),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x110C58D0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
