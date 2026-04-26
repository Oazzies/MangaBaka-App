import 'package:bakahyou/utils/constants/app_constants.dart';

/// Library-specific constants derived from AppConstants.
/// Uses `final` for computed values from string interpolation.
class LibraryConstants {
  LibraryConstants._(); // Prevent instantiation

  static final String baseUrl = '${AppConstants.baseApiUrl}/my/library';
  static const int pageLimit = AppConstants.libraryPageLimit;
  static const String userAgent = AppConstants.userAgent;
}
