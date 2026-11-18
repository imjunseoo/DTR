import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ChatFailure implements Exception {
  const ChatFailure(this.message);
  final String message;
}

class ChatApi {
  const ChatApi({this.endpoint = const String.fromEnvironment('DTR_CHAT_URL')});
  final String endpoint;
  bool get configured {
    final uri = Uri.tryParse(endpoint);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty;
  }

  Future<String> reply({
    required String token,
    required List<Map<String, String>> messages,
    required Map<String, Object> context,
  }) async {
    if (!configured) {
      throw const ChatFailure('AI 연결 준비 중이에요. 기본 대화는 계속 이용할 수 있어요.');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final request = await client.postUrl(Uri.parse(endpoint));
        request.followRedirects = false;
        request.headers.contentType = ContentType.json;
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.write(jsonEncode({'messages': messages, 'context': context}));
        final response = await request.close();
        if (response.statusCode == 429) {
          throw const ChatFailure(
            '요청이 많거나 이용 한도에 도달했어요. 잠시 후 다시 시도하거나 기본 대화를 이용해 주세요.',
          );
        }
        if (response.statusCode == 401) {
          throw const ChatFailure('초대 코드를 확인해 주세요. AI 대화를 껐다 켜면 다시 입력할 수 있어요.');
        }
        if (response.statusCode != 200) {
          throw const ChatFailure('AI가 잠시 쉬고 있어요. 잠시 후 다시 시도해 주세요.');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 32768) {
            throw const ChatFailure('응답을 읽지 못했어요. 다시 시도해 주세요.');
          }
        }
        final data = jsonDecode(utf8.decode(bytes));
        final reply = data is Map ? data['reply'] : null;
        if (reply is! String || reply.trim().isEmpty || reply.length > 6000) {
          throw const ChatFailure('응답을 읽지 못했어요. 다시 시도해 주세요.');
        }
        return reply.trim();
      })().timeout(const Duration(seconds: 35));
    } on ChatFailure {
      rethrow;
    } catch (_) {
      throw const ChatFailure('연결하지 못했어요. 인터넷 연결을 확인하거나 기본 대화를 이용해 주세요.');
    } finally {
      client.close(force: true);
    }
  }
}
