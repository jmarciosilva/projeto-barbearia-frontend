import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Liga/desliga a simulacao de "sem conexao" de `buildFakeBackend` durante
/// um teste (mutavel, pra dar pra simular a conexao caindo/voltando no meio
/// de um fluxo — ex: logar online, depois ficar offline pra testar a fila
/// de sincronizacao, depois voltar online pra testar o flush automatico).
class FakeConnectivityToggle {
  bool offline = false;
}

/// Simula as respostas do backend Laravel (`backend/docs/api.md`) o
/// suficiente para exercitar login e os fluxos dos 3 perfis em testes de
/// widget, sem precisar de uma API real rodando.
///
/// O "token" retornado no login e literalmente o papel do usuario
/// (`owner-token`, `professional-token`, `customer-token`), o que permite
/// ao `GET /me` simulado devolver o usuario certo sem estado adicional.
http.Client buildFakeBackend({
  bool founderTenant = false,
  bool trialTenant = false,
  FakeConnectivityToggle? offlineToggle,
}) {
  final adminTenants = _buildAdminTenantsJson();

  return MockClient((request) async {
    if (offlineToggle?.offline ?? false) {
      throw const SocketException('Sem conexao (simulado em teste).');
    }

    final path = request.url.path;
    final method = request.method;

    if (method == 'POST' && path.endsWith('/auth/register-owner')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final owner = body['owner'] as Map<String, dynamic>;

      return _jsonResponse(201, {
        'token': 'owner-token',
        'user': {..._ownerJson, 'name': owner['name'], 'email': owner['email']},
      });
    }

    if (method == 'POST' && path.endsWith('/auth/register-client')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final client = body['client'] as Map<String, dynamic>;
      final hasInvite = (body['invite_code'] as String?)?.isNotEmpty ?? false;
      final hasTenantId = body['tenant_id'] != null;

      if (!hasInvite && !hasTenantId) {
        return _jsonResponse(422, {
          'message': 'Informe um codigo de convite ou escolha um estabelecimento.',
          'error': 'validation_error',
          'errors': {
            'invite_code': ['Informe um codigo de convite ou escolha um estabelecimento.'],
          },
        });
      }

      if (hasInvite && body['invite_code'] != 'AB3XQ9') {
        return _jsonResponse(404, {
          'message': 'Registro nao encontrado.',
          'error': 'not_found',
        });
      }

      return _jsonResponse(201, {
        'token': 'customer-token',
        'user': {..._customerJson, 'name': client['name'], 'email': client['email']},
        'client': {'id': 5, 'name': client['name']},
        'tenant': {
          'id': 1,
          'name': 'Clube do Salao Demo',
          'business_type': 'barbershop',
          'city': 'Sao Paulo',
        },
      });
    }

    if (method == 'GET' && path.contains('/tenants/by-invite-code/')) {
      final code = path.split('/').last;

      if (code != 'AB3XQ9') {
        return _jsonResponse(404, {
          'message': 'Registro nao encontrado.',
          'error': 'not_found',
        });
      }

      return _jsonResponse(200, {
        'id': 1,
        'name': 'Clube do Salao Demo',
        'business_type': 'barbershop',
        'city': 'Sao Paulo',
      });
    }

    if (method == 'GET' && path.endsWith('/tenants/directory')) {
      return _jsonResponse(200, [
        {
          'id': 1,
          'name': 'Clube do Salao Demo',
          'business_type': 'barbershop',
          'city': 'Sao Paulo',
        },
        {
          'id': 2,
          'name': 'Barbearia do Ze',
          'business_type': 'barbershop',
          'city': 'Campinas',
        },
      ]);
    }

    if (method == 'POST' && path.endsWith('/tenant/invite-code/regenerate')) {
      return _jsonResponse(200, {..._tenantJson, 'invite_code': 'ZZ9YY8'});
    }

    if (method == 'POST' && path.endsWith('/auth/login')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final email = body['email'] as String;

      return switch (email) {
        'owner@clubedosalao.com' => _jsonResponse(200, {
          'token': 'owner-token',
          'user': _ownerJson,
        }),
        'ana.souza@clubedosalao.com' => _jsonResponse(200, {
          'token': 'professional-token',
          'user': _professionalJson,
        }),
        'carlos.mendes@clubedosalao.com' => _jsonResponse(200, {
          'token': 'customer-token',
          'user': _customerJson,
        }),
        'admin@clubedosalao.com' => _jsonResponse(200, {
          'token': 'admin-token',
          'user': _adminJson,
        }),
        _ => _jsonResponse(422, {
          'message': 'Dados invalidos.',
          'error': 'validation_error',
          'errors': {
            'email': ['Credenciais invalidas.'],
          },
        }),
      };
    }

    if (method == 'GET' && path.endsWith('/me')) {
      final user = _userForToken(request);
      if (user == null) return _jsonResponse(401, _unauthenticated);

      return _jsonResponse(200, user);
    }

    if (method == 'PATCH' && path.endsWith('/me/credentials')) {
      final user = _userForToken(request);
      if (user == null) return _jsonResponse(401, _unauthenticated);

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['current_password'] != 'demo12345') {
        return _jsonResponse(422, {
          'message': 'Dados invalidos.',
          'error': 'validation_error',
          'errors': {
            'current_password': ['Senha atual incorreta.'],
          },
        });
      }

      return _jsonResponse(200, {
        ...user,
        if (body['email'] != null) 'email': body['email'],
      });
    }

    if (method == 'POST' && path.endsWith('/auth/logout')) {
      return http.Response('', 204);
    }

    if (method == 'GET' && path.endsWith('/admin/dashboard')) {
      final founderCount = adminTenants
          .where((tenant) => tenant['is_founder'] == true)
          .length;
      final activeCount = adminTenants
          .where(
            (tenant) =>
                (tenant['saas_subscription'] as Map)['status'] == 'active',
          )
          .length;
      final trialCount = adminTenants
          .where(
            (tenant) =>
                (tenant['saas_subscription'] as Map)['effective_status'] ==
                'trial',
          )
          .length;
      final expiredCount = adminTenants
          .where(
            (tenant) =>
                (tenant['saas_subscription'] as Map)['effective_status'] ==
                'trial_expired',
          )
          .length;
      final projectedRevenueCents = adminTenants
          .where(
            (tenant) =>
                (tenant['saas_subscription'] as Map)['status'] == 'active',
          )
          .fold<int>(
            0,
            (sum, tenant) =>
                sum +
                ((tenant['saas_subscription'] as Map)['price_cents'] as int),
          );

      return _jsonResponse(200, {
        'total_tenants': adminTenants.length,
        'active_tenants': activeCount,
        'trial_tenants': trialCount,
        'expired_tenants': expiredCount,
        'founder_tenants': founderCount,
        'projected_revenue_cents': projectedRevenueCents,
        'total_users': 12,
      });
    }

    if (method == 'GET' && path.endsWith('/admin/tenants')) {
      return _jsonResponse(200, adminTenants);
    }

    if (method == 'PATCH' &&
        RegExp(r'/admin/tenants/\d+/founder$').hasMatch(path)) {
      final id = int.parse(
        RegExp(
          r'/admin/tenants/(\d+)/founder$',
        ).firstMatch(path)!.group(1)!,
      );
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final tenant = adminTenants.firstWhere((tenant) => tenant['id'] == id);
      tenant['is_founder'] = body['is_founder'];

      return _jsonResponse(200, tenant);
    }

    if (method == 'POST' &&
        RegExp(r'/admin/tenants/\d+/subscription/extend$').hasMatch(path)) {
      final id = int.parse(
        RegExp(
          r'/admin/tenants/(\d+)/subscription/extend$',
        ).firstMatch(path)!.group(1)!,
      );
      final tenant = adminTenants.firstWhere((tenant) => tenant['id'] == id);
      final subscription = tenant['saas_subscription'] as Map<String, dynamic>;
      subscription['status'] = 'active';
      subscription['effective_status'] = 'active';
      subscription['plan_name'] = 'Premium (cortesia)';
      subscription['price_cents'] = 0;
      subscription['current_period_ends_at'] = '2027-07-09T00:00:00.000000Z';

      return _jsonResponse(200, tenant);
    }

    if (method == 'GET' && path.endsWith('/tenant')) {
      return _jsonResponse(200, {
        ..._tenantJson,
        'is_founder': founderTenant,
        if (trialTenant)
          'saas_subscription': {
            ..._tenantJson['saas_subscription'] as Map<String, dynamic>,
            'status': 'trial',
            'effective_status': 'trial',
            'trial_days_remaining': 5,
          },
      });
    }

    if (method == 'PATCH' && path.endsWith('/tenant')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(200, {
        ..._tenantJson,
        'professional_payment_day': body['professional_payment_day'],
        if (body.containsKey('opening_time'))
          'opening_time': body['opening_time'],
        if (body.containsKey('closing_time'))
          'closing_time': body['closing_time'],
        if (body.containsKey('break_start_time'))
          'break_start_time': body['break_start_time'],
        if (body.containsKey('break_end_time'))
          'break_end_time': body['break_end_time'],
      });
    }

    if (method == 'GET' && path.endsWith('/tenant/schedule-overrides')) {
      return _jsonResponse(200, _scheduleOverridesJson);
    }

    if (method == 'POST' && path.endsWith('/tenant/schedule-overrides')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 1,
        'date': body['date'],
        'is_closed': body['is_closed'] ?? false,
        'opens_at': body['opens_at'],
        'closes_at': body['closes_at'],
      });
    }

    if (method == 'DELETE' && path.contains('/tenant/schedule-overrides/')) {
      return http.Response('', 204);
    }

    if (method == 'GET' && path.endsWith('/saas-plans')) {
      return _jsonResponse(200, _saasPlansJson);
    }

    if (method == 'PATCH' && path.endsWith('/saas-subscription')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final planCode = body['plan_code'] as String;
      final plan = _saasPlansJson.firstWhere((p) => p['code'] == planCode);

      return _jsonResponse(200, {
        ..._tenantJson,
        'saas_subscription': {
          'status': 'active',
          'effective_status': 'active',
          'trial_days_remaining': null,
          'plan_name': plan['name'],
          'price_cents': plan['price_cents'],
          'plan': plan,
          'limits': {
            'professionals': plan['max_professionals'],
            'client_subscriptions': plan['max_client_subscriptions'],
            'units': plan['max_units'],
          },
          'usage': {'professionals': 2, 'client_subscriptions': 3, 'units': 1},
        },
      });
    }

    if (method == 'GET' && path.endsWith('/dashboard/summary')) {
      return _jsonResponse(200, {
        'appointments_today': 4,
        'confirmed_today': 2,
        'pending_today': 1,
        'canceled_today': 1,
        'waitlist_count': 2,
        'expected_revenue_today_cents': 24000,
        'recurring_revenue_month_cents': 18400,
        'walkin_revenue_month_cents': 7350,
        'open_debt_cents': 14990,
      });
    }

    if (method == 'GET' && path.endsWith('/dashboard/occupancy')) {
      return _jsonResponse(200, [
        {
          'professional_id': 10,
          'professional_name': 'Ana Souza',
          'days': [
            {
              'weekday': 1,
              'date': '2026-07-06',
              'has_override': false,
              'available_minutes': 240,
              'occupied_minutes': 192,
              'percentage': 80,
            },
          ],
        },
        {
          'professional_id': 11,
          'professional_name': 'Rafael Souza',
          'days': [
            {
              'weekday': 1,
              'date': '2026-07-06',
              'has_override': false,
              'available_minutes': 200,
              'occupied_minutes': 100,
              'percentage': 50,
            },
          ],
        },
      ]);
    }

    if (method == 'GET' && path.endsWith('/dashboard/team-performance')) {
      return _jsonResponse(200, [
        {
          'professional_id': 10,
          'professional_name': 'Ana Souza',
          'completed_count': 6,
          'avulso_count': 4,
          'plano_count': 2,
          'gross_cents': 36000,
          'commission_percentage': 40,
          'commission_cents': 14400,
          'advances_cents': 3000,
          'net_cents': 11400,
        },
        {
          'professional_id': 11,
          'professional_name': 'Rafael Souza',
          'completed_count': 2,
          'avulso_count': 2,
          'plano_count': 0,
          'gross_cents': 12000,
          'commission_percentage': 35,
          'commission_cents': 4200,
          'advances_cents': 0,
          'net_cents': 4200,
        },
      ]);
    }

    if (method == 'GET' &&
        path.endsWith('/me/professional/schedule-overrides')) {
      return _jsonResponse(200, _professionalScheduleOverridesJson);
    }

    if (method == 'POST' &&
        path.endsWith('/me/professional/schedule-overrides')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 9,
        'date': body['date'],
        'is_off': body['is_off'] ?? false,
        'starts_at': body['starts_at'],
        'ends_at': body['ends_at'],
      });
    }

    if (method == 'DELETE' &&
        path.contains('/me/professional/schedule-overrides/')) {
      return http.Response('', 204);
    }

    if (method == 'GET' && path.endsWith('/dashboard/return-risk')) {
      return _jsonResponse(200, [
        {
          'client_id': 5,
          'client_name': 'Maria Oliveira',
          'last_visit_at': '2026-05-30',
          'avg_interval_days': 25,
          'days_since_last': 38,
          'probability': 'alta',
        },
      ]);
    }

    if (method == 'GET' && path.endsWith('/me/professional')) {
      return _jsonResponse(200, _professionalMeJson);
    }

    if (method == 'GET' && path.endsWith('/me/professional/finance')) {
      return _jsonResponse(200, _professionalFinanceJson);
    }

    if (method == 'PATCH' && path.endsWith('/me/professional')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(200, {
        ..._professionalMeJson,
        if (body['name'] != null) 'name': body['name'],
        if (body['email'] != null) 'email': body['email'],
        if (body['specialty'] != null) 'specialty': body['specialty'],
        if (body['phone'] != null) 'phone': body['phone'],
      });
    }

    if (method == 'GET' && path.endsWith('/me/client')) {
      return _jsonResponse(200, _meClientJson);
    }

    if (method == 'PATCH' && path.endsWith('/me/client')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(200, {
        ..._meClientJson,
        if (body['name'] != null) 'name': body['name'],
        if (body['phone'] != null) 'phone': body['phone'],
        if (body['email'] != null) 'email': body['email'],
      });
    }

    if (method == 'GET' && path.endsWith('/clients')) {
      return _jsonResponse(200, _clientsJson);
    }

    if (method == 'POST' && path.endsWith('/clients')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 99,
        'name': body['name'],
        'phone': body['phone'],
        'email': body['email'],
        'notes': body['notes'],
        'status': 'active',
        'created_at': '2026-07-09T09:00:00.000000Z',
        'subscriptions': <dynamic>[],
      });
    }

    if (method == 'PATCH' && path.contains('/clients/')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final client = _clientsJson.firstWhere(
        (client) => '${client['id']}' == path.split('/').last,
        orElse: () => _clientsJson.first,
      );
      return _jsonResponse(200, {
        ...client,
        if (body['name'] != null) 'name': body['name'],
        if (body['phone'] != null) 'phone': body['phone'],
        if (body['notes'] != null) 'notes': body['notes'],
        if (body['status'] != null) 'status': body['status'],
      });
    }

    if (method == 'GET' && path.endsWith('/services')) {
      return _jsonResponse(200, _servicesJson);
    }

    if (method == 'POST' && path.endsWith('/services')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 55,
        'name': body['name'],
        'duration_minutes': body['duration_minutes'],
        'price_cents': body['price_cents'],
        'description': body['description'],
        'is_active': true,
      });
    }

    if (method == 'PATCH' && path.contains('/services/')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final service = _servicesJson.firstWhere(
        (service) => '${service['id']}' == path.split('/').last,
        orElse: () => _servicesJson.first,
      );
      return _jsonResponse(200, {
        ...service,
        if (body['name'] != null) 'name': body['name'],
        if (body['duration_minutes'] != null)
          'duration_minutes': body['duration_minutes'],
        if (body['price_cents'] != null) 'price_cents': body['price_cents'],
        if (body['description'] != null) 'description': body['description'],
        if (body['is_active'] != null) 'is_active': body['is_active'],
      });
    }

    if (method == 'GET' && path.endsWith('/professionals')) {
      return _jsonResponse(200, _professionalsJson);
    }

    if (method == 'GET' &&
        path.contains('/professionals/') &&
        path.endsWith('/finance')) {
      return _jsonResponse(200, _professionalFinanceJson);
    }

    if (method == 'POST' &&
        path.contains('/professionals/') &&
        path.endsWith('/advances')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 2,
        'amount_cents': body['amount_cents'],
        'paid_at': '2026-07-04T10:00:00.000000Z',
        'notes': body['notes'],
      });
    }

    if (method == 'POST' && path.endsWith('/professionals')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final serviceIds = (body['service_ids'] as List<dynamic>? ?? []);
      return _jsonResponse(201, {
        'id': 66,
        'name': body['name'],
        'email': body['email'],
        'phone': body['phone'],
        'specialty': body['specialty'],
        'commission_percentage': body['commission_percentage'],
        'is_active': true,
        'services': serviceIds
            .map((id) => {'id': id, 'name': 'Servico $id'})
            .toList(),
      });
    }

    if (method == 'PATCH' && path.contains('/professionals/')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final serviceIds = (body['service_ids'] as List<dynamic>? ?? []);
      return _jsonResponse(200, {
        ..._professionalMeJson,
        if (body['name'] != null) 'name': body['name'],
        if (body['specialty'] != null) 'specialty': body['specialty'],
        if (body['is_active'] != null) 'is_active': body['is_active'],
        'services': serviceIds
            .map((id) => {'id': id, 'name': 'Servico $id'})
            .toList(),
      });
    }

    if (method == 'GET' && path.endsWith('/subscription-plans')) {
      return _jsonResponse(200, _plansJson);
    }

    if (method == 'POST' && path.endsWith('/subscription-plans')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 88,
        'name': body['name'],
        'price_cents': body['price_cents'],
        'usage_limit': body['usage_limit'],
        'is_active': true,
        'services': <dynamic>[],
      });
    }

    if (method == 'PATCH' && path.contains('/subscription-plans/')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final services = (body['services'] as List<dynamic>? ?? []);
      return _jsonResponse(200, {
        ..._bronzePlanJson,
        if (body['name'] != null) 'name': body['name'],
        if (body['price_cents'] != null) 'price_cents': body['price_cents'],
        if (body['usage_limit'] != null) 'usage_limit': body['usage_limit'],
        if (body['is_active'] != null) 'is_active': body['is_active'],
        'services': services
            .map((service) => {'id': (service as Map<String, dynamic>)['id'], 'name': 'Servico ${service['id']}'})
            .toList(),
        'professionals': <dynamic>[],
      });
    }

    if (method == 'POST' && path.endsWith('/me/client-subscriptions')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final plan = _plansJson.firstWhere(
        (plan) => plan['id'] == body['subscription_plan_id'],
        orElse: () => _bronzePlanJson,
      );
      return _jsonResponse(201, {
        'id': 2,
        'client_id': 1,
        'subscription_plan_id': plan['id'],
        'status': 'active',
        'payment_status': 'pending',
        'plan': plan,
        'usages': <dynamic>[],
        'payments': <dynamic>[],
      });
    }

    if (method == 'POST' && path.endsWith('/me/client-subscriptions/cancel')) {
      return _jsonResponse(200, {
        'id': 1,
        'client_id': 1,
        'subscription_plan_id': 1,
        'status': 'canceled',
        'payment_status': 'paid',
        'plan': _bronzePlanJson,
        'usages': <dynamic>[],
        'payments': <dynamic>[],
      });
    }

    if (method == 'POST' &&
        path.contains('/appointments/') &&
        path.endsWith('/complete')) {
      return _jsonResponse(200, {
        ..._appointmentsJson.first,
        'status': 'completed',
        // Atendimento avulso concluido tem um pagamento pendente associado,
        // que o app oferece confirmar direto na tela de conclusao.
        'payment': {
          'id': 30,
          'amount_cents': 6000,
          'method': 'pix',
          'status': 'pending',
        },
      });
    }

    if (method == 'POST' && path.endsWith('/appointments')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 77,
        'starts_at': body['starts_at'],
        'ends_at': body['starts_at'],
        'status': 'scheduled',
        'client': {'name': 'Carlos Mendes'},
        'professional': {'name': 'Ana Souza'},
        'service': {'name': 'Corte masculino'},
        'notes': null,
        // Agendamento avulso: backend real cria esse pagamento automaticamente
        // quando nao ha client_subscription_id.
        'payment': body['client_subscription_id'] == null
            ? {'amount_cents': 6000, 'status': 'pending'}
            : null,
      });
    }

    if (method == 'GET' && path.endsWith('/appointments/salon')) {
      // Espelha o backend real: a agenda do salao nunca inclui o cliente.
      return _jsonResponse(
        200,
        _appointmentsJson
            .map((json) => {...json}..remove('client'))
            .toList(),
      );
    }

    if (method == 'GET' && path.endsWith('/appointments')) {
      return _jsonResponse(200, _appointmentsJson);
    }

    if ((method == 'PATCH' || method == 'PUT') &&
        RegExp(r'/appointments/\d+$').hasMatch(path)) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(200, {
        ..._appointmentsJson.first,
        if (body['status'] != null) 'status': body['status'],
        if (body['starts_at'] != null) 'starts_at': body['starts_at'],
        if (body['starts_at'] != null) 'ends_at': body['starts_at'],
      });
    }

    if (method == 'POST' &&
        path.contains('/waitlist/') &&
        path.endsWith('/assign')) {
      return _jsonResponse(200, {
        ..._waitlistEntriesJson.first,
        'status': 'scheduled',
        'professional': {'name': 'Ana Souza'},
        'appointment': {
          'id': 99,
          'status': 'scheduled',
          'service': {'name': 'Corte masculino'},
          'payment': {'amount_cents': 6000, 'status': 'pending'},
        },
      });
    }

    if (method == 'GET' && path.endsWith('/waitlist')) {
      return _jsonResponse(200, _waitlistEntriesJson);
    }

    if (method == 'POST' && path.endsWith('/waitlist')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 2,
        'status': 'waiting',
        'notes': body['notes'],
        'client': {'name': 'Carlos Mendes'},
        'service': {'name': 'Corte masculino'},
        'professional': null,
        'appointment': null,
      });
    }

    if (method == 'PATCH' && RegExp(r'/waitlist/\d+$').hasMatch(path)) {
      return _jsonResponse(200, {
        ..._waitlistEntriesJson.first,
        'status': 'canceled',
      });
    }

    if (method == 'GET' && path.endsWith('/me/payments')) {
      return _jsonResponse(200, _paymentsJson);
    }

    if (method == 'GET' && path.endsWith('/payments')) {
      return _jsonResponse(200, _paymentsJson);
    }

    if (method == 'POST' && path.endsWith('/payments')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(201, {
        'id': 99,
        'amount_cents': body['amount_cents'],
        'method': 'pix',
        'status': body['status'] ?? 'pending',
        'client_subscription_id': body['client_subscription_id'],
        'subscription': {
          'client': {'name': 'Carlos Mendes'},
        },
        'receipts': <dynamic>[],
      });
    }

    if (method == 'POST' &&
        path.contains('/payments/') &&
        path.endsWith('/mark-paid')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final selectedMethod = body['method'] as String;
      return _jsonResponse(200, {
        ..._paymentsJson.first,
        'method': selectedMethod,
        'status': selectedMethod == 'fiado' ? 'pending' : 'paid',
      });
    }

    if (method == 'POST' &&
        path.contains('/payments/') &&
        path.endsWith('/receipts')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return _jsonResponse(200, {
        ..._paymentsJson.first,
        'method': body['method'],
        'status': 'pending',
        'receipts': [
          ...(_paymentsJson.first['receipts'] as List<dynamic>),
          {
            'id': 2,
            'amount_cents': body['amount_cents'],
            'method': body['method'],
            'received_at': '2026-07-04T10:00:00.000000Z',
          },
        ],
      });
    }

    return _jsonResponse(404, {
      'message': 'Registro nao encontrado.',
      'error': 'not_found',
    });
  });
}

Map<String, dynamic>? _userForToken(http.Request request) {
  final auth = request.headers['Authorization'];

  return switch (auth) {
    'Bearer owner-token' => _ownerJson,
    'Bearer professional-token' => _professionalJson,
    'Bearer customer-token' => _customerJson,
    'Bearer admin-token' => _adminJson,
    _ => null,
  };
}

http.Response _jsonResponse(int statusCode, dynamic body) {
  return http.Response(jsonEncode(body), statusCode);
}

const _unauthenticated = {
  'message': 'Autenticacao obrigatoria.',
  'error': 'unauthenticated',
};

const _tenantJson = {
  'id': 1,
  'name': 'Clube do Salao Demo',
  'professional_payment_day': 5,
  'invite_code': 'AB3XQ9',
  'is_founder': false,
  'saas_subscription': {
    'status': 'active',
    'effective_status': 'active',
    'trial_days_remaining': null,
    'plan_name': 'Intermediario',
    'price_cents': 12999,
    'plan': {
      'code': 'intermediario',
      'name': 'Intermediario',
      'price_cents': 12999,
      'max_professionals': 8,
      'max_client_subscriptions': 400,
      'max_units': 1,
    },
    'limits': {'professionals': 8, 'client_subscriptions': 400, 'units': 1},
    'usage': {'professionals': 2, 'client_subscriptions': 3, 'units': 1},
  },
};

const _scheduleOverridesJson = <Map<String, dynamic>>[];

const _saasPlansJson = [
  {
    'code': 'basico',
    'name': 'Basico',
    'price_cents': 7999,
    'max_professionals': 3,
    'max_client_subscriptions': 100,
    'max_units': 1,
  },
  {
    'code': 'intermediario',
    'name': 'Intermediario',
    'price_cents': 12999,
    'max_professionals': 8,
    'max_client_subscriptions': 400,
    'max_units': 1,
  },
  {
    'code': 'premium',
    'name': 'Premium',
    'price_cents': 19999,
    'max_professionals': null,
    'max_client_subscriptions': null,
    'max_units': null,
  },
];

const _ownerJson = {
  'id': 1,
  'name': 'Jose Silva',
  'email': 'owner@clubedosalao.com',
  'role': 'owner',
  'tenant_id': 1,
  'tenant': {'name': 'Clube do Salao Demo'},
};

const _professionalJson = {
  'id': 2,
  'name': 'Ana Souza',
  'email': 'ana.souza@clubedosalao.com',
  'role': 'professional',
  'tenant_id': 1,
  'tenant': {'name': 'Clube do Salao Demo'},
};

const _customerJson = {
  'id': 4,
  'name': 'Carlos Mendes',
  'email': 'carlos.mendes@clubedosalao.com',
  'role': 'customer',
  'tenant_id': 1,
  'tenant': {'name': 'Clube do Salao Demo'},
};

