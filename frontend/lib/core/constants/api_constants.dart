class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://marketplace-api.business-alejandrolopezmurillo.workers.dev';
  static const String prodBaseUrl = 'https://marketplace-api.business-alejandrolopezmurillo.workers.dev';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Listings
  static const String listings = '/listings';
  static const String myListings = '/my/listings';

  // Categories
  static const String categories = '/categories';

  // Messages
  static const String messages = '/messages';

  // Help requests
  static const String requests = '/requests';

  // Users
  static const String users = '/users';

  // Uploads
  static const String uploads = '/uploads/presign';

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
}
