import 'dart:convert';

/// How a setting is stored in SharedPreferences.
enum SettingType { boolean, integer, decimal, string, stringList }

/// A user setting that backups carry and adb commands can change, with the values its getter copes with.
class SettingSpec {
  final String key;
  final SettingType type;

  /// The only values a string setting accepts; null accepts any string.
  final List<String>? choices;

  /// Regular expression a string setting has to match.
  final String? pattern;

  final num? min;
  final num? max;

  /// Credentials: they can be set over adb, but are never exported or printed.
  final bool secret;

  const SettingSpec(
    this.key,
    this.type, {
    this.choices,
    this.pattern,
    this.min,
    this.max,
    this.secret = false,
  });

  SettingSpec.choice(this.key, List<Enum> values)
      : type = SettingType.string,
        choices = [for (final value in values) value.name],
        pattern = null,
        min = null,
        max = null,
        secret = false;

  /// Converts [value], from JSON or typed in an adb command, to the stored type.
  ///
  /// Throws a [FormatException] naming the expected values when it does not fit.
  Object coerce(Object? value) {
    switch (type) {
      case SettingType.boolean:
        if (value is bool) {
          return value;
        }
        final text = value?.toString().trim().toLowerCase();
        if (const ["true", "1", "on", "yes"].contains(text)) {
          return true;
        }
        if (const ["false", "0", "off", "no"].contains(text)) {
          return false;
        }
        throw FormatException("$key expects true or false, got $value");
      case SettingType.integer:
        final number = value is num ? value : num.tryParse(value?.toString().trim() ?? "");
        if (number == null || number != number.roundToDouble()) {
          throw FormatException("$key expects a whole number${_rangeText()}, got $value");
        }
        return _checkRange(number.toInt());
      case SettingType.decimal:
        final number = value is num ? value : num.tryParse(value?.toString().trim() ?? "");
        if (number == null || !number.isFinite) {
          throw FormatException("$key expects a number${_rangeText()}, got $value");
        }
        return _checkRange(number.toDouble());
      case SettingType.string:
        if (value is! String && value is! num) {
          throw FormatException("$key expects text, got $value");
        }
        final text = value.toString();
        if (choices != null && !choices!.contains(text)) {
          throw FormatException("$key expects one of ${choices!.map(_quoted).join(", ")}, got ${_quoted(text)}");
        }
        if (pattern != null && !RegExp(pattern!).hasMatch(text)) {
          throw FormatException("$key expects text matching $pattern, got ${_quoted(text)}");
        }
        return text;
      case SettingType.stringList:
        Object? list = value;
        if (list is String) {
          final text = list.trim();
          list = text.startsWith("[")
              ? _decodeList(text)
              : text.split(",").map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
        }
        if (list is! List) {
          throw FormatException("$key expects a list, got $value");
        }
        return [for (final item in list) item.toString()];
    }
  }

  /// One line for `help`: the key, its type and what it accepts.
  String describe() {
    final String accepts;
    switch (type) {
      case SettingType.boolean:
        accepts = "true|false";
      case SettingType.integer:
        accepts = "integer${_rangeText()}";
      case SettingType.decimal:
        accepts = "number${_rangeText()}";
      case SettingType.string:
        accepts = choices != null
            ? choices!.map((choice) => choice.isEmpty ? '""' : choice).join("|")
            : pattern != null
                ? "text matching $pattern"
                : "text";
      case SettingType.stringList:
        accepts = "comma-separated list or JSON array";
    }
    return "$key: $accepts${secret ? " (secret)" : ""}";
  }

  T _checkRange<T extends num>(T number) {
    if ((min != null && number < min!) || (max != null && number > max!)) {
      throw FormatException("$key expects a value${_rangeText()}, got $number");
    }
    return number;
  }

  String _rangeText() {
    if (min != null && max != null) {
      return " from $min to $max";
    }
    if (min != null) {
      return " of at least $min";
    }
    if (max != null) {
      return " up to $max";
    }
    return "";
  }

  Object? _decodeList(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      throw FormatException("$key expects a JSON array, got $text");
    }
  }

  static String _quoted(String text) => '"$text"';
}