// Administrador da plataforma (roadmap Fase 5) nao pertence a nenhum
// tenant, entao nao tem `tenant_id`/`tenant` (espelha o backend real).
const _adminJson = {
  'id': 99,
  'name': 'Jose Admin',
  'email': 'admin@clubedosalao.com',
  'role': 'admin',
};

/// Lista mutavel de saloes vista pelo administrador (`/admin/tenants`).
/// Uma copia nova e criada a cada `buildFakeBackend()`, entao cada teste
/// comeca do mesmo estado inicial mesmo apos toggles/concessoes.
List<Map<String, dynamic>> _buildAdminTenantsJson() => [
  {
    'id': 1,
    'name': 'Clube do Salao Demo',
    'business_type': 'barbershop',
    'city': 'Sao Paulo',
    'is_founder': false,
    'saas_subscription': {
      'status': 'active',
      'effective_status': 'active',
      'trial_days_remaining': null,
      'plan_name': 'Intermediario',
      'price_cents': 12999,
      'plan': _saasPlansJson[1],
      'limits': {'professionals': 8, 'client_subscriptions': 400, 'units': 1},
      'usage': {'professionals': 2, 'client_subscriptions': 3, 'units': 1},
      'current_period_ends_at': '2026-08-05T00:00:00.000000Z',
    },
  },
  {
    'id': 2,
    'name': 'Barbearia do Ze',
    'business_type': 'barbershop',
    'city': 'Campinas',
    'is_founder': true,
    'saas_subscription': {
      'status': 'trial',
      'effective_status': 'trial',
      'trial_days_remaining': 5,
      'plan_name': 'Trial',
      'price_cents': 0,
      'plan': null,
      'limits': {'professionals': 3, 'client_subscriptions': 100, 'units': 1},
      'usage': {'professionals': 1, 'client_subscriptions': 10, 'units': 1},
      'current_period_ends_at': null,
    },
  },
];

