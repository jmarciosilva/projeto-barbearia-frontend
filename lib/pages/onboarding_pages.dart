import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/support/business_types.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Onboarding do estabelecimento: cria o tenant e o usuario proprietario em
/// uma unica chamada (`POST /auth/register-owner`) e ja autentica, sem exigir
/// um segundo login logo em seguida.
class RegisterOwnerPage extends StatefulWidget {
  const RegisterOwnerPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<RegisterOwnerPage> createState() => _RegisterOwnerPageState();
}

class _RegisterOwnerPageState extends State<RegisterOwnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _tenantNameController = TextEditingController();
  final _tenantPhoneController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  String _businessType = businessTypeLabels.keys.first;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // AuthSession nao e um ListenableBuilder aqui: sem este listener, um erro
    // vindo da API (ex: e-mail duplicado) so aparece na tela apos algum
    // outro rebuild, deixando o usuario sem feedback ate voltar e reabrir.
    widget.authSession.addListener(_onAuthSessionChanged);
  }

  void _onAuthSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.authSession.removeListener(_onAuthSessionChanged);
    _tenantNameController.dispose();
    _tenantPhoneController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.authSession.registerOwner(
      tenantName: _tenantNameController.text.trim(),
      businessType: _businessType,
      tenantPhone: _tenantPhoneController.text.trim().isEmpty
          ? null
          : _tenantPhoneController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      ownerEmail: _ownerEmailController.text.trim(),
      ownerPassword: _ownerPasswordController.text,
    );

    if (!mounted) return;
    if (widget.authSession.isAuthenticated) {
      // `popUntil` (em vez de um unico `pop`) porque esta tela agora pode
      // ser aberta por baixo de `ChooseAccountTypePage`.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        widget.authSession.status == AuthStatus.authenticating;

    return AppScaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AppSectionTitle('Estabelecimento'),
              TextFormField(
                controller: _tenantNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do estabelecimento',
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Informe o nome do estabelecimento'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _businessType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo de negócio'),
                items: [
                  for (final entry in businessTypeLabels.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _businessType = value ?? _businessType),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tenantPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone do estabelecimento (opcional)',
                  hintText: 'Ex: 11912345678',
                ),
                keyboardType: TextInputType.phone,
                autofillHints: const [],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              const SizedBox(height: 24),
              const AppSectionTitle('Dados do proprietário'),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: 'Seu nome'),
                autofillHints: const [],
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerEmailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [],
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Informe o e-mail' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerPasswordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                autofillHints: const [],
                validator: (value) => (value == null || value.length < 8)
                    ? 'A senha precisa ter ao menos 8 caracteres'
                    : null,
              ),
              if (widget.authSession.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.authSession.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
