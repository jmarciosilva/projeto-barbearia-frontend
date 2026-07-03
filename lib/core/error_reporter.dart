import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_exception.dart';

/// Centraliza o tratamento de excecoes nao capturadas pelo app.
///
/// Enquanto nao houver servico externo de observabilidade, registramos os erros
/// no console de desenvolvimento e mostramos uma tela segura para o usuario.
class AppErrorReporter {
  const AppErrorReporter._();

  static void configure() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      report(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      report(error, stackTrace);

      return true;
    };

    ErrorWidget.builder = (_) => const AppCrashView();
  }

  static void reportZoneError(Object error, StackTrace stackTrace) {
    report(error, stackTrace);
  }

  static void report(Object error, StackTrace? stackTrace) {
    final message = switch (error) {
      AppException appError => appError.toString(),
      _ => error.toString(),
    };

    debugPrint('Erro capturado pelo aplicativo: $message');

    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

/// Tela de contingencia para falhas inesperadas de renderizacao.
class AppCrashView extends StatelessWidget {
  const AppCrashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nao foi possivel carregar esta tela. Tente novamente em instantes.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
