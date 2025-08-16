import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class LocaleService extends StateNotifier<Locale> {
  static const String _boxName = 'settings';
  static const String _localeKey = 'locale';
  Box? _settingsBox;

  LocaleService() : super(const Locale('en')) {
    _init();
  }

  Future<void> _init() async {
    try {
      _settingsBox = await Hive.openBox(_boxName);
      final savedLocale = _settingsBox?.get(_localeKey);
      if (savedLocale != null) {
        state = Locale(savedLocale);
      } else {
        // Try to detect system locale
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        if (systemLocale.languageCode == 'de') {
          state = const Locale('de');
          await _settingsBox?.put(_localeKey, 'de');
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize LocaleService: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _settingsBox?.put(_localeKey, locale.languageCode);
  }

  void toggleLocale() {
    final newLocale = state.languageCode == 'en' 
        ? const Locale('de') 
        : const Locale('en');
    setLocale(newLocale);
  }

  // Format date based on current locale
  String formatDate(DateTime date, {String? pattern}) {
    final locale = state.languageCode;
    if (pattern != null) {
      return DateFormat(pattern, locale).format(date);
    }
    // Default format: day month year for German, month day year for English
    return locale == 'de' 
        ? DateFormat('dd.MM.yyyy', locale).format(date)
        : DateFormat('MM/dd/yyyy', locale).format(date);
  }

  String formatDateTime(DateTime dateTime) {
    final locale = state.languageCode;
    return locale == 'de'
        ? DateFormat('dd.MM.yyyy HH:mm', locale).format(dateTime)
        : DateFormat('MM/dd/yyyy h:mm a', locale).format(dateTime);
  }

  String formatMonthYear(DateTime date) {
    final locale = state.languageCode;
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  String formatWeekday(DateTime date) {
    final locale = state.languageCode;
    return DateFormat('EEEE', locale).format(date);
  }

  // Format currency (Euro only)
  String formatCurrency(double amount) {
    final locale = state.languageCode;
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format decimal numbers
  String formatDecimal(double number, {int decimalDigits = 2}) {
    final locale = state.languageCode;
    final formatter = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return formatter.format(number);
  }

  // Get month names for charts and displays
  List<String> getMonthNames() {
    final locale = state.languageCode;
    final formatter = DateFormat('MMMM', locale);
    return List.generate(12, (index) {
      final date = DateTime(2024, index + 1);
      return formatter.format(date);
    });
  }

  // Get abbreviated month names
  List<String> getMonthNamesShort() {
    final locale = state.languageCode;
    final formatter = DateFormat('MMM', locale);
    return List.generate(12, (index) {
      final date = DateTime(2024, index + 1);
      return formatter.format(date);
    });
  }

  // Get weekday names
  List<String> getWeekdayNames() {
    final locale = state.languageCode;
    final formatter = DateFormat('EEEE', locale);
    // Start from Monday for German, Sunday for English
    final startDay = locale == 'de' ? 1 : 0;
    return List.generate(7, (index) {
      final date = DateTime(2024, 1, startDay + index);
      return formatter.format(date);
    });
  }

  // Get abbreviated weekday names
  List<String> getWeekdayNamesShort() {
    final locale = state.languageCode;
    final formatter = DateFormat('E', locale);
    final startDay = locale == 'de' ? 1 : 0;
    return List.generate(7, (index) {
      final date = DateTime(2024, 1, startDay + index);
      return formatter.format(date);
    });
  }
}

// Provider for locale service
final localeServiceProvider = StateNotifierProvider<LocaleService, Locale>((ref) {
  return LocaleService();
});