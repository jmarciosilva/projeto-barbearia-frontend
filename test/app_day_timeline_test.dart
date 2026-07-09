import 'package:clube_do_salao/models/appointment_model.dart';
import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppointmentModel _appointment({
  required int id,
  required String startsAt,
  required String status,
  required String serviceName,
}) {
  final starts = DateTime.parse(startsAt);
  return AppointmentModel(
    id: id,
    startsAt: starts,
    endsAt: starts.add(const Duration(minutes: 30)),
    status: status,
    clientName: 'Cliente',
    professionalName: 'Profissional',
    serviceName: serviceName,
  );
}

void main() {
  testWidgets(
    'AppDayTimeline lista horarios em ordem decrescente, do mais tarde para o mais cedo',
    (tester) async {
      final appointments = [
        _appointment(
          id: 1,
          startsAt: '2026-07-09T09:00:00',
          status: 'completed',
          serviceName: 'Corte cedo',
        ),
        _appointment(
          id: 2,
          startsAt: '2026-07-09T16:00:00',
          status: 'scheduled',
          serviceName: 'Corte tarde',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDayTimeline(
              appointments: appointments,
              onAppointmentTap: (_) {},
            ),
          ),
        ),
      );

      final sectionTitles = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where((text) => text == '09:00' || text == '16:00')
          .toList();

      // "16:00" (mais tarde) deve aparecer antes de "09:00" (mais cedo).
      expect(sectionTitles.indexOf('16:00'), lessThan(sectionTitles.indexOf('09:00')));
    },
  );

  testWidgets(
    'AppDayTimeline sinaliza visualmente atendimento concluido e cancelado',
    (tester) async {
      final appointments = [
        _appointment(
          id: 1,
          startsAt: '2026-07-09T09:00:00',
          status: 'completed',
          serviceName: 'Corte concluido',
        ),
        _appointment(
          id: 2,
          startsAt: '2026-07-09T10:00:00',
          status: 'canceled',
          serviceName: 'Corte cancelado',
        ),
        _appointment(
          id: 3,
          startsAt: '2026-07-09T11:00:00',
          status: 'scheduled',
          serviceName: 'Corte agendado',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDayTimeline(
              appointments: appointments,
              onAppointmentTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      expect(find.byIcon(Icons.event), findsOneWidget);
    },
  );
}
