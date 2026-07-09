/// Formata um valor em centavos como moeda brasileira, ex: 9990 -> "R$ 99,90".
String formatCents(int? cents) {
  if (cents == null) return 'R\$ 0,00';

  final reais = cents ~/ 100;
  final centavos = (cents % 100).toString().padLeft(2, '0');

  return 'R\$ $reais,$centavos';
}

/// Converte um preco digitado ("99,90" ou "99.90") para centavos (9990).
int parsePriceToCents(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  final value = double.tryParse(normalized) ?? 0;

  return (value * 100).round();
}

/// Formata um horario como "HH:mm" a partir de um [DateTime].
String formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

/// Formata data e hora como "dd/mm/yyyy HH:mm" a partir de um [DateTime].
String formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');

  return '$day/$month/${dateTime.year} ${formatTime(dateTime)}';
}

const _monthNames = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// Formata mes e ano por extenso, ex: "julho de 2026" — usado em "Cliente
/// desde" para leitura rapida sem exigir interpretar uma data numerica.
String formatMonthYear(DateTime dateTime) {
  return '${_monthNames[dateTime.month - 1]} de ${dateTime.year}';
}

/// Formata uma duracao como "40 min" ou "1h 30min".
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '${hours}h';

  return '${hours}h ${minutes}min';
}
