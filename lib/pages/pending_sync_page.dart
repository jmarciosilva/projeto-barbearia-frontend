import 'package:clube_do_salao/core/formatting.dart';
import 'package:clube_do_salao/services/offline/mutation_queue.dart';
import 'package:clube_do_salao/services/offline/queued_mutation.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

/// Fila de mutacoes ainda nao sincronizadas com o servidor — pendentes
/// (aguardando conexao) ou com falha permanente (rejeitadas pelo servidor
/// numa tentativa de reenvio, precisam de acao manual). Acessivel pelo
/// indicador na barra superior, visivel pros 4 papeis (mesmo `AppScaffold`
/// compartilhado).
class PendingSyncPage extends StatelessWidget {
  const PendingSyncPage({super.key, required this.mutationQueue});

  final MutationQueue mutationQueue;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Sincronização pendente')),
      body: ListenableBuilder(
        listenable: mutationQueue,
        builder: (context, _) {
          final items = mutationQueue.items;

          if (items.isEmpty) {
            return const Center(child: Text('Tudo sincronizado.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in items)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      item.status == QueuedMutationStatus.failed
                          ? Icons.error_outline
                          : Icons.cloud_upload_outlined,
                      color: item.status == QueuedMutationStatus.failed
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    title: Text(item.description),
                    subtitle: Text(
                      item.status == QueuedMutationStatus.failed
                          ? (item.lastError ?? 'Falhou ao sincronizar.')
                          : 'Aguardando conexão desde ${formatDateTime(item.createdAt)}',
                    ),
                    trailing: item.status == QueuedMutationStatus.failed
                        ? IconButton(
                            tooltip: 'Descartar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => mutationQueue.discard(item.id),
                          )
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
