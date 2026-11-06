import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);

/// "$24.99" — prices are shown in USD, like on the web app.
String money(num amount) => _money.format(amount);

/// "Oct 26, 2026".
String day(DateTime date) => DateFormat.yMMMd('en_US').format(date);
