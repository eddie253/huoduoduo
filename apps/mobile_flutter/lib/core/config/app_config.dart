class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000/v1');

  static const String registerUrl = String.fromEnvironment(
    'WEBVIEW_REGISTER_URL',
    defaultValue: 'https://old.huoduoduo.com.tw/register/register.aspx',
  );

  static const String resetPasswordUrl = String.fromEnvironment(
    'WEBVIEW_RESET_URL',
    defaultValue:
        'https://old.huoduoduo.com.tw/register/register_resetpwd.aspx',
  );

  static const List<String> allowedWebHosts = <String>[
    'old.huoduoduo.com.tw',
    'reserve.huoduoduo.com.tw',
    'app.elf.com.tw'
  ];
}
