import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
final _moneyRound = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 0);

/// "$1,100" or "$22.50" — amounts are USD, like on the web app.
String formatMoney(num amount) =>
    amount == amount.roundToDouble() ? _moneyRound.format(amount) : _money.format(amount);

/// "Oct 30, 2026".
String formatDay(DateTime date) => DateFormat.yMMMd('en_US').format(date);

/// "Oct 30, 2026 · 14:05".
String formatDateTime(DateTime date) => DateFormat('MMM d, y · HH:mm', 'en_US').format(date);
