import 'package:clube_do_salao/core/app_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('confirma valor preparado com commit', () {
    final transaction = AppStateTransaction<String>('proprietario')
      ..stage('cliente');

    expect(transaction.commit(), 'cliente');
  });

  test('restaura valor original com rollback', () {
    final transaction = AppStateTransaction<String>('proprietario')
      ..stage('cliente');

    expect(transaction.rollback(), 'proprietario');
  });

  test('nao permite finalizar a mesma transacao duas vezes', () {
    final transaction = AppStateTransaction<String>('proprietario')
      ..stage('cliente');

    transaction.commit();

    expect(transaction.rollback, throwsStateError);
  });
}
