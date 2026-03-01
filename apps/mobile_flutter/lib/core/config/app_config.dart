class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/v1'
  );

  static const List<String> allowedWebHosts = <String>[
    'old.huoduoduo.com.tw',
    'reserve.huoduoduo.com.tw',
    'app.elf.com.tw'
  ];
}