const _professionalMeJson = {
  'id': 10,
  'name': 'Ana Souza',
  'email': 'ana.souza@clubedosalao.com',
  'phone': '11999990000',
  'specialty': 'Cortes e barba',
  'commission_percentage': 40,
  'is_active': true,
  'user_id': 2,
  'services': [
    {'id': 1, 'name': 'Corte masculino'},
    {'id': 2, 'name': 'Barba completa'},
  ],
  // Horario individual bem mais amplo que o horario padrao do salao
  // (ver `_availableSlots` em ChooseTimePage), pra cobrir o bug real
  // relatado pelo usuario: cliente via so ate 17:30 mesmo com o
  // profissional configurado pra atender ate mais tarde.
  'working_hours': [
    {'weekday': 0, 'starts_at': '08:00', 'ends_at': '23:00'},
    {'weekday': 1, 'starts_at': '08:00', 'ends_at': '23:00'},
    {'weekday': 2, 'starts_at': '08:00', 'ends_at': '23:00'},
    {'weekday': 3, 'starts_at': '08:00', 'ends_at': '23:00'},
    {'weekday': 4, 'starts_at': '08:00', 'ends_at': '23:00'},
    {'weekday': 5, 'starts_at': '08:00', 'ends_at': '23:00'},
    {'weekday': 6, 'starts_at': '08:00', 'ends_at': '23:00'},
  ],
};

