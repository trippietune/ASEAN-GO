import 'package:flutter/services.dart';

/// Formats digits as "4242 4242 4242 4242" while typing, capped at 19 digits
/// (covers all common card lengths incl. Amex's 15 and some debit cards' 19).
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '').substring(0, _cap(newValue.text));
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }

  int _cap(String text) {
    final digitCount = text.replaceAll(RegExp(r'\D'), '').length;
    return digitCount > 19 ? 19 : digitCount;
  }
}

/// Formats digits as "MM/YY" while typing.
class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.substring(0, digits.length > 4 ? 4 : digits.length);
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(capped[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Standard mod-10 checksum — catches typos before we ever send the card to
/// Omise, so the user gets instant feedback instead of a round trip.
bool isValidLuhn(String digitsOnly) {
  if (digitsOnly.length < 12) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digitsOnly.length - 1; i >= 0; i--) {
    var digit = int.parse(digitsOnly[i]);
    if (alternate) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}
