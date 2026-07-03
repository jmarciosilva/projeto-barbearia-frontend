import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Simula as respostas do backend Laravel (`backend/docs/api.md`) o
/// suficiente para exercitar o login e o dashboard do proprietario em
/// testes de widget, sem precisar de uma API real rodando.
///
/// O "token" retornado no login e literalmente o papel do usuario
/// (`owner-token`, `professional-token`, `customer-token`), o que permite
/// ao `GET /me` simulado devolver o usuario certo sem estado adicional.
http.Client buildFakeBackend() {
  return MockClient((request) async {
    final path = request.url.path;
    final method = request.method;

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

    if (method == 'POST' && path.endsWith('/auth/logout')) {
      return http.Response('', 204);
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
        'subscriptions': <dynamic>[],
      });
    }

    if (method == 'GET' && path.endsWith('/services')) {
      return _jsonResponse(200, _servicesJson);
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

    if (method == 'GET' && path.endsWith('/appointments')) {
      return _jsonResponse(200, _appointmentsJson);
    }

    if (method == 'GET' && path.endsWith('/payments')) {
      return _jsonResponse(200, _paymentsJson);
    }

    if (method == 'POST' && path.contains('/payments/') && path.endsWith('/mark-paid')) {
      return _jsonResponse(200, {
        ..._paymentsJson.first,
        'status': 'paid',
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
    'email': null,
    'notes': null,
    'status': 'active',
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
    'subscriptions': <dynamic>[],
  },
];

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

final _paymentsJson = [
  {
    'id': 1,
    'amount_cents': 19990,
    'method': 'pix',
    'status': 'pending',
    'due_on': '2026-07-10',
    'subscription': {
      'client': {'name': 'Joao Ribeiro'},
    },
  },
];
