import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/services/auth_session.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

/// Tela para o usuario logado trocar o proprio e-mail e/ou senha de login
/// (`PATCH /me/credentials`), disponivel para qualquer papel. Exige a senha
/// atual antes de aplicar a mudanca.
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  late final _emailController = TextEditingController(
    text: widget.authSession.user?.email,
  );
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureNewPasswordConfirm = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final newPassword = _newPasswordController.text;

    try {
      await widget.authSession.updateCredentials(
        currentPassword: _currentPasswordController.text,
        email: _emailController.text.trim(),
        password: newPassword.isEmpty ? null : newPassword,
        passwordConfirmation: newPassword.isEmpty
            ? null
            : _newPasswordConfirmController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dados de acesso atualizados.')));
      Navigator.of(context).pop();
    } on AppException catch (error) {
      setState(() => _errorMessage = error.userMessage);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Meus dados de acesso')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Confirme sua senha atual para alterar o e-mail e/ou a senha de acesso ao app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    ),
                  ),
                ),
                obscureText: _obscureCurrentPassword,
                autofillHints: const [],
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Informe a senha atual'
                    : null,
              ),
              const SizedBox(height: 24),
              const AppSectionTitle('Novo e-mail'),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [],
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Informe o e-mail' : null,
              ),
              const SizedBox(height: 24),
              const AppSectionTitle('Nova senha (opcional)'),
              Text(
                'Deixe em branco para manter a senha atual.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                  ),
                ),
                obscureText: _obscureNewPassword,
                autofillHints: const [],
                validator: (value) => (value != null && value.isNotEmpty && value.length < 8)
                    ? 'A senha precisa ter ao menos 8 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordConfirmController,
                decoration: InputDecoration(
                  labelText: 'Confirmar nova senha',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPasswordConfirm
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                      () => _obscureNewPasswordConfirm =
                          !_obscureNewPasswordConfirm,
                    ),
                  ),
                ),
                obscureText: _obscureNewPasswordConfirm,
                autofillHints: const [],
                validator: (value) =>
                    _newPasswordController.text.isNotEmpty &&
                        value != _newPasswordController.text
                    ? 'As senhas não coincidem'
                    : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
