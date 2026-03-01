import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/config/app_config.dart';
import '../../auth/domain/auth_models.dart';
import '../application/js_bridge_service.dart';
import '../domain/webview_cache_policy.dart';

class WebViewShellPage extends StatefulWidget {
  final WebviewBootstrap bootstrap;

  const WebViewShellPage({super.key, required this.bootstrap});

  @override
  State<WebViewShellPage> createState() => _WebViewShellPageState();
}

class _WebViewShellPageState extends State<WebViewShellPage> {
  final _bridgeService = JsBridgeService();
  final _cachePolicyResolver = const WebviewCachePolicyResolver();
  InAppWebViewController? _controller;
  String? _errorText;
  static final InAppWebViewKeepAlive _keepAlive = InAppWebViewKeepAlive();

  static const String _bridgeAdapterScript = '''
(function () {
  if (window.android && window.android.__bridgeVersion === '1.0') return;
  function emit(method, params) {
    var payload = {
      id: String(Date.now()) + '-' + Math.random().toString(16).slice(2),
      version: '1.0',
      method: method,
      params: params || {},
      timestamp: Date.now()
    };
    return window.flutter_inappwebview.callHandler('bridge', payload);
  }
  window.android = {
    __bridgeVersion: '1.0',
    error: function () { return emit('error', {}); },
    RefreshEnable: function (enable) { return emit('RefreshEnable', { enable: String(enable) }); },
    redirect: function (page) { return emit('redirect', { page: String(page || '') }); },
    openfile: function (url) { return emit('openfile', { url: String(url || '') }); },
    open_IMG_Scanner: function (type) { return emit('open_IMG_Scanner', { type: String(type || '') }); },
    openMsgExit: function (msg) { return emit('openMsgExit', { msg: String(msg || '') }); },
    cfs_sign: function () { return emit('cfs_sign', {}); },
    APPEvent: function (kind, result) { return emit('APPEvent', { kind: String(kind || ''), result: String(result || '') }); }
  };
})();
''';

  bool _isAllowedHost(String? host) {
    if (host == null || host.isEmpty) {
      return false;
    }
    return AppConfig.allowedWebHosts.contains(host);
  }

  Future<void> _bootstrapWebView(InAppWebViewController controller) async {
    final cookieManager = CookieManager.instance();
    final baseUri = WebUri(widget.bootstrap.baseUrl);

    for (final cookie in widget.bootstrap.cookies) {
      await cookieManager.setCookie(
          url: baseUri,
          name: cookie.name,
          value: cookie.value,
          domain: cookie.domain,
          path: cookie.path,
          isSecure: cookie.secure,
          isHttpOnly: cookie.httpOnly);
    }

    await controller.loadUrl(
      urlRequest: URLRequest(
        url: baseUri,
        cachePolicy: _cachePolicyResolver.cachePolicyFor(baseUri),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('WebView Shell')),
        body: Stack(children: <Widget>[
          InAppWebView(
              keepAlive: _keepAlive,
              initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  javaScriptCanOpenWindowsAutomatically: false,
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: true,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                  clearCache: false,
                  allowFileAccessFromFileURLs: false,
                  allowUniversalAccessFromFileURLs: false),
              onWebViewCreated: (controller) async {
                _controller = controller;
                controller.addJavaScriptHandler(
                    handlerName: 'bridge',
                    callback: (args) => _bridgeService.handle(args, context));
                await _bootstrapWebView(controller);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                if (!_isAllowedHost(uri?.host)) {
                  setState(() {
                    _errorText =
                        'Blocked navigation to non-whitelisted domain.';
                  });
                  return NavigationActionPolicy.CANCEL;
                }

                final cachePolicy = _cachePolicyResolver.cachePolicyFor(uri);
                if (cachePolicy ==
                    URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA) {
                  await controller.loadUrl(
                    urlRequest: URLRequest(
                      url: uri,
                      cachePolicy: cachePolicy,
                    ),
                  );
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(
                    source: _bridgeAdapterScript);
              },
              onReceivedError: (controller, request, error) {
                setState(() {
                  _errorText = '${error.type}: ${error.description}';
                });
              }),
          if (_errorText != null)
            Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade700,
                    child: Text(_errorText!,
                        style: const TextStyle(color: Colors.white))))
        ]),
        floatingActionButton: FloatingActionButton(
            onPressed: () => _controller?.reload(),
            child: const Icon(Icons.refresh)));
  }
}
