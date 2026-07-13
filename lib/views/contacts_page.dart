import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../controllers/panic_home_controller.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, required this.controller});

  final PanicHomeController controller;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  late final List<TextEditingController> _contactControllers;
  bool _isImporting = false;

  PanicHomeController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _contactControllers = controller.sosContacts
        .map((contact) => TextEditingController(text: contact))
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final contactController in _contactControllers) {
      contactController.dispose();
    }
    super.dispose();
  }

  Future<void> _importFromAgenda() async {
    final permissionStatus = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (!mounted) {
      return;
    }

    if (permissionStatus != PermissionStatus.granted &&
        permissionStatus != PermissionStatus.limited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas permiso de contactos para importar.'),
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );

      final agendaContacts = contacts
          .where((contact) => contact.phones.isNotEmpty)
          .map((contact) {
            final name = _contactName(contact);
            final phone = _contactPhone(contact);
            return _AgendaContact(name: name, phone: phone);
          })
          .where((contact) => contact.phone.isNotEmpty)
          .toList(growable: false);

      if (agendaContacts.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontraron contactos con teléfono.'),
          ),
        );
        return;
      }

      final selectedContacts = await showModalBottomSheet<List<_AgendaContact>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final sheetTheme = Theme.of(sheetContext);
          final selectedIndexes = <int>{};

          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0D8E7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.contacts_rounded,
                            color: Color(0xFF2F6CE5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Elige 3 contactos de la agenda',
                              style: sheetTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF132B4A),
                              ),
                            ),
                          ),
                          Text(
                            '${selectedIndexes.length}/3',
                            style: sheetTheme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF5E6B80),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: agendaContacts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final contact = agendaContacts[index];
                            final selected = selectedIndexes.contains(index);

                            return CheckboxListTile(
                              value: selected,
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    if (selectedIndexes.length >= 3) {
                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Solo puedes elegir 3 contactos.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    selectedIndexes.add(index);
                                  } else {
                                    selectedIndexes.remove(index);
                                  }
                                });
                              },
                              title: Text(contact.name),
                              subtitle: Text(contact.phone),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: selectedIndexes.length == 3
                                  ? () {
                                      final selectedList = selectedIndexes
                                          .map((index) => agendaContacts[index])
                                          .toList(growable: false);
                                      Navigator.of(
                                        sheetContext,
                                      ).pop(selectedList);
                                    }
                                  : null,
                              child: const Text('Usar 3 contactos'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (!mounted || selectedContacts == null) {
        return;
      }

      final formattedContacts = selectedContacts
          .take(3)
          .map((contact) => '${contact.name} - ${contact.phone}')
          .toList(growable: false);

      controller.replaceContacts(formattedContacts);
      for (
        var index = 0;
        index < formattedContacts.length && index < _contactControllers.length;
        index++
      ) {
        _contactControllers[index].text = formattedContacts[index];
      }
      setState(() {});
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  String _contactName(Contact contact) {
    final name = contact.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final firstName = contact.name?.first?.trim();
    final lastName = contact.name?.last?.trim();
    final combined = [
      firstName,
      lastName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return combined.isNotEmpty ? combined : 'Sin nombre';
  }

  String _contactPhone(Contact contact) {
    final phone = contact.phones.first;
    return (phone.normalizedNumber ?? phone.number).trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Contactos SOS'), toolbarHeight: 72),
      body: Stack(
        children: [
          const _BackgroundDecor(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              children: [
                const SizedBox(height: 32),
                Container(
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
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edita tus contactos de emergencia',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'La lista se guarda automáticamente mientras escribes.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                  onPressed: _isImporting ? null : _importFromAgenda,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.import_contacts_rounded),
                  label: Text(
                    _isImporting ? 'Importando...' : 'Importar desde agenda',
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Lista de contactos',
                  icon: Icons.contacts_rounded,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < _contactControllers.length;
                        index++
                      ) ...[
                        TextField(
                          controller: _contactControllers[index],
                          onChanged: (value) =>
                              controller.updateContact(index, value),
                          decoration: InputDecoration(
                            labelText: 'Contacto ${index + 1}',
                            hintText: 'Nombre - teléfono',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (index != _contactControllers.length - 1)
                          const SizedBox(height: 12),
                      ],
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
  }
}

class _AgendaContact {
  const _AgendaContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.icon,
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
