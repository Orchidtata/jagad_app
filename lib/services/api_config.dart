class ApiConfig {
  static const String baseUrl = 'http://172.18.216.143:8000';
  static const String apiPrefix = '/api';
  
  static String get eventsEndpoint => '$baseUrl$apiPrefix/events';
  static String eventDetailEndpoint(int id) => '$baseUrl$apiPrefix/events/$id';
}