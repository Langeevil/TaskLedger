class AppCurrencyUtils {
  static double parse(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return parseBrazilian(value);
    }
    return 0;
  }

  static double parseBrazilian(String value) {
    final cleanText = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (cleanText.isEmpty) {
      return 0;
    }

    final normalized = cleanText.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  static String format(double value) {
    final number = formatNumber(value.abs());
    final sign = value < 0 ? '-' : '';
    return '${sign}R\$ $number';
  }

  static String formatNumber(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];
    final buffer = StringBuffer();

    for (int i = 0; i < integer.length; i++) {
      final remainingIndex = integer.length - i;
      buffer.write(integer[i]);
      if (remainingIndex > 1 && remainingIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()},$decimal';
  }
}
