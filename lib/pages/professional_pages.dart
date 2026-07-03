import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

class ProfessionalHomePage extends StatelessWidget {
  const ProfessionalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScheduleList(
      title: 'Atendimentos de hoje',
      items: const [
        AppScheduleItem(
          '09:00',
          'Corte masculino',
          'Carlos Mendes',
          notes: 'Cliente prefere maquina numero 2 nas laterais.',
        ),
        AppScheduleItem('10:30', 'Barba completa', 'Joao Ribeiro'),
        AppScheduleItem('14:00', 'Sobrancelha', 'Marina Alves'),
      ],
      onItemTap: (item) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AppointmentDetailPage(item: item)),
      ),
    );
  }
}

class ProfessionalProfilePage extends StatelessWidget {
  const ProfessionalProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProfileSummary(
      title: 'Perfil profissional',
      rows: const [
        AppInfoRow('Especialidade', 'Cortes e barba'),
        AppInfoRow('Comissao', '40%'),
        AppInfoRow('Atendimentos no mes', '86'),
      ],
      footer: [
        const SizedBox(height: 16),
        AppActionTile(
          icon: Icons.edit,
          title: 'Editar perfil',
          subtitle: 'Atualize especialidade, comissao e dados de contato.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EditProfessionalProfilePage(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Detalhe mockado de um atendimento da agenda, com acao para concluir.
class AppointmentDetailPage extends StatefulWidget {
  const AppointmentDetailPage({super.key, required this.item});

  final AppScheduleItem item;

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AppScaffold(
      appBar: AppBar(title: const Text('Detalhe do atendimento')),
      body: _completed
          ? AppMockSuccessPanel(
              title: 'Atendimento concluido',
              message: '${item.service} de ${item.client} foi marcado como concluido.',
              buttonLabel: 'Voltar para a agenda',
              onDone: () => Navigator.of(context).pop(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Cliente'),
                        trailing: Text(item.client),
                      ),
                      ListTile(
                        title: const Text('Servico'),
                        trailing: Text(item.service),
                      ),
                      ListTile(
                        title: const Text('Horario'),
                        trailing: Text(item.time),
                      ),
                      ListTile(
                        title: const Text('Duracao'),
                        trailing: Text(item.duration),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AppSectionTitle('Observacoes'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(item.notes),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => setState(() => _completed = true),
                  icon: const Icon(Icons.check),
                  label: const Text('Concluir atendimento'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Formulario mockado de edicao do perfil profissional.
class EditProfessionalProfilePage extends StatefulWidget {
  const EditProfessionalProfilePage({super.key});

  @override
  State<EditProfessionalProfilePage> createState() =>
      _EditProfessionalProfilePageState();
}

class _EditProfessionalProfilePageState
    extends State<EditProfessionalProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _specialtyController = TextEditingController(text: 'Cortes e barba');
  final _commissionController = TextEditingController(text: '40');

  @override
  void dispose() {
    _specialtyController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado (mock).')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _specialtyController,
              decoration: const InputDecoration(labelText: 'Especialidade'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe a especialidade' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commissionController,
              decoration: const InputDecoration(labelText: 'Comissao (%)'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Informe a comissao' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
