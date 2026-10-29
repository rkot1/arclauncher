import 'package:flauncher/models/setting_spec.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Mode { off, on }

void main() {
  test("booleans accept JSON and typed values", () {
    const spec = SettingSpec("flag", SettingType.boolean);
    expect(spec.coerce(true), isTrue);
    expect(spec.coerce("on"), isTrue);
    expect(spec.coerce("0"), isFalse);
    expect(() => spec.coerce("maybe"), throwsFormatException);
  });

  test("numbers are parsed and kept in range", () {
    const integer = SettingSpec("count", SettingType.integer, min: 0, max: 50);
    expect(integer.coerce("12"), 12);
    expect(integer.coerce(12.0), isA<int>());
    expect(() => integer.coerce("1.5"), throwsFormatException);
    expect(() => integer.coerce(51), throwsFormatException);

    const decimal = SettingSpec("size", SettingType.decimal, min: 6, max: 48);
    expect(decimal.coerce("14"), isA<double>().having((value) => value, "value", 14));
    expect(() => decimal.coerce("big"), throwsFormatException);
    expect(() => decimal.coerce(4), throwsFormatException);
  });

  test("strings are checked against choices and patterns", () {
    final choice = SettingSpec.choice("mode", _Mode.values);
    expect(choice.coerce("on"), "on");
    expect(
      () => choice.coerce("auto"),
      throwsA(isA<FormatException>().having((e) => e.message, "message", contains('"off", "on"'))),
    );

    const hex = SettingSpec("color", SettingType.string, pattern: r"^[0-9A-Fa-f]{6}$");
    expect(hex.coerce("7C4DFF"), "7C4DFF");
    expect(() => hex.coerce("purple"), throwsFormatException);
  });

  test("lists accept JSON arrays and comma-separated text", () {
    const spec = SettingSpec("list", SettingType.stringList);
    expect(spec.coerce(["a", "b"]), ["a", "b"]);
    expect(spec.coerce('["a", "b"]'), ["a", "b"]);
    expect(spec.coerce("a, b,,c"), ["a", "b", "c"]);
    expect(() => spec.coerce(3), throwsFormatException);
  });

  test("describe names the accepted values", () {
    expect(SettingSpec.choice("mode", _Mode.values).describe(), "mode: off|on");
    expect(const SettingSpec("size", SettingType.decimal, min: 6, max: 48).describe(), "size: number from 6 to 48");
    expect(const SettingSpec("key", SettingType.string, secret: true).describe(), "key: text (secret)");
  });
}
