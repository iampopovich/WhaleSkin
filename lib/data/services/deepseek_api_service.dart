import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekApiService {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  late final String _apiKey;

  DeepSeekApiService({required String apiKey}) : _apiKey = apiKey;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
  };

  Future<String> sendChatMessage({
    required List<Map<String, String>> messages,
    String model = 'deepseek-chat',
    double temperature = 1.0,
    int maxTokens = 2048,
    List<String> stopSequences = const [],
    String? systemPrompt,
    double frequencyPenalty = 0.0,
    double presencePenalty = 0.0,
    double topP = 1.0,
  }) async {
    try {
      // Добавляем системный промпт в начало, если он есть
      final fullMessages = <Map<String, String>>[];
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        fullMessages.add({'role': 'system', 'content': systemPrompt});
      }
      fullMessages.addAll(messages);

      final body = {
        'model': model,
        'messages': fullMessages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'frequency_penalty': frequencyPenalty,
        'presence_penalty': presencePenalty,
        'top_p': topP,
        'response_format': {'type': 'text'},
        'stream': false,
        'tool_choice': 'none',
        'logprobs': false,
        if (stopSequences.isNotEmpty) 'stop': stopSequences,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        throw DeepSeekApiException(
          'API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is DeepSeekApiException) rethrow;
      throw DeepSeekApiException('Network error: $e');
    }
  }

  Future<bool> validateApiKey() async {
    try {
      await sendChatMessage(
        messages: [
          {'role': 'user', 'content': 'Hi'},
        ],
        maxTokens: 1,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Test API key validity
  Future<bool> testApiKey() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class DeepSeekApiException implements Exception {
  final String message;
  DeepSeekApiException(this.message);

  @override
  String toString() => 'DeepSeekApiException: $message';
}
