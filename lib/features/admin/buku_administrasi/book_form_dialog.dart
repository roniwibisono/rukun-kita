import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'buku_administrasi_field_config.dart';

/// Dialog form terstruktur — 1 [TextFormField]/[DropdownButtonFormField]
/// per kolom, dibangun dari [BookField] config. Menggantikan editor JSON
/// mentah agar pengurus RT tidak perlu tahu nama kolom/format tanggal.
///
/// Mengembalikan `Map<String, dynamic>` siap kirim ke
/// `supabase.from(table).insert(...)`/`.update(...)` saat "Simpan" ditekan,
/// atau `null` jika dibatalkan.
class BookFormDialog extends StatefulWidget {
  const BookFormDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.supabase,
    this.initialRow,
  });

  final String title;
  final List<BookField> fields;
  final SupabaseClient supabase;
  final Map<String, dynamic>? initialRow;

  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, DateTime?> _dateValues = {};
  final Map<String, TimeOfDay?> _timeValues = {};
  final Map<String, String?> _dropdownValues = {};

  /// Cache opsi dropdown referensi per refTable, di-load sekali saat dialog dibuka.
  final Map<String, Future<List<Map<String, dynamic>>>> _refOptionsFuture = {};

  static final _dateFormat = DateFormat('dd MMM yyyy', 'id');

  @override
  void initState() {
    super.initState();

    for (final field in widget.fields) {
      final rawValue = widget.initialRow?[field.key];

      switch (field.type) {
        case BookFieldType.text:
        case BookFieldType.multiline:
          _controllers[field.key] =
              TextEditingController(text: rawValue?.toString() ?? '');
          break;
        case BookFieldType.integer:
        case BookFieldType.decimal:
          _controllers[field.key] =
              TextEditingController(text: rawValue?.toString() ?? '');
          break;
        case BookFieldType.date:
          _dateValues[field.key] =
              rawValue == null ? null : DateTime.tryParse(rawValue.toString());
          break;
        case BookFieldType.time:
          _timeValues[field.key] = _parseTimeOfDay(rawValue?.toString());
          break;
        case BookFieldType.dropdownEnum:
          _dropdownValues[field.key] = rawValue?.toString();
          break;
        case BookFieldType.dropdownRef:
          _dropdownValues[field.key] = rawValue?.toString();
          _refOptionsFuture.putIfAbsent(
            field.refTable!,
            () {
              final displayColumns =
                  bookRefDisplayColumns[field.refTable!] ?? const <String>[];
              final selectColumns = {'id', ...displayColumns}.join(',');
              final query =
                  widget.supabase.from(field.refTable!).select(selectColumns);
              final future = displayColumns.isEmpty
                  ? query
                  : query.order(displayColumns.first);
              return future.then((rows) => rows.cast<Map<String, dynamic>>());
            },
          );
          break;
      }
    }
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null) return null;
    // Format Postgres `time`: "HH:mm:ss" atau "HH:mm".
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in widget.fields) ...[
                  _buildField(field),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildField(BookField field) {
    switch (field.type) {
      case BookFieldType.text:
        return TextFormField(
          controller: _controllers[field.key],
          decoration: InputDecoration(
            labelText: _labelWithHint(field),
            helperText: field.hint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) => _requiredValidator(field, value),
        );

      case BookFieldType.multiline:
        return TextFormField(
          controller: _controllers[field.key],
          maxLines: 3,
          decoration: InputDecoration(
            labelText: _labelWithHint(field),
            helperText: field.hint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) => _requiredValidator(field, value),
        );

      case BookFieldType.integer:
        return TextFormField(
          controller: _controllers[field.key],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _labelWithHint(field),
            helperText: field.hint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final requiredError = _requiredValidator(field, value);
            if (requiredError != null) return requiredError;
            if (value != null &&
                value.trim().isNotEmpty &&
                int.tryParse(value.trim()) == null) {
              return 'Harus berupa angka bulat';
            }
            return null;
          },
        );

      case BookFieldType.decimal:
        return TextFormField(
          controller: _controllers[field.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _labelWithHint(field),
            helperText: field.hint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final requiredError = _requiredValidator(field, value);
            if (requiredError != null) return requiredError;
            if (value != null &&
                value.trim().isNotEmpty &&
                double.tryParse(value.trim()) == null) {
              return 'Harus berupa angka';
            }
            return null;
          },
        );

      case BookFieldType.date:
        final value = _dateValues[field.key];
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _dateValues[field.key] = picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: _labelWithHint(field),
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              value == null ? 'Pilih tanggal' : _dateFormat.format(value),
              style: value == null
                  ? TextStyle(color: Theme.of(context).hintColor)
                  : null,
            ),
          ),
        );

      case BookFieldType.time:
        final value = _timeValues[field.key];
        return InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value ?? TimeOfDay.now(),
            );
            if (picked != null) setState(() => _timeValues[field.key] = picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: _labelWithHint(field),
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.access_time_outlined, size: 18),
            ),
            child: Text(
              value == null ? 'Pilih waktu' : value.format(context),
              style: value == null
                  ? TextStyle(color: Theme.of(context).hintColor)
                  : null,
            ),
          ),
        );

      case BookFieldType.dropdownEnum:
        return DropdownButtonFormField<String>(
          initialValue: _dropdownValues[field.key],
          decoration: InputDecoration(
              labelText: _labelWithHint(field),
              border: const OutlineInputBorder()),
          items: [
            for (final option in field.options)
              DropdownMenuItem(value: option.value, child: Text(option.label)),
          ],
          onChanged: (value) =>
              setState(() => _dropdownValues[field.key] = value),
          validator: (value) => _requiredDropdownValidator(field, value),
        );

      case BookFieldType.dropdownRef:
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _refOptionsFuture[field.refTable!],
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: _labelWithHint(field),
                  border: const OutlineInputBorder(),
                  errorText: 'Referensi gagal dimuat',
                ),
                child: Text('${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: _labelWithHint(field),
                  border: const OutlineInputBorder(),
                ),
                child: const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final options = snapshot.data!;
            return DropdownButtonFormField<String>(
              initialValue: _dropdownValues[field.key],
              isExpanded: true,
              decoration: InputDecoration(
                  labelText: _labelWithHint(field),
                  border: const OutlineInputBorder()),
              items: [
                for (final row in options)
                  DropdownMenuItem(
                    value: row['id'] as String,
                    child: Text(
                      bookRefDisplayLabel(field.refTable!, row),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _dropdownValues[field.key] = value),
              validator: (value) => _requiredDropdownValidator(field, value),
            );
          },
        );
    }
  }

  String _labelWithHint(BookField field) {
    final suffix = field.required ? '' : ' (opsional)';
    return '${field.label}$suffix';
  }

  String? _requiredValidator(BookField field, String? value) {
    if (!field.required) return null;
    if (value == null || value.trim().isEmpty) {
      return '${field.label} wajib diisi';
    }
    return null;
  }

  String? _requiredDropdownValidator(BookField field, String? value) {
    if (!field.required) return null;
    if (value == null || value.isEmpty) return '${field.label} wajib dipilih';
    return null;
  }

  void _submit() {
    // Validasi tambahan untuk date/time wajib (tidak tercakup Form validator
    // biasa karena bukan TextFormField).
    for (final field in widget.fields) {
      if (!field.required) continue;
      if (field.type == BookFieldType.date && _dateValues[field.key] == null) {
        _showError('${field.label} wajib diisi');
        return;
      }
      if (field.type == BookFieldType.time && _timeValues[field.key] == null) {
        _showError('${field.label} wajib diisi');
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    final result = <String, dynamic>{};
    for (final field in widget.fields) {
      switch (field.type) {
        case BookFieldType.text:
        case BookFieldType.multiline:
          final text = _controllers[field.key]!.text.trim();
          result[field.key] = text.isEmpty ? null : text;
          break;
        case BookFieldType.integer:
          final text = _controllers[field.key]!.text.trim();
          result[field.key] = text.isEmpty ? null : int.parse(text);
          break;
        case BookFieldType.decimal:
          final text = _controllers[field.key]!.text.trim();
          result[field.key] = text.isEmpty ? null : double.parse(text);
          break;
        case BookFieldType.date:
          final date = _dateValues[field.key];
          result[field.key] = date?.toIso8601String().split('T').first;
          break;
        case BookFieldType.time:
          final time = _timeValues[field.key];
          result[field.key] = time == null
              ? null
              : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
          break;
        case BookFieldType.dropdownEnum:
        case BookFieldType.dropdownRef:
          result[field.key] = _dropdownValues[field.key];
          break;
      }
    }

    Navigator.pop(context, result);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