const _professionalFinanceJson = {
  'professional_id': 10,
  'professional_name': 'Ana Souza',
  'period': 'month',
  'from': '2026-07-01',
  'to': '2026-07-31',
  'payment_day': 5,
  'completed_count': 6,
  'avulso_count': 4,
  'plano_count': 2,
  'gross_cents': 36000,
  'avulso_revenue_cents': 24000,
  'plano_revenue_cents': 12000,
  'commission_percentage': 40,
  'commission_cents': 14400,
  'advances_cents': 3000,
  'net_cents': 11400,
  'appointments': [
    {
      'starts_at': '2026-07-01T09:00:00.000000Z',
      'client_subscription_id': null,
      'service': {'id': 1, 'name': 'Corte masculino', 'price_cents': 6000},
      'client': {'id': 1, 'name': 'Carlos Mendes'},
    },
    {
      'starts_at': '2026-07-02T10:00:00.000000Z',
      'client_subscription_id': null,
      'service': {'id': 1, 'name': 'Corte masculino', 'price_cents': 6000},
      'client': {'id': 2, 'name': 'Maria Avulsa'},
    },
    {
      'starts_at': '2026-07-03T11:00:00.000000Z',
      'client_subscription_id': null,
      'service': {'id': 1, 'name': 'Corte masculino', 'price_cents': 6000},
      'client': {'id': 3, 'name': 'Joao Ribeiro'},
    },
    {
      'starts_at': '2026-07-04T14:00:00.000000Z',
      'client_subscription_id': null,
      'service': {'id': 1, 'name': 'Corte masculino', 'price_cents': 6000},
      'client': {'id': 4, 'name': 'Ana Cliente'},
    },
    {
      'starts_at': '2026-07-05T09:00:00.000000Z',
      'client_subscription_id': 501,
      'service': {'id': 1, 'name': 'Corte masculino', 'price_cents': 6000},
      'client': {'id': 1, 'name': 'Carlos Mendes'},
    },
    {
      'starts_at': '2026-07-06T09:00:00.000000Z',
      'client_subscription_id': 502,
      'service': {'id': 1, 'name': 'Corte masculino', 'price_cents': 6000},
      'client': {'id': 2, 'name': 'Maria Avulsa'},
    },
  ],
  'advances': [
    {
      'id': 1,
      'amount_cents': 3000,
      'paid_at': '2026-07-04T10:00:00.000000Z',
      'notes': 'Adiantamento',
    },
  ],
};

final _professionalsJson = [
  _professionalMeJson,
  {
    'id': 11,
    'name': 'Rafael Souza',
    'email': 'rafael.souza@clubedosalao.com',
    'specialty': 'Sobrancelha e coloracao',
    'commission_percentage': 35,
    'is_active': true,
    'user_id': 3,
    'services': [
      {'id': 1, 'name': 'Corte masculino'},
      {'id': 2, 'name': 'Barba completa'},
    ],
  },
];

const _bronzePlanJson = {
  'id': 1,
  'name': 'Bronze',
  'price_cents': 9990,
  'usage_limit': 4,
  'is_active': true,
  'services': [
    {
      'id': 1,
      'name': 'Corte masculino',
      'pivot': {'included_quantity': 4, 'discount_percentage': 0},
    },
  ],
};

final _plansJson = [
  _bronzePlanJson,
  {
    'id': 2,
    'name': 'Prata',
    'price_cents': 14990,
    'usage_limit': 8,
    'is_active': true,
    'services': <dynamic>[],
  },
  {
    'id': 3,
    'name': 'Black',
    'price_cents': 19990,
    'usage_limit': null,
    'is_active': true,
    'services': <dynamic>[],
  },
];

final _clientsJson = [
  {
    'id': 1,
    'name': 'Carlos Mendes',
    'phone': '11988881234',
    'email': 'carlos.mendes@clubedosalao.com',
    'notes': null,
    'status': 'active',
    'created_at': '2026-05-12T10:00:00.000000Z',
    'subscriptions': [
      {
        'id': 1,
        'client_id': 1,
        'subscription_plan_id': 1,
        'status': 'active',
        'payment_status': 'paid',
        'plan': _bronzePlanJson,
      },
    ],
  },
  {
    'id': 2,
    'name': 'Joao Ribeiro',
    'phone': '11977775678',
    'email': null,
    'notes': null,
    'status': 'active',
    'created_at': '2026-07-01T08:00:00.000000Z',
    'subscriptions': <dynamic>[],
  },
];

