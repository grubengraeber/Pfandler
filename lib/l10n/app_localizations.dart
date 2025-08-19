import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'appName': 'Pfandler',
      'language': 'English',
      
      // Auth
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'signOut': 'Sign Out',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'forgotPassword': 'Forgot Password?',
      'alreadyHaveAccount': 'Already have an account?',
      'dontHaveAccount': 'Don\'t have an account?',
      'signInToSync': 'Sign In to Sync Data',
      'signOutConfirmTitle': 'Sign Out',
      'signOutConfirmMessage': 'Are you sure you want to sign out? Your local data will be preserved.',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'signedOutSuccess': 'Signed out successfully',
      'notSignedIn': 'Not signed in',
      'guestUser': 'Guest User',
      'accountCreated': 'Account created successfully!',
      'createAccount': 'Create Your Account',
      'signUpDescription': 'Sign up to sync your bottles across devices',
      'signInDescription': 'Sign in to access your bottle collection',
      'enterEmail': 'Please enter your email',
      'enterPassword': 'Please enter your password',
      'invalidEmail': 'Please enter a valid email',
      'passwordTooShort': 'Password must be at least 6 characters',
      'signInSuccess': 'Successfully signed in',
      
      // Navigation
      'home': 'Home',
      'bottles': 'Bottles',
      'map': 'Map',
      'analytics': 'Analytics',
      'profile': 'Profile',
      'settings': 'Settings',
      'stores': 'Stores',
      'appearance': 'Appearance',
      'dataPrivacy': 'Data & Privacy',
      'scanner': 'Scanner',
      'about': 'About',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'chooseTheme': 'Choose Theme',
      'export': 'Export',
      'exportData': 'Export Data',
      'exportDescription': 'Export as CSV or JSON',
      'chooseExportFormat': 'Choose export format:',
      'autoScan': 'Auto-Scan',
      'autoScanDescription': 'Automatically scan when camera opens',
      'scanSound': 'Scan Sound',
      'scanSoundDescription': 'Play sound on successful scan',
      'vibration': 'Vibration',
      'vibrationDescription': 'Vibrate on successful scan',
      'navigation': 'Navigation',
      'general': 'General',
      'support': 'Support',
      'contactSupport': 'Contact Support',
      'viewStatistics': 'View your statistics',
      'manageAccount': 'Manage your account',
      'bottleReturnManager': 'Bottle Return Manager',
      
      // Home Screen
      'welcomeBack': 'Welcome back',
      'welcomeDescription': 'Your bottle deposit tracking app',
      'findReturnLocations': 'Find Return Locations',
      'searchStores': 'Search stores...',
      'quickStats': 'Quick Stats',
      'recentActivity': 'Recent Activity',
      'totalBottles': 'Total Bottles',
      'totalEarned': 'Total Earned',
      'totalValue': 'Total Value',
      'unknown': 'Unknown',
      'weekAbbr': 'W',
      'errorLoadingDepositData': 'Error loading deposit data',
      'errorLoadingChartData': 'Error loading chart data',
      'errorLoadingStats': 'Error loading stats',
      'failedToCaptureScreenshot': 'Failed to capture screenshot',
      'pendingReturns': 'Pending Returns',
      'viewAll': 'View All',
      'noRecentActivity': 'No recent activity',
      
      // Bottles
      'addBottle': 'Add Bottle',
      'scanBarcode': 'Scan Barcode',
      'manualEntry': 'Manual Entry',
      'quickScanCamera': 'Quick scan using camera',
      'addBottleManually': 'Add bottle details manually',
      'viewScannedBottles': 'View scanned bottles',
      'signInToViewBottles': 'Please sign in to view your bottles',
      'syncFailed': 'Sync failed',
      'noBottlesYet': 'No bottles scanned yet',
      'startScanning': 'Start scanning bottles to track your returns',
      'bottleType': 'Bottle Type',
      'plastic': 'Plastic',
      'glass': 'Glass',
      'can': 'Can',
      'crate': 'Crate',
      'cans': 'Cans',
      'crates': 'Crates',
      'plastic025': 'Plastic 0.25L',
      'plastic05': 'Plastic 0.5L',
      'plastic1': 'Plastic 1L',
      'plastic15': 'Plastic 1.5L',
      'other': 'Other',
      'volume': 'Volume',
      'depositAmount': 'Deposit Amount',
      'brand': 'Brand',
      'productName': 'Product Name',
      'barcode': 'Barcode',
      'scannedAt': 'Scanned at',
      'returnedAt': 'Returned at',
      'markAsReturned': 'Mark as Returned',
      'markAsPending': 'Mark as Pending',
      'deleteBottle': 'Delete Bottle',
      'bottleAdded': 'Bottle added successfully',
      'bottleUpdated': 'Bottle updated successfully',
      'bottleDeleted': 'Bottle deleted successfully',
      'scanToAddBottle': 'Scan barcode to add bottle',
      'nBottles': '{count} bottles',
      'allBottles': 'All Bottles',
      'returnedBottles': 'Returned',
      'pendingBottles': 'Pending',
      'alignBarcodeWithinFrame': 'Align barcode within frame',
      'orEnterBarcodeManually': 'Or Enter Barcode Manually',
      'barcodeNumber': 'Barcode Number',
      'enterBarcodeDigits': 'Enter barcode digits',
      'lookUp': 'Look up',
      'searching': 'Searching...',
      'tips': 'Tips',
      'tipPointCamera': 'Point camera at barcode and hold steady',
      'tipUseTorch': 'Use torch button in low light conditions',
      'tipCleanBarcode': 'Clean the barcode for better scanning',
      'tipAustrianBottles': 'Most Austrian deposit bottles have 13-digit EAN codes',
      'productNotFound': 'Product Not Found',
      'noProductFound': 'No product found for barcode',
      'wouldYouLikeToAddManually': 'Would you like to add it manually?',
      'addManually': 'Add Manually',
      'barcodeScanned': 'Barcode Scanned',
      'addToCollection': 'Add to Collection',
      'bottleAddedSuccess': 'Bottle added successfully!',
      'failedToAddBottle': 'Failed to add bottle',
      'errorLookingUpBarcode': 'Error looking up barcode',
      'pleaseEnterBarcode': 'Please enter a barcode',
      'scanAnother': 'Scan Another',
      
      // Map
      'nearbyStores': 'Nearby Stores',
      'allStores': 'All Stores',
      'openNow': 'Open Now',
      'closedNow': 'Closed',
      'opensAt': 'Opens at {time}',
      'closesAt': 'Closes at {time}',
      'returnMachine': 'Return Machine',
      'machines': 'machines',
      'acceptedTypes': 'Accepted Types',
      'directions': 'Directions',
      'call': 'Call',
      'distanceKm': '{distance} km',
      'distanceM': '{distance} m',
      'locationPermissionRequired': 'Location permission required',
      'enableLocationMessage': 'Please enable location services to see nearby stores',
      'openSettings': 'Open Settings',
      'address': 'Address',
      'acceptedDepositTypes': 'Accepted Deposit Types',
      'getDirections': 'Get Directions',
      'returnHere': 'Return Here',
      'storesInArea': '{count} stores in this area',
      'tapStoreToViewDetails': 'Tap a store to view details',
      
      // Analytics
      'statistics': 'Statistics',
      'returnTrend': 'Return Trend',
      'depositTypes': 'Deposit Types',
      'bottleTypes': 'Bottle Types',
      'daily': 'Daily',
      'weekly': 'Weekly', 
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'averagePerDay': 'Avg/Day',
      'mostCommon': 'Most Common',
      'noData': 'No Data',
      'shareAnalytics': 'Check out my Pfandler bottle return analytics!',
      'failedToShare': 'Failed to share analytics',
      
      // Settings
      'accountSettings': 'Account Settings',
      'appSettings': 'App Settings',
      'darkMode': 'Dark Mode',
      'notifications': 'Notifications',
      'languageSettings': 'Language',
      'selectLanguage': 'Select Language',
      'german': 'German',
      'english': 'English',
      'aboutApp': 'About App',
      'version': 'Version',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      
      // Errors
      'error': 'Error',
      'errorOccurred': 'An error occurred',
      'tryAgain': 'Try Again',
      'networkError': 'Network error. Please check your connection.',
      'passwordsDoNotMatch': 'Passwords do not match',
      'emailAlreadyInUse': 'Email already in use',
      'invalidCredentials': 'Invalid email or password',
      'somethingWentWrong': 'Something went wrong',
      
      // Success Messages
      'success': 'Success',
      'savedSuccessfully': 'Saved successfully',
      'updatedSuccessfully': 'Updated successfully',
      'deletedSuccessfully': 'Deleted successfully',
      
      // Date & Time
      'today': 'Today',
      'yesterday': 'Yesterday',
      'tomorrow': 'Tomorrow',
      'now': 'Now',
      'justNow': 'Just now',
      'minutesAgo': '{count} minutes ago',
      'hoursAgo': '{count} hours ago',
      'daysAgo': '{count} days ago',
      
      // Store Chains
      'storeBilla': 'Billa',
      'storeBillaPlus': 'Billa Plus',
      'storeSpar': 'Spar',
      'storeEurospar': 'Eurospar',
      'storeInterspar': 'Interspar',
      'storeHofer': 'Hofer',
      'storeLidl': 'Lidl',
      'storePenny': 'Penny',
      'storeMerkur': 'Merkur',
      'storeMpreis': 'MPreis',
      'storeOther': 'Other',
      
      // Days of Week
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
      
      // Months
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mar',
      'apr': 'Apr',
      'mayShort': 'May',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Aug',
      'sep': 'Sep',
      'oct': 'Oct',
      'nov': 'Nov',
      'dec': 'Dec',
    },
    'de': {
      // App
      'appName': 'Pfandler',
      'language': 'Deutsch',
      
      // Auth
      'signIn': 'Anmelden',
      'signUp': 'Registrieren',
      'signOut': 'Abmelden',
      'email': 'E-Mail',
      'password': 'Passwort',
      'confirmPassword': 'Passwort bestätigen',
      'forgotPassword': 'Passwort vergessen?',
      'alreadyHaveAccount': 'Bereits ein Konto?',
      'dontHaveAccount': 'Noch kein Konto?',
      'signInToSync': 'Anmelden zum Synchronisieren',
      'signOutConfirmTitle': 'Abmelden',
      'signOutConfirmMessage': 'Möchten Sie sich wirklich abmelden? Ihre lokalen Daten bleiben erhalten.',
      'cancel': 'Abbrechen',
      'confirm': 'Bestätigen',
      'signedOutSuccess': 'Erfolgreich abgemeldet',
      'notSignedIn': 'Nicht angemeldet',
      'guestUser': 'Gastbenutzer',
      
      // Navigation
      'home': 'Start',
      'bottles': 'Flaschen',
      'map': 'Karte',
      'analytics': 'Statistik',
      'profile': 'Profil',
      'settings': 'Einstellungen',
      'stores': 'Geschäfte',
      'appearance': 'Erscheinungsbild',
      'dataPrivacy': 'Daten & Datenschutz',
      'scanner': 'Scanner',
      'about': 'Über',
      'theme': 'Design',
      'light': 'Hell',
      'dark': 'Dunkel',
      'system': 'System',
      'chooseTheme': 'Design wählen',
      'export': 'Export',
      'exportData': 'Daten exportieren',
      'exportDescription': 'Als CSV oder JSON exportieren',
      'chooseExportFormat': 'Exportformat wählen:',
      'autoScan': 'Auto-Scan',
      'autoScanDescription': 'Automatisch scannen, wenn Kamera öffnet',
      'scanSound': 'Scan-Ton',
      'scanSoundDescription': 'Ton bei erfolgreichem Scan abspielen',
      'vibration': 'Vibration',
      'vibrationDescription': 'Bei erfolgreichem Scan vibrieren',
      'navigation': 'Navigation',
      'general': 'Allgemein',
      'support': 'Unterstützung',
      'contactSupport': 'Support kontaktieren',
      'viewStatistics': 'Ihre Statistiken anzeigen',
      'manageAccount': 'Konto verwalten',
      'bottleReturnManager': 'Flaschenrückgabe-Manager',
      
      // Home Screen
      'welcomeBack': 'Willkommen zurück',
      'welcomeDescription': 'Ihre App zur Pfandflaschen-Verfolgung',
      'findReturnLocations': 'Rückgabestellen finden',
      'quickStats': 'Schnellstatistik',
      'recentActivity': 'Letzte Aktivität',
      'totalBottles': 'Flaschen gesamt',
      'totalEarned': 'Gesamt verdient',
      'totalValue': 'Gesamtwert',
      'unknown': 'Unbekannt',
      'weekAbbr': 'W',
      'errorLoadingDepositData': 'Fehler beim Laden der Pfanddaten',
      'errorLoadingChartData': 'Fehler beim Laden der Diagrammdaten',
      'errorLoadingStats': 'Fehler beim Laden der Statistiken',
      'failedToCaptureScreenshot': 'Screenshot konnte nicht erstellt werden',
      'pendingReturns': 'Ausstehende Rückgaben',
      'viewAll': 'Alle anzeigen',
      'noRecentActivity': 'Keine aktuelle Aktivität',
      
      // Bottles
      'addBottle': 'Flasche hinzufügen',
      'scanBarcode': 'Barcode scannen',
      'manualEntry': 'Manuelle Eingabe',
      'quickScanCamera': 'Schneller Scan mit Kamera',
      'addBottleManually': 'Flaschendetails manuell hinzufügen',
      'viewScannedBottles': 'Gescannte Flaschen anzeigen',
      'signInToViewBottles': 'Bitte melden Sie sich an, um Ihre Flaschen zu sehen',
      'syncFailed': 'Synchronisation fehlgeschlagen',
      'noBottlesYet': 'Noch keine Flaschen gescannt',
      'startScanning': 'Beginnen Sie mit dem Scannen von Flaschen',
      'syncingWithServer': 'Synchronisierung mit Server...',
      'bottleType': 'Flaschentyp',
      'plastic': 'Plastik',
      'glass': 'Glas',
      'can': 'Dose',
      'crate': 'Kiste',
      'cans': 'Dosen',
      'crates': 'Kisten',
      'plastic025': 'Plastik 0,25L',
      'plastic05': 'Plastik 0,5L',
      'plastic1': 'Plastik 1L',
      'plastic15': 'Plastik 1,5L',
      'other': 'Andere',
      'volume': 'Volumen',
      'depositAmount': 'Pfandbetrag',
      'brand': 'Marke',
      'productName': 'Produktname',
      'barcode': 'Barcode',
      'scannedAt': 'Gescannt am',
      'returnedAt': 'Zurückgegeben am',
      'markAsReturned': 'Als zurückgegeben markieren',
      'markAsPending': 'Als ausstehend markieren',
      'deleteBottle': 'Flasche löschen',
      'bottleAdded': 'Flasche erfolgreich hinzugefügt',
      'bottleUpdated': 'Flasche erfolgreich aktualisiert',
      'bottleDeleted': 'Flasche erfolgreich gelöscht',
      'scanToAddBottle': 'Barcode scannen zum Hinzufügen',
      'nBottles': '{count} Flaschen',
      'allBottles': 'Alle Flaschen',
      'returnedBottles': 'Zurückgegeben',
      'pendingBottles': 'Ausstehend',
      'alignBarcodeWithinFrame': 'Barcode im Rahmen ausrichten',
      'orEnterBarcodeManually': 'Oder Barcode manuell eingeben',
      'barcodeNumber': 'Barcode-Nummer',
      'enterBarcodeDigits': 'Barcode-Ziffern eingeben',
      'lookUp': 'Nachschlagen',
      'searching': 'Suche...',
      'tips': 'Tipps',
      'tipPointCamera': 'Kamera auf Barcode richten und ruhig halten',
      'tipUseTorch': 'Taschenlampe bei schlechten Lichtverhältnissen verwenden',
      'tipCleanBarcode': 'Barcode für besseres Scannen reinigen',
      'tipAustrianBottles': 'Die meisten österreichischen Pfandflaschen haben 13-stellige EAN-Codes',
      'productNotFound': 'Produkt nicht gefunden',
      'noProductFound': 'Kein Produkt für Barcode gefunden',
      'wouldYouLikeToAddManually': 'Möchten Sie es manuell hinzufügen?',
      'addManually': 'Manuell hinzufügen',
      'barcodeScanned': 'Barcode gescannt',
      'addToCollection': 'Zur Sammlung hinzufügen',
      'bottleAddedSuccess': 'Flasche erfolgreich hinzugefügt!',
      'failedToAddBottle': 'Fehler beim Hinzufügen der Flasche',
      'errorLookingUpBarcode': 'Fehler beim Nachschlagen des Barcodes',
      'pleaseEnterBarcode': 'Bitte geben Sie einen Barcode ein',
      'scanAnother': 'Weitere scannen',
      
      // Map
      'nearbyStores': 'Geschäfte in der Nähe',
      'searchStores': 'Geschäfte suchen...',
      'allStores': 'Alle Geschäfte',
      'openNow': 'Jetzt geöffnet',
      'closedNow': 'Geschlossen',
      'opensAt': 'Öffnet um {time}',
      'closesAt': 'Schließt um {time}',
      'returnMachine': 'Rückgabeautomat',
      'machines': 'Automaten',
      'acceptedTypes': 'Akzeptierte Typen',
      'directions': 'Route',
      'call': 'Anrufen',
      'distanceKm': '{distance} km',
      'distanceM': '{distance} m',
      'locationPermissionRequired': 'Standortberechtigung erforderlich',
      'enableLocationMessage': 'Bitte aktivieren Sie die Standortdienste, um Geschäfte in der Nähe zu sehen',
      'openSettings': 'Einstellungen öffnen',
      'address': 'Adresse',
      'acceptedDepositTypes': 'Akzeptierte Pfandtypen',
      'getDirections': 'Wegbeschreibung',
      'returnHere': 'Hier zurückgeben',
      'storesInArea': '{count} Geschäfte in diesem Bereich',
      'tapStoreToViewDetails': 'Tippen Sie auf ein Geschäft, um Details anzuzeigen',
      
      // Analytics
      'statistics': 'Statistiken',
      'returnTrend': 'Rückgabetrend',
      'depositTypes': 'Pfandtypen',
      'bottleTypes': 'Flaschentypen',
      'daily': 'Täglich',
      'weekly': 'Wöchentlich',
      'monthly': 'Monatlich',
      'yearly': 'Jährlich',
      'averagePerDay': 'Durchschn./Tag',
      'mostCommon': 'Häufigste',
      'noData': 'Keine Daten',
      'shareAnalytics': 'Schau dir meine Pfandler Flaschenrückgabe-Statistik an!',
      'failedToShare': 'Teilen fehlgeschlagen',
      
      // Settings
      'accountSettings': 'Kontoeinstellungen',
      'appSettings': 'App-Einstellungen',
      'darkMode': 'Dunkler Modus',
      'notifications': 'Benachrichtigungen',
      'languageSettings': 'Sprache',
      'selectLanguage': 'Sprache auswählen',
      'german': 'Deutsch',
      'english': 'Englisch',
      'aboutApp': 'Über die App',
      'version': 'Version',
      'privacyPolicy': 'Datenschutz',
      'termsOfService': 'Nutzungsbedingungen',
      
      // Errors
      'error': 'Fehler',
      'errorOccurred': 'Ein Fehler ist aufgetreten',
      'tryAgain': 'Erneut versuchen',
      'networkError': 'Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung.',
      'invalidEmail': 'Bitte geben Sie eine gültige E-Mail ein',
      'passwordTooShort': 'Passwort muss mindestens 6 Zeichen lang sein',
      'passwordsDoNotMatch': 'Passwörter stimmen nicht überein',
      'emailAlreadyInUse': 'E-Mail bereits in Verwendung',
      'invalidCredentials': 'Ungültige E-Mail oder Passwort',
      'somethingWentWrong': 'Etwas ist schiefgelaufen',
      
      // Success Messages
      'success': 'Erfolg',
      'savedSuccessfully': 'Erfolgreich gespeichert',
      'updatedSuccessfully': 'Erfolgreich aktualisiert',
      'deletedSuccessfully': 'Erfolgreich gelöscht',
      
      // Date & Time
      'today': 'Heute',
      'yesterday': 'Gestern',
      'tomorrow': 'Morgen',
      'now': 'Jetzt',
      'justNow': 'Gerade eben',
      'minutesAgo': 'vor {count} Minuten',
      'hoursAgo': 'vor {count} Stunden',
      'daysAgo': 'vor {count} Tagen',
      
      // Store Chains
      'storeBilla': 'Billa',
      'storeBillaPlus': 'Billa Plus',
      'storeSpar': 'Spar',
      'storeEurospar': 'Eurospar',
      'storeInterspar': 'Interspar',
      'storeHofer': 'Hofer',
      'storeLidl': 'Lidl',
      'storePenny': 'Penny',
      'storeMerkur': 'Merkur',
      'storeMpreis': 'MPreis',
      'storeOther': 'Andere',
      
      // Days of Week
      'monday': 'Montag',
      'tuesday': 'Dienstag',
      'wednesday': 'Mittwoch',
      'thursday': 'Donnerstag',
      'friday': 'Freitag',
      'saturday': 'Samstag',
      'sunday': 'Sonntag',
      'mon': 'Mo',
      'tue': 'Di',
      'wed': 'Mi',
      'thu': 'Do',
      'fri': 'Fr',
      'sat': 'Sa',
      'sun': 'So',
      
      // Months
      'january': 'Januar',
      'february': 'Februar',
      'march': 'März',
      'april': 'April',
      'may': 'Mai',
      'june': 'Juni',
      'july': 'Juli',
      'august': 'August',
      'september': 'September',
      'october': 'Oktober',
      'november': 'November',
      'december': 'Dezember',
      'jan': 'Jan',
      'feb': 'Feb',
      'mar': 'Mär',
      'apr': 'Apr',
      'mayShort': 'Mai',
      'jun': 'Jun',
      'jul': 'Jul',
      'aug': 'Aug',
      'sep': 'Sep',
      'oct': 'Okt',
      'nov': 'Nov',
      'dec': 'Dez',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for common strings
  String get appName => translate('appName');
  String get signIn => translate('signIn');
  String get signUp => translate('signUp');
  String get signOut => translate('signOut');
  String get email => translate('email');
  String get password => translate('password');
  String get home => translate('home');
  String get bottles => translate('bottles');
  String get map => translate('map');
  String get analytics => translate('analytics');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get addBottle => translate('addBottle');
  String get scanBarcode => translate('scanBarcode');
  String get manualEntry => translate('manualEntry');
  String get totalBottles => translate('totalBottles');
  String get totalEarned => translate('totalEarned');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get error => translate('error');
  String get success => translate('success');
  
  // Format currency (always in Euros)
  String formatCurrency(double amount) {
    return '€${amount.toStringAsFixed(2)}';
  }
  
  // Format date based on locale
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return translate('today');
    } else if (difference.inDays == 1) {
      return translate('yesterday');
    } else if (difference.inDays < 7) {
      return translate('daysAgo').replaceAll('{count}', difference.inDays.toString());
    } else {
      // Format as DD.MM.YYYY for German, MM/DD/YYYY for English
      if (locale.languageCode == 'de') {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } else {
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      }
    }
  }
  
  // Format time based on locale
  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    
    if (locale.languageCode == 'de') {
      return '$hour:$minute Uhr';
    } else {
      final period = time.hour >= 12 ? 'PM' : 'AM';
      final displayHour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      return '$displayHour:$minute $period';
    }
  }
  
  // Get localized store chain name
  String getStoreChainName(String chain) {
    return translate('store${chain[0].toUpperCase()}${chain.substring(1)}');
  }
  
  // Get short day name
  String getShortDayName(int weekday) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return translate(days[weekday - 1]);
  }
  
  // Get short month name
  String getShortMonthName(int month) {
    const months = ['jan', 'feb', 'mar', 'apr', 'mayShort', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    return translate(months[month - 1]);
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}