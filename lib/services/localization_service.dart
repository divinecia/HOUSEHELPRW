import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'rw': 'Kinyarwanda',
    'fr': 'Français',
    'sw': 'Kiswahili',
  };

  static const Map<String, Locale> _locales = {
    'en': Locale('en', 'US'),
    'rw': Locale('rw', 'RW'),
    'fr': Locale('fr', 'FR'),
    'sw': Locale('sw', 'KE'),
  };

  /// Get the current language code
  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _defaultLanguage;
  }

  /// Set the current language
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  /// Get available languages
  static List<String> getAvailableLanguages() {
    return _languageNames.keys.toList();
  }

  /// Get language name by code
  static String getLanguageName(String languageCode) {
    return _languageNames[languageCode] ?? languageCode;
  }

  /// Get locale by language code
  static Locale? getLocale(String languageCode) {
    return _locales[languageCode];
  }

  /// Get all available locales
  static List<Locale> getSupportedLocales() {
    return _locales.values.toList();
  }

  /// Translation strings
  static const Map<String, Map<String, String>> _translations = {
    // App General
    'app_name': {
      'en': 'HouseHelp',
      'rw': 'Ubufasha bw\'Inzu',
      'fr': 'Aide Ménagère',
      'sw': 'Msaidizi wa Nyumbani',
    },
    'welcome': {
      'en': 'Welcome',
      'rw': 'Murakaza neza',
      'fr': 'Bienvenue',
      'sw': 'Karibu',
    },
    'loading': {
      'en': 'Loading...',
      'rw': 'Biratangurwa...',
      'fr': 'Chargement...',
      'sw': 'Inapakia...',
    },
    'error': {
      'en': 'Error',
      'rw': 'Ikosa',
      'fr': 'Erreur',
      'sw': 'Hitilafu',
    },
    'success': {
      'en': 'Success',
      'rw': 'Byakunze',
      'fr': 'Succès',
      'sw': 'Mafanikio',
    },
    'cancel': {
      'en': 'Cancel',
      'rw': 'Kuraguza',
      'fr': 'Annuler',
      'sw': 'Ghairi',
    },
    'save': {
      'en': 'Save',
      'rw': 'Kubika',
      'fr': 'Enregistrer',
      'sw': 'Hifadhi',
    },
    'delete': {
      'en': 'Delete',
      'rw': 'Gusiba',
      'fr': 'Supprimer',
      'sw': 'Futa',
    },
    'edit': {
      'en': 'Edit',
      'rw': 'Guhindura',
      'fr': 'Modifier',
      'sw': 'Hariri',
    },
    'confirm': {
      'en': 'Confirm',
      'rw': 'Kwemeza',
      'fr': 'Confirmer',
      'sw': 'Thibitisha',
    },
    'yes': {
      'en': 'Yes',
      'rw': 'Yego',
      'fr': 'Oui',
      'sw': 'Ndiyo',
    },
    'no': {
      'en': 'No',
      'rw': 'Oya',
      'fr': 'Non',
      'sw': 'Hapana',
    },

    // Authentication
    'login': {
      'en': 'Login',
      'rw': 'Kwinjira',
      'fr': 'Se connecter',
      'sw': 'Ingia',
    },
    'logout': {
      'en': 'Logout',
      'rw': 'Gusohoka',
      'fr': 'Se déconnecter',
      'sw': 'Toka',
    },
    'register': {
      'en': 'Register',
      'rw': 'Kwiyandikisha',
      'fr': 'S\'inscrire',
      'sw': 'Jisajili',
    },
    'email': {
      'en': 'Email',
      'rw': 'Imeyili',
      'fr': 'Email',
      'sw': 'Barua pepe',
    },
    'password': {
      'en': 'Password',
      'rw': 'Ijambo ry\'ibanga',
      'fr': 'Mot de passe',
      'sw': 'Nenosiri',
    },
    'forgot_password': {
      'en': 'Forgot Password?',
      'rw': 'Wibagiwe ijambo ry\'ibanga?',
      'fr': 'Mot de passe oublié?',
      'sw': 'Umesahau nenosiri?',
    },

    // Profile
    'profile': {
      'en': 'Profile',
      'rw': 'Umwirondoro',
      'fr': 'Profil',
      'sw': 'Wasifu',
    },
    'full_name': {
      'en': 'Full Name',
      'rw': 'Amazina yose',
      'fr': 'Nom complet',
      'sw': 'Jina kamili',
    },
    'phone_number': {
      'en': 'Phone Number',
      'rw': 'Nimero ya telefoni',
      'fr': 'Numéro de téléphone',
      'sw': 'Nambari ya simu',
    },
    'address': {
      'en': 'Address',
      'rw': 'Aderesi',
      'fr': 'Adresse',
      'sw': 'Anwani',
    },
    'date_of_birth': {
      'en': 'Date of Birth',
      'rw': 'Italiki y\'amavuko',
      'fr': 'Date de naissance',
      'sw': 'Tarehe ya kuzaliwa',
    },

    // Dashboard
    'dashboard': {
      'en': 'Dashboard',
      'rw': 'Ikibaho',
      'fr': 'Tableau de bord',
      'sw': 'Dashibodi',
    },
    'welcome_back': {
      'en': 'Welcome back',
      'rw': 'Murakaza neza nanone',
      'fr': 'Bon retour',
      'sw': 'Karibu tena',
    },
    'quick_actions': {
      'en': 'Quick Actions',
      'rw': 'Ibikorwa byihuse',
      'fr': 'Actions rapides',
      'sw': 'Vitendo vya haraka',
    },

    // Jobs/Hiring
    'find_worker': {
      'en': 'Find Worker',
      'rw': 'Gushaka umukozi',
      'fr': 'Trouver un travailleur',
      'sw': 'Tafuta mfanyakazi',
    },
    'hire_request': {
      'en': 'Hire Request',
      'rw': 'Icyifuzo cyo gukoresha',
      'fr': 'Demande d\'embauche',
      'sw': 'Ombi la ajira',
    },
    'job_title': {
      'en': 'Job Title',
      'rw': 'Umutwe w\'akazi',
      'fr': 'Titre du poste',
      'sw': 'Kichwa cha kazi',
    },
    'hourly_rate': {
      'en': 'Hourly Rate',
      'rw': 'Igiciro ku isaha',
      'fr': 'Tarif horaire',
      'sw': 'Kiwango cha saa',
    },
    'start_date': {
      'en': 'Start Date',
      'rw': 'Italiki yo gutangira',
      'fr': 'Date de début',
      'sw': 'Tarehe ya kuanza',
    },
    'end_date': {
      'en': 'End Date',
      'rw': 'Italiki yo kurangiza',
      'fr': 'Date de fin',
      'sw': 'Tarehe ya mwisho',
    },

    // Payments
    'payment': {
      'en': 'Payment',
      'rw': 'Kwishura',
      'fr': 'Paiement',
      'sw': 'Malipo',
    },
    'amount': {
      'en': 'Amount',
      'rw': 'Amafaranga',
      'fr': 'Montant',
      'sw': 'Kiasi',
    },
    'pay_now': {
      'en': 'Pay Now',
      'rw': 'Kwishura ubu',
      'fr': 'Payer maintenant',
      'sw': 'Lipa sasa',
    },
    'payment_method': {
      'en': 'Payment Method',
      'rw': 'Uburyo bwo kwishura',
      'fr': 'Méthode de paiement',
      'sw': 'Njia ya malipo',
    },
    'mobile_money': {
      'en': 'Mobile Money',
      'rw': 'Amafaranga ya telefoni',
      'fr': 'Mobile Money',
      'sw': 'Pesa za simu',
    },

    // Training
    'training': {
      'en': 'Training',
      'rw': 'Amahugurwa',
      'fr': 'Formation',
      'sw': 'Mafunzo',
    },
    'course': {
      'en': 'Course',
      'rw': 'Amasomo',
      'fr': 'Cours',
      'sw': 'Kozi',
    },
    'progress': {
      'en': 'Progress',
      'rw': 'Aho bigeze',
      'fr': 'Progrès',
      'sw': 'Maendeleo',
    },
    'certificate': {
      'en': 'Certificate',
      'rw': 'Icyemezo',
      'fr': 'Certificat',
      'sw': 'Hati',
    },
    'start_training': {
      'en': 'Start Training',
      'rw': 'Gutangira amahugurwa',
      'fr': 'Commencer la formation',
      'sw': 'Anza mafunzo',
    },

    // Chat/Communication
    'chat': {
      'en': 'Chat',
      'rw': 'Kuganira',
      'fr': 'Chat',
      'sw': 'Mazungumzo',
    },
    'message': {
      'en': 'Message',
      'rw': 'Ubutumwa',
      'fr': 'Message',
      'sw': 'Ujumbe',
    },
    'send_message': {
      'en': 'Send Message',
      'rw': 'Kohereza ubutumwa',
      'fr': 'Envoyer un message',
      'sw': 'Tuma ujumbe',
    },
    'type_message': {
      'en': 'Type a message...',
      'rw': 'Andika ubutumwa...',
      'fr': 'Tapez un message...',
      'sw': 'Andika ujumbe...',
    },

    // Reports
    'report': {
      'en': 'Report',
      'rw': 'Raporo',
      'fr': 'Rapport',
      'sw': 'Ripoti',
    },
    'behavior_report': {
      'en': 'Behavior Report',
      'rw': 'Raporo y\'imyitwarire',
      'fr': 'Rapport de comportement',
      'sw': 'Ripoti ya tabia',
    },
    'submit_report': {
      'en': 'Submit Report',
      'rw': 'Gutanga raporo',
      'fr': 'Soumettre le rapport',
      'sw': 'Wasilisha ripoti',
    },
    'description': {
      'en': 'Description',
      'rw': 'Ibisobanuro',
      'fr': 'Description',
      'sw': 'Maelezo',
    },

    // Emergency
    'emergency': {
      'en': 'Emergency',
      'rw': 'Byihutirwa',
      'fr': 'Urgence',
      'sw': 'Dharura',
    },
    'emergency_contacts': {
      'en': 'Emergency Contacts',
      'rw': 'Aho hahamagara mu byihutirwa',
      'fr': 'Contacts d\'urgence',
      'sw': 'Mawasiliano ya dharura',
    },
    'call_emergency': {
      'en': 'Call Emergency',
      'rw': 'Hamagara mu byihutirwa',
      'fr': 'Appeler l\'urgence',
      'sw': 'Piga simu ya dharura',
    },
    'emergency_report': {
      'en': 'Emergency Report',
      'rw': 'Raporo y\'ibyihutirwa',
      'fr': 'Rapport d\'urgence',
      'sw': 'Ripoti ya dharura',
    },

    // Settings
    'settings': {
      'en': 'Settings',
      'rw': 'Igenamiterere',
      'fr': 'Paramètres',
      'sw': 'Mipangilio',
    },
    'language': {
      'en': 'Language',
      'rw': 'Ururimi',
      'fr': 'Langue',
      'sw': 'Lugha',
    },
    'notifications': {
      'en': 'Notifications',
      'rw': 'Amakuru',
      'fr': 'Notifications',
      'sw': 'Arifa',
    },
    'privacy': {
      'en': 'Privacy',
      'rw': 'Ibanga',
      'fr': 'Confidentialité',
      'sw': 'Faragha',
    },
    'security': {
      'en': 'Security',
      'rw': 'Umutekano',
      'fr': 'Sécurité',
      'sw': 'Usalama',
    },

    // Status
    'pending': {
      'en': 'Pending',
      'rw': 'Butegereje',
      'fr': 'En attente',
      'sw': 'Inasubiri',
    },
    'approved': {
      'en': 'Approved',
      'rw': 'Byemewe',
      'fr': 'Approuvé',
      'sw': 'Imeidhinishwa',
    },
    'rejected': {
      'en': 'Rejected',
      'rw': 'Byanze',
      'fr': 'Rejeté',
      'sw': 'Imekataliwa',
    },
    'completed': {
      'en': 'Completed',
      'rw': 'Byarangiye',
      'fr': 'Terminé',
      'sw': 'Imekamilika',
    },
    'active': {
      'en': 'Active',
      'rw': 'Biracyakora',
      'fr': 'Actif',
      'sw': 'Hai',
    },
    'inactive': {
      'en': 'Inactive',
      'rw': 'Ntibikora',
      'fr': 'Inactif',
      'sw': 'Haifanyi kazi',
    },

    // Verification
    'verification': {
      'en': 'Verification',
      'rw': 'Kwemeza',
      'fr': 'Vérification',
      'sw': 'Uthibitisho',
    },
    'verified': {
      'en': 'Verified',
      'rw': 'Byemejwe',
      'fr': 'Vérifié',
      'sw': 'Imethibitishwa',
    },
    'not_verified': {
      'en': 'Not Verified',
      'rw': 'Ntibyemejwe',
      'fr': 'Non vérifié',
      'sw': 'Haijathibitishwa',
    },
    'upload_document': {
      'en': 'Upload Document',
      'rw': 'Gushyiraho inyandiko',
      'fr': 'Télécharger le document',
      'sw': 'Pakia hati',
    },

    // Location
    'location': {
      'en': 'Location',
      'rw': 'Ahantu',
      'fr': 'Emplacement',
      'sw': 'Mahali',
    },
    'district': {
      'en': 'District',
      'rw': 'Akarere',
      'fr': 'District',
      'sw': 'Wilaya',
    },
    'sector': {
      'en': 'Sector',
      'rw': 'Umurenge',
      'fr': 'Secteur',
      'sw': 'Sehemu',
    },
    'cell': {
      'en': 'Cell',
      'rw': 'Akagari',
      'fr': 'Cellule',
      'sw': 'Seli',
    },

    // Time
    'today': {
      'en': 'Today',
      'rw': 'Uyu munsi',
      'fr': 'Aujourd\'hui',
      'sw': 'Leo',
    },
    'tomorrow': {
      'en': 'Tomorrow',
      'rw': 'Ejo',
      'fr': 'Demain',
      'sw': 'Kesho',
    },
    'yesterday': {
      'en': 'Yesterday',
      'rw': 'Ejo hashize',
      'fr': 'Hier',
      'sw': 'Jana',
    },
    'this_week': {
      'en': 'This Week',
      'rw': 'Iyi cyumweru',
      'fr': 'Cette semaine',
      'sw': 'Wiki hii',
    },
    'this_month': {
      'en': 'This Month',
      'rw': 'Uku kwezi',
      'fr': 'Ce mois',
      'sw': 'Mwezi huu',
    },

    // Common actions
    'search': {
      'en': 'Search',
      'rw': 'Gushaka',
      'fr': 'Rechercher',
      'sw': 'Tafuta',
    },
    'filter': {
      'en': 'Filter',
      'rw': 'Gutandukanya',
      'fr': 'Filtrer',
      'sw': 'Chuja',
    },
    'sort': {
      'en': 'Sort',
      'rw': 'Gutondeka',
      'fr': 'Trier',
      'sw': 'Panga',
    },
    'refresh': {
      'en': 'Refresh',
      'rw': 'Gusiba no gutangira',
      'fr': 'Actualiser',
      'sw': 'Onyesha upya',
    },
    'share': {
      'en': 'Share',
      'rw': 'Gusangira',
      'fr': 'Partager',
      'sw': 'Shiriki',
    },
    'export': {
      'en': 'Export',
      'rw': 'Gusohora',
      'fr': 'Exporter',
      'sw': 'Hamisha',
    },
    'import': {
      'en': 'Import',
      'rw': 'Gukuramo',
      'fr': 'Importer',
      'sw': 'Ingiza',
    },

    // Error messages
    'network_error': {
      'en': 'Network connection error',
      'rw': 'Ikibazo cy\'urubuga',
      'fr': 'Erreur de connexion réseau',
      'sw': 'Hitilafu ya muunganiko wa mtandao',
    },
    'invalid_email': {
      'en': 'Invalid email address',
      'rw': 'Imeyili si nziza',
      'fr': 'Adresse email invalide',
      'sw': 'Barua pepe si sahihi',
    },
    'password_too_short': {
      'en': 'Password is too short',
      'rw': 'Ijambo ry\'ibanga ni rito cyane',
      'fr': 'Le mot de passe est trop court',
      'sw': 'Nenosiri ni fupi sana',
    },
    'required_field': {
      'en': 'This field is required',
      'rw': 'Uyu mwanya ukenewe',
      'fr': 'Ce champ est requis',
      'sw': 'Uga huu unahitajika',
    },
  };

  /// Get translated text
  static String translate(String key, {String? languageCode}) {
    final lang = languageCode ?? _defaultLanguage;
    final translations = _translations[key];

    if (translations == null) {
      return key; // Return key if translation not found
    }

    return translations[lang] ?? translations[_defaultLanguage] ?? key;
  }

  /// Get translated text with dynamic language
  static Future<String> translateAsync(String key) async {
    final currentLang = await getCurrentLanguage();
    return translate(key, languageCode: currentLang);
  }

  /// Format currency based on locale
  static String formatCurrency(double amount, {String? languageCode}) {
    final lang = languageCode ?? _defaultLanguage;

    switch (lang) {
      case 'rw':
        return '${amount.toStringAsFixed(0)} RWF';
      case 'fr':
        return '${amount.toStringAsFixed(0)} RWF';
      case 'sw':
        return 'RWF ${amount.toStringAsFixed(0)}';
      default:
        return 'RWF ${amount.toStringAsFixed(0)}';
    }
  }

  /// Format date based on locale
  static String formatDate(DateTime date, {String? languageCode}) {
    final lang = languageCode ?? _defaultLanguage;

    // Simple date formatting - in a real app, use intl package
    switch (lang) {
      case 'rw':
        return '${date.day}/${date.month}/${date.year}';
      case 'fr':
        return '${date.day}/${date.month}/${date.year}';
      case 'sw':
        return '${date.day}/${date.month}/${date.year}';
      default:
        return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// Get text direction for RTL languages
  static TextDirection getTextDirection(String? languageCode) {
    // All supported languages are LTR
    return TextDirection.ltr;
  }

  /// Check if language is RTL
  static bool isRTL(String? languageCode) {
    // All supported languages are LTR
    return false;
  }
}