final _meClientJson = {
  'id': 1,
  'name': 'Carlos Mendes',
  'phone': '11988881234',
  'email': 'carlos.mendes@clubedosalao.com',
  'notes': null,
  'status': 'active',
  'subscriptions': [
    {
      'id': 1,
      'client_id': 1,
      'subscription_plan_id': 1,
      'status': 'active',
      'payment_status': 'paid',
      'renews_on': '2026-08-01',
      'plan': _bronzePlanJson,
      'payments': [
        {
          'id': 10,
          'client_subscription_id': 1,
          'amount_cents': 9990,
          'method': 'pix',
          'status': 'paid',
          'due_on': '2026-07-01',
          'paid_at': '2026-07-01T10:00:00.000000Z',
          'receipts': <dynamic>[],
        },
      ],
      'usages': [
        {
          'used_at': '2026-06-20T10:00:00.000000Z',
          'service': {'name': 'Corte masculino'},
        },
      ],
    },
  ],
};

final _servicesJson = [
  {
    'id': 1,
    'name': 'Corte masculino',
    'duration_minutes': 45,
    'price_cents': 6000,
    'is_active': true,
  },
  {
    'id': 2,
    'name': 'Barba completa',
    'duration_minutes': 30,
    'price_cents': 4000,
    'is_active': true,
  },
];

final _appointmentsJson = [
  {
    'id': 1,
    'starts_at': '2026-07-03T09:00:00.000000Z',
    'ends_at': '2026-07-03T09:45:00.000000Z',
    'status': 'scheduled',
    'client': {'name': 'Carlos Mendes'},
    'professional': {'name': 'Ana Souza'},
    'service': {'name': 'Corte masculino'},
    'notes': null,
  },
];

final _professionalScheduleOverridesJson = [
  {
    'id': 1,
    'date': '2026-07-06',
    'is_off': false,
    'starts_at': '10:00',
    'ends_at': '18:00',
  },
];

final _waitlistEntriesJson = [
  {
    'id': 1,
    'status': 'waiting',
    'notes': null,
    'client': {'name': 'Carlos Mendes'},
    'service': {'name': 'Corte masculino'},
    'professional': null,
    'appointment': null,
  },
];

final _paymentsJson = [
  {
    'id': 1,
    'amount_cents': 19990,
    'method': 'fiado',
    'status': 'pending',
    'due_on': '2026-07-10',
    'subscription': {
      'client': {'name': 'Joao Ribeiro'},
    },
    // Data bem no passado de proposito: mantido fora do mes corrente pra nao
    // aparecer em extratos de receita "deste mes" so por coincidencia com a
    // data real de quando o teste roda (o app calcula "mes atual" com
    // DateTime.now()).
    'receipts': [
      {
        'id': 1,
        'amount_cents': 5000,
        'method': 'pix',
        'received_at': '2020-01-04T10:00:00.000000Z',
      },
    ],
  },
  // Avulso comum ainda aguardando a primeira confirmacao (method default,
  // nao fiado) — distinto do fiado acima, que ja saiu de "Pagamentos
  // pendentes" e so aparece em "Gestao do fiado".
  {
    'id': 2,
    'amount_cents': 6000,
    'method': 'pix',
    'status': 'pending',
    'due_on': null,
    'client': {'name': 'Maria Avulsa'},
    'receipts': <dynamic>[],
  },
  // Fiado com um recebimento parcial recebido "hoje" (data calculada em
  // tempo de execucao, sempre dentro do mes corrente) — cobre o bug real
  // onde um recebimento parcial nao entrava na receita do mes ate o fiado
  // ser quitado por completo.
  {
    'id': 3,
    'amount_cents': 8000,
    'method': 'fiado',
    'status': 'pending',
    'due_on': null,
    'client': {'name': 'Pedro Devedor'},
    'receipts': [
      {
        'id': 2,
        'amount_cents': 3000,
        'method': 'pix',
        'received_at': DateTime.now().toIso8601String(),
      },
    ],
  },
];
