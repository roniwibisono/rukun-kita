import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final DateFormat _date = DateFormat('dd MMM yyyy', 'id');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy HH:mm', 'id');
  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String date(DateTime value) => _date.format(value.toLocal());

  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());

  static String rupiah(num value) => _rupiah.format(value);
}
