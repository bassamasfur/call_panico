import 'package:flutter/material.dart';

import '../controllers/panic_home_controller.dart';
import 'contacts_page.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key, required this.controller});

  final PanicHomeController controller;

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  late final TextEditingController _phraseController;
  late final TextEditingController _extraPhraseController;

  PanicHomeController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _phraseController = TextEditingController(text: controller.emergencyPhrase);
    _extraPhraseController = TextEditingController();
  }

  @override
  void dispose() {
    _phraseController.dispose();
    _extraPhraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Configuración SOS'),
            toolbarHeight: 72,
          ),
          body: Stack(
            children: [
              const _BackgroundDecor(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  children: [
                    const SizedBox(height: 32),
                    _HeaderCard(
                      title: 'Ajustes de emergencia',
                      description:
                          'Aquí editas la frase de emergencia, administras contactos y pruebas la escucha real.',
                    ),
                    const SizedBox(height: 18),
                    if (controller.statusMessage != null) ...[
                      _NoticeBanner(message: controller.statusMessage!),
                      const SizedBox(height: 16),
                    ],
                    _SectionCard(
                      title: 'Frases de activación',
                      icon: Icons.record_voice_over_rounded,
                      child: TextField(
                        controller: _phraseController,
                        onChanged: controller.updateEmergencyPhrase,
                        decoration: const InputDecoration(
                          labelText: 'Frase principal',
                          hintText: 'Escribe la frase principal de activación',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Agregar otra frase',
                      icon: Icons.add_comment_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _extraPhraseController,
                            decoration: const InputDecoration(
                              labelText: 'Frase alternativa',
                              hintText: 'Ejemplo: necesito ayuda',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              controller.addEmergencyPhrase(
                                _extraPhraseController.text,
                              );
                              _extraPhraseController.clear();
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Guardar frase'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'La primera frase es la principal. Puedes guardar varias alternativas para que el sistema reconozca cualquiera de ellas.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6F7E95),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Frases guardadas',
                      icon: Icons.local_offer_rounded,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (
                            var index = 0;
                            index < controller.emergencyPhrases.length;
                            index++
                          )
                            InputChip(
                              label: Text(controller.emergencyPhrases[index]),
                              onDeleted: controller.emergencyPhrases.length == 1
                                  ? null
                                  : () =>
                                        controller.removeEmergencyPhrase(index),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Número fijo de prueba',
                      icon: Icons.phone_rounded,
                      child: Text(
                        '+56959178040 · El SMS se enviará a este número con el texto "necesito ayuda".',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5E6B80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Contactos SOS',
                      icon: Icons.groups_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edita los contactos en su propia pantalla.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF5E6B80),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Estos contactos son de respaldo; el destino fijo de prueba es el número de arriba.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6F7E95),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ContactsPage(controller: controller),
                                ),
                              );
                            },
                            icon: const Icon(Icons.contacts_rounded),
                            label: const Text('Editar contactos'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Prueba de voz real',
                      icon: Icons.mic_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'La app escucha unos segundos y comprueba si lo dicho coincide con la frase configurada.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () async {
                              await controller.testVoiceDetection();
                            },
                            icon: const Icon(Icons.hearing_rounded),
                            label: const Text('Probar escucha real'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Listo'),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF2F6CE5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF132B4A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
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

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -50,
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
            bottom: 90,
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
