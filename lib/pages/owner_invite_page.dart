import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/models/tenant_model.dart';
import 'package:clube_do_salao/services/onboarding_checklist_storage.dart';
import 'package:clube_do_salao/services/tenant_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show Share;

/// URL usada para embrulhar o codigo de convite em link/QR. Sem app
/// instalado, o link ainda mostra o codigo, que o cliente pode digitar
/// manualmente ao abrir o app pela loja.
const _inviteLinkBase = 'https://clubedosalao.app/c';

/// Tela do dono para ver, compartilhar e regenerar o codigo de convite do
/// proprio estabelecimento (spec: onboarding e autocadastro do cliente).
class InviteCodePage extends StatefulWidget {
  const InviteCodePage({
    super.key,
    required this.tenantRepository,
    required this.checklistStorage,
    required this.initialTenant,
  });

  final TenantRepository tenantRepository;
  final OnboardingChecklistStorage checklistStorage;
  final TenantModel initialTenant;

  @override
  State<InviteCodePage> createState() => _InviteCodePageState();
}

class _InviteCodePageState extends State<InviteCodePage> {
  late TenantModel _tenant = widget.initialTenant;
  bool _isRegenerating = false;
  String? _errorMessage;

  String get _inviteLink => '$_inviteLinkBase/${_tenant.inviteCode}';

  Future<void> _share() async {
    await Share.share(
      'Olá! Use este link para se cadastrar no ${_tenant.name} pelo '
      'app Clube do Salão: $_inviteLink\n\nOu digite o código '
      '${_tenant.inviteCode} na tela de cadastro do app.',
    );
    await widget.checklistStorage.markInviteShared();
  }

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gerar novo código?'),
        content: Text(
          'O código atual (${_tenant.inviteCode}) deixa de funcionar. '
          'Quem já tiver o link/QR antigo não vai conseguir mais se cadastrar por ele.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Gerar novo código'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRegenerating = true;
      _errorMessage = null;
    });

    try {
      final updated = await widget.tenantRepository.regenerateInviteCode();
      setState(() => _tenant = updated);
    } on AppException catch (error) {
      setState(() => _errorMessage = error.userMessage);
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: AppBar(title: const Text('Convidar clientes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Compartilhe este QR code ou link com seus clientes. Quem abrir '
              'já se cadastra direto vinculado ao ${_tenant.name}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: QrImageView(
                  data: _inviteLink,
                  size: 200,
                  key: ValueKey(_tenant.inviteCode),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Código: ${_tenant.inviteCode}',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar convite'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isRegenerating ? null : _regenerate,
              icon: _isRegenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Gerar novo código'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}
