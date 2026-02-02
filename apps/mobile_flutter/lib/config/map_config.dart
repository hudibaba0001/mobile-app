/// Configuration for Mapbox API
///
/// To use automatic travel time calculation:
/// 1. Go to https://account.mapbox.com/
/// 2. Sign up or log in to your Mapbox account
/// 3. Go to "Access tokens" in your account settings
/// 4. Copy your default public token or create a new one
/// 5. Replace 'YOUR_MAPBOX_API_KEY' below with your actual access token
///
/// Note: Mapbox provides free tier with generous limits for development
class MapConfig {
  /// Mapbox Access Token for Directions API and Geocoding API
  ///
  /// Get your access token from: https://account.mapbox.com/access-tokens/
  /// The token will have access to:
  /// - Directions API (for route calculation)
  /// - Geocoding API (for address to coordinates conversion)
  static const String mapboxApiKey =
      'pk.eyJ1IjoiZWtheXVuZ2VyaWNhMjgiLCJhIjoiY21qdGJldnpwMDBpYjNlczR6NXBueTh3ciJ9.WEa3vVzc6qKC6RE-UxUc9Q';

  /// Check if the API key is configured
  static bool get isConfigured => mapboxApiKey != 'YOUR_MAPBOX_API_KEY';
}
