String formatMinutes(
  int minutes, {
  String? localeCode,
  bool signed = false,
  bool showPlusForZero = false,
  bool padMinutes = false,
}) {
  final normalizedLocale = (localeCode ?? '').toLowerCase();
  final isSwedish = normalizedLocale.startsWith('sv');
  final absoluteMinutes = minutes.abs();
  final hours = absoluteMinutes ~/ 60;
  final mins = absoluteMinutes % 60;
  final minuteText = padMinutes ? mins.toString().padLeft(2, '0') : '$mins';

  final base = isSwedish
      ? '$hours h $minuteText min'
      : '${hours}h ${minuteText}m';

  if (!signed) {
    return base;
  }

  String sign = '';
  if (minutes < 0) {
    sign = '-';
  } else if (minutes > 0 || showPlusForZero) {
    sign = '+';
  }

  return '$sign$base';
}

String formatSignedMinutes(
  int minutes, {
  String? localeCode,
  bool showPlusForZero = false,
  bool padMinutes = true,
}) {
  return formatMinutes(
    minutes,
    localeCode: localeCode,
    signed: true,
    showPlusForZero: showPlusForZero,
    padMinutes: padMinutes,
  );
}
