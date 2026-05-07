import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../ui/navigation/shop_layer_app_bar.dart';

class MyDataScreen extends ConsumerStatefulWidget {
  const MyDataScreen({super.key});

  @override
  ConsumerState<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends ConsumerState<MyDataScreen> {
  final _fullNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).profile;
    if (profile != null) {
      _fullNameCtrl.text = '${profile.firstName} ${profile.lastName}'.trim();
      _addressCtrl.text = profile.address;
      final parsedBirth = profile.birthDate == null ? null : DateTime.tryParse(profile.birthDate!);
      if (parsedBirth != null) {
        _birthDateCtrl.text = _displayDate(parsedBirth);
      }
    }
  }

  String _displayDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d.$m.$y';
  }

  DateTime? _parseDisplayDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _parseDisplayDate(_birthDateCtrl.text) ?? DateTime(now.year - 20, 1, 1);
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      initialDate: initial.isAfter(now) ? now : initial,
      locale: const Locale('ru'),
    );
    if (selected == null) return;
    setState(() => _birthDateCtrl.text = _displayDate(selected));
  }

  Future<void> _save() async {
    final profile = ref.read(authControllerProvider).profile;
    if (profile == null) return;

    final fullName = _fullNameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final birth = _birthDateCtrl.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя и фамилию')),
      );
      return;
    }

    final parsedBirth = birth.isEmpty ? null : _parseDisplayDate(birth);
    if (birth.isNotEmpty && parsedBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите дату в формате ДД.ММ.ГГГГ')),
      );
      return;
    }

    final parts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final firstName = parts.isEmpty ? '' : parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfileData(
            firstName: firstName,
            lastName: lastName,
            address: address,
            birthDate: parsedBirth?.toIso8601String().split('T').first,
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _addressCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои данные'),
        actions: shopLayerAppBarActions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _fullNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Ному Насаб',
              hintText: 'Имя Фамилия',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Адрес',
              hintText: 'Введите адрес',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _birthDateCtrl,
            readOnly: true,
            onTap: _pickBirthDate,
            decoration: InputDecoration(
              labelText: 'Дата рождения',
              hintText: 'ДД.ММ.ГГГГ',
              suffixIcon: IconButton(
                onPressed: _pickBirthDate,
                icon: const Icon(Icons.calendar_month),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
}
