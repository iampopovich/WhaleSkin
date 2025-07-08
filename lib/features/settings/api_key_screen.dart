import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chat_bloc.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscured = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: BlocListener<ChatBloc, ChatState>(
          listener: (context, state) {
            // Бизнес-логика переходов и обработки состояний
            if (state is ChatLoaded && state.hasApiKey) {
              Navigator.of(context).pushReplacementNamed('/home');
            } else if (state is ApiKeyTestSuccess) {
              context.read<ChatBloc>().add(SetApiKey(state.apiKey));
            } else if (state is ApiKeyTestFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is ChatError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Логотип и заголовок
                  const Icon(Icons.chat, size: 80, color: Color(0xFF4F9CF9)),
                  const SizedBox(height: 24),
                  const Text(
                    'WhaleSkin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'DeepSeek API Wrapper',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 48),

                  // Форма ввода API ключа
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Введите DeepSeek API ключ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _controller,
                          obscureText: _isObscured,
                          decoration: InputDecoration(
                            hintText: 'sk-...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF64748B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2A2A3A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF4F9CF9),
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscured
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите API ключ';
                            }
                            if (!value.startsWith('sk-')) {
                              return 'API ключ должен начинаться с "sk-"';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Кнопка отправки
                        BlocBuilder<ChatBloc, ChatState>(
                          builder: (context, state) {
                            final isLoading =
                                state is ChatLoading || state is ApiKeyTesting;

                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : _testAndSubmitApiKey,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F9CF9),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            state is ApiKeyTesting
                                                ? 'Проверка ключа...'
                                                : 'Загрузка...',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Проверить и продолжить',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Информация о получении API ключа
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4F9CF9).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFF4F9CF9),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Как получить API ключ?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F9CF9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Перейдите на platform.deepseek.com\n'
                          '2. Создайте аккаунт или войдите\n'
                          '3. Перейдите в раздел API Keys\n'
                          '4. Создайте новый ключ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openDeepSeekPlatform,
                                icon: const Icon(
                                  Icons.open_in_browser,
                                  size: 16,
                                ),
                                label: const Text('Открыть DeepSeek'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4F9CF9),
                                  side: const BorderSide(
                                    color: Color(0xFF4F9CF9),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _copyUrl,
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Копировать'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                side: const BorderSide(
                                  color: Color(0xFF64748B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _testAndSubmitApiKey() {
    if (_formKey.currentState!.validate()) {
      context.read<ChatBloc>().add(TestApiKey(_controller.text.trim()));
    }
  }

  Future<void> _openDeepSeekPlatform() async {
    const url = 'https://platform.deepseek.com';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть ссылку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyUrl() {
    const url = 'https://platform.deepseek.com';
    Clipboard.setData(const ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ссылка скопирована в буфер обмена'),
        backgroundColor: Color(0xFF4F9CF9),
      ),
    );
  }
}
