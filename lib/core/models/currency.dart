enum Currency {
  sy,
  dollar;

  String get value {
    switch (this) {
      case Currency.sy:
        return 'SYP';
      case Currency.dollar:
        return 'USD';
    }
  }

  String get displayName {
    switch (this) {
      case Currency.sy:
        return 'ليرة سورية';
      case Currency.dollar:
        return 'دولار';
    }
  }

  String get symbol {
    switch (this) {
      case Currency.sy:
        return 'ل.س';
      case Currency.dollar:
        return '\$';
    }
  }

  static Currency fromString(String value) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) return Currency.sy;

    final normalized = cleanValue.toUpperCase();

    for (final currency in Currency.values) {
      if (currency.value == normalized ||
          currency.name.toUpperCase() == normalized ||
          currency.symbol == cleanValue ||
          currency.displayName == cleanValue) {
        return currency;
      }
    }

    if (normalized.contains('SY') || normalized.contains('SYP')) {
      return Currency.sy;
    }
    if (normalized.contains('USD') || normalized.contains('DOLLAR')) {
      return Currency.dollar;
    }

    return Currency.sy;
  }
}
