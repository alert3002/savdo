import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../api/api_client.dart';
import 'auth_controller.dart';

class SmsLoginForm extends ConsumerStatefulWidget {
  const SmsLoginForm({
    super.key,
    required this.initialPhone,
    required this.onVerified,
  });

  final String initialPhone;
  final VoidCallback onVerified;

  @override
  ConsumerState<SmsLoginForm> createState() => _SmsLoginFormState();
}

class _SmsLoginFormState extends ConsumerState<SmsLoginForm> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  bool _isRegistered = true;

  int _secondsLeft = 0;
  Timer? _timer;
  bool _autoResendEnabled = true;
  bool _autoVerifyTriggered = false;

  @override
  void initState() {
    super.initState();
    final initialDigits = widget.initialPhone.replaceAll(RegExp(r'\D'), '');
    _phoneCtrl.text = initialDigits.length > 9
        ? initialDigits.substring(initialDigits.length - 9)
        : initialDigits;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
        return;
      }

      _timer?.cancel();

      // Auto resend if user didn't enter code yet.
      if (_autoResendEnabled && _codeCtrl.text.trim().isEmpty) {
        await _sendCode(auto: true);
      }
    });
  }

  Future<void> _sendCode({bool auto = false}) async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      if (!auto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Укажите номер телефона')),
        );
      }
      return;
    }

    setState(() => _sending = true);
    try {
      final isRegistered =
          await ref.read(authControllerProvider.notifier).requestLoginOtp(phone: phone);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _isRegistered = isRegistered;
        _secondsLeft = 60;
        _autoResendEnabled = true;
        _autoVerifyTriggered = false;
        if (isRegistered) {
          _refCtrl.clear();
        }
      });
      _startResendTimer();
      if (!auto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код отправлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e, sendStep: true))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (phone.length != 9 || code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите 9-значный номер и 4-значный код')),
      );
      return;
    }

    setState(() => _verifying = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithSmsOtp(
            phone: phone,
            otpCode: code,
            referralCode: _isRegistered ? null : _refCtrl.text.trim(),
          );
      widget.onVerified();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
      _autoVerifyTriggered = false;
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  String _friendlyError(Object e, {bool sendStep = false}) {
    if (e is ApiException) {
      var body = e.body;
      if (body.contains('<html') || body.contains('<!DOCTYPE')) {
        return sendStep
            ? 'Ошибка сервера при отправке SMS. Попробуйте позже.'
            : 'Ошибка сервера. Попробуйте позже.';
      }
      String message = body;
      try {
        // ignore: avoid_dynamic_calls
        final map = body.isNotEmpty ? (jsonDecode(body) as Map<String, dynamic>) : <String, dynamic>{};
        if (map['detail'] is String) message = map['detail'] as String;
        if (map['otp_code'] is String) message = map['otp_code'] as String;
        if (map['otp_code'] is List && (map['otp_code'] as List).isNotEmpty) {
          message = (map['otp_code'] as List).first.toString();
        }
        if (map['phone'] is String) message = map['phone'] as String;
        if (map['phone'] is List && (map['phone'] as List).isNotEmpty) {
          message = (map['phone'] as List).first.toString();
        }
      } catch (_) {}

      final lower = message.toLowerCase();
      if (lower.contains('international format') || lower.contains('формат номера')) {
        return 'Неверный номер. Введите 9 цифр (например 927203002).';
      }
      if (lower.contains('incorrect otp') || lower.contains('неверный код')) {
        return 'Неверный код. Проверьте и попробуйте снова.';
      }
      if (lower.contains('expired') || lower.contains('истек')) {
        return 'Код устарел. Запросите новый код.';
      }
      if (lower.contains('not requested') || lower.contains('не был запрошен')) {
        return 'Сначала запросите код.';
      }
      if (sendStep && (lower.contains('too many') || lower.contains('превышено'))) {
        return 'Слишком много попыток. Подождите немного.';
      }
      return message;
    }
    return sendStep ? 'Не удалось отправить код. Попробуйте позже.' : 'Не удалось подтвердить код.';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: AutofillGroup(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вход по SMS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: const InputDecoration(
                labelText: 'Телефон (9 цифр)',
                hintText: '9XXXXXXXX',
              ),
              onChanged: (v) {
                if (v.length > 9) {
                  _phoneCtrl.text = v.substring(0, 9);
                  _phoneCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _phoneCtrl.text.length),
                  );
                }
                // Reset step state when phone changes.
                if (_codeSent) {
                  setState(() {
                    _codeSent = false;
                    _secondsLeft = 0;
                    _autoVerifyTriggered = false;
                    _isRegistered = true;
                  });
                  _timer?.cancel();
                  _codeCtrl.clear();
                  _refCtrl.clear();
                }
                // Stop auto resend once user started typing code.
                if (_codeCtrl.text.trim().isNotEmpty) {
                  _autoResendEnabled = false;
                }
              },
            ),
            const SizedBox(height: 10),
            if (_codeSent) ...[
              if (!_isRegistered) ...[
                TextField(
                  controller: _refCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Реферальный код',
                    hintText: 'Например: Z24ILP6X',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: 'Код (4 цифры)',
                  suffixText: _secondsLeft > 0 ? '${_secondsLeft}s' : '0s',
                ),
                onChanged: (_) {
                  if (_codeCtrl.text.trim().isNotEmpty) {
                    _autoResendEnabled = false;
                  }
                  if (_codeCtrl.text.trim().length == 4 && !_verifying && !_autoVerifyTriggered) {
                    _autoVerifyTriggered = true;
                    _verify();
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _verifying ? null : _verify,
                      child: _verifying
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Подтвердить'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _sending || _secondsLeft > 0 ? null : () => _sendCode(),
                  child: Text(
                    _secondsLeft > 0
                        ? 'Отправить еще раз через ${_secondsLeft}s'
                        : 'Отправить еще раз',
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending ? null : () => _sendCode(),
                  child: _sending
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Отправить код'),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

