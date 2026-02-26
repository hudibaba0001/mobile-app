import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/services/auth_http_client.dart';

class _QueueHttpClient extends http.BaseClient {
  _QueueHttpClient(this._responses);

  final List<http.Response> _responses;
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final index =
        callCount < _responses.length ? callCount : _responses.length - 1;
    callCount++;
    final response = _responses[index];
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

void main() {
  test('401 attempts refresh and signs out when refresh fails', () async {
    var refreshCalls = 0;
    var signOutCalls = 0;
    final client = _QueueHttpClient([http.Response('unauthorized', 401)]);
    final authClient = AuthHttpClient(
      client: client,
      accessTokenProvider: () => 'token',
      refreshSession: () async {
        refreshCalls++;
        return false;
      },
      signOut: () async {
        signOutCalls++;
      },
    );

    await expectLater(
      authClient.get(Uri.parse('https://example.com/protected')),
      throwsA(isA<AuthExpiredException>()),
    );

    expect(refreshCalls, 1);
    expect(signOutCalls, 1);
    expect(client.callCount, 1);
  });

  test('401 after refresh retry signs out and throws AuthExpiredException',
      () async {
    var refreshCalls = 0;
    var signOutCalls = 0;
    final client = _QueueHttpClient([
      http.Response('unauthorized', 401),
      http.Response('still unauthorized', 401),
    ]);
    final authClient = AuthHttpClient(
      client: client,
      accessTokenProvider: () => 'token',
      refreshSession: () async {
        refreshCalls++;
        return true;
      },
      signOut: () async {
        signOutCalls++;
      },
    );

    await expectLater(
      authClient.get(Uri.parse('https://example.com/protected')),
      throwsA(isA<AuthExpiredException>()),
    );

    expect(refreshCalls, 1);
    expect(signOutCalls, 1);
    expect(client.callCount, 2);
  });
}
