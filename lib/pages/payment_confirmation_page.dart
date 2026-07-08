import 'package:clube_do_salao/core/app_exception.dart';
import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/models/payment_model.dart';
import 'package:clube_do_salao/services/payments_repository.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

/// Confirmacao de um pagamento manual, chamando a API.
///
/// Retorna `true` via [Navigator.pop] quando o pagamento e confirmado, para
/// que a tela de origem possa atualizar sua lista. Widget generico por
/// papel (so quem tem `role:owner` consegue de fato confirmar no backend),
/// reaproveitado tanto pela lista de pagamentos pendentes quanto pela tela
/// de conclusao de atendimento.
class PaymentConfirmationPage extends StatefulWidget {
  const PaymentConfirmationPage({
    super.key,
    required this.paymentsRepository,
    required this.payment,
  });

  final PaymentsRepository paymentsRepository;
  final PaymentModel payment;

  @override
  State<PaymentConfirmationPage> createState() =>
      _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> {
  bool _confirmed = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _selectedMethod = 'pix';

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.paymentsRepository.markPaid(
        widget.payment.id,
        method: _selectedMethod,
      );

      if (!mounted) return;
      setState(() {
        _confirmed = result.status == 'paid';
        _isSaving = false;
      });

      if (result.status != 'paid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento registrado como fiado.')),
        );
        Navigator.of(context).pop(false);
      }
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.userMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final selectedLabel = _paymentMethodLabel(_selectedMethod);

    return AppScaffold(
      appBar: AppBar(title: const Text('Confirmar pagamento')),
      body: _confirmed
          ? AppMockSuccessPanel(
              title: 'Pagamento confirmado',
              message:
                  '${formatCents(payment.amountCents)} de ${payment.clientName ?? 'cliente'} via $selectedLabel.',
              buttonLabel: 'Concluir',
              onDone: () => Navigator.of(context).pop(true),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Cliente'),
                        trailing: Text(payment.clientName ?? '-'),
                      ),
                      if (payment.serviceName != null)
                        ListTile(
                          title: const Text('Serviço'),
                          trailing: Text(payment.serviceName!),
                        ),
                      ListTile(
                        title: const Text('Valor'),
                        trailing: Text(formatCents(payment.amountCents)),
                      ),
                      ListTile(
                        title: const Text('Forma de pagamento'),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final method in _manualPaymentMethods)
                                ChoiceChip(
                                  label: Text(_paymentMethodLabel(method)),
                                  selected: _selectedMethod == method,
                                  onSelected: _isSaving
                                      ? null
                                      : (_) {
                                          setState(
                                            () => _selectedMethod = method,
                                          );
                                        },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _confirm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar pagamento'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],
            ),
    );
  }

  static const _manualPaymentMethods = [
    'pix',
    'credit_card',
    'debit_card',
    'cash',
    'fiado',
  ];

  String _paymentMethodLabel(String method) => switch (method) {
    'pix' => 'PIX',
    'credit_card' => 'Cartão crédito',
    'debit_card' => 'Cartão débito',
    'cash' => 'Dinheiro',
    'fiado' => 'Fiado',
    _ => method,
  };
}
