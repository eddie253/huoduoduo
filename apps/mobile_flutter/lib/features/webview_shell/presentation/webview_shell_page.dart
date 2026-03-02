import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../application/js_bridge_service.dart';
import '../domain/webview_cache_policy.dart';

enum _ShellSection { reservation, order, signature, wallet }

enum _MenuActionType {
  openWeb,
  openScanner,
  openShipment,
  openSignature,
  openNotifications,
  openMaps,
  logout,
  placeholder,
}

class _BottomTab {
  const _BottomTab({
    required this.section,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final _ShellSection section;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _MenuTile {
  const _MenuTile._({
    required this.label,
    required this.icon,
    required this.actionType,
    this.uri,
    this.value,
    this.enabled = true,
  });

  const _MenuTile.web({
    required String label,
    required IconData icon,
    required WebUri uri,
  }) : this._(
          label: label,
          icon: icon,
          actionType: _MenuActionType.openWeb,
          uri: uri,
        );

  const _MenuTile.scanner({
    required String label,
    required IconData icon,
    required String scanType,
  }) : this._(
          label: label,
          icon: icon,
          actionType: _MenuActionType.openScanner,
          value: scanType,
        );

  const _MenuTile.simple({
    required String label,
    required IconData icon,
    required _MenuActionType actionType,
  }) : this._(label: label, icon: icon, actionType: actionType);

  const _MenuTile.placeholder()
      : this._(
          label: '即將開放',
          icon: Icons.local_shipping_outlined,
          actionType: _MenuActionType.placeholder,
          enabled: false,
        );

  final String label;
  final IconData icon;
  final _MenuActionType actionType;
  final WebUri? uri;
  final String? value;
  final bool enabled;
}

class WebViewShellPage extends ConsumerStatefulWidget {
  const WebViewShellPage({super.key, required this.bootstrap});

  final WebviewBootstrap bootstrap;

  @override
  ConsumerState<WebViewShellPage> createState() => _WebViewShellPageState();
}

class _WebViewShellPageState extends ConsumerState<WebViewShellPage> {
  static const int _menuSlotCount = 8;

  static const Key shellScaffoldKey = Key('webview.shell.scaffold');
  static const Key topBackButtonKey = Key('webview.top.backButton');
  static const Key bottomBarKey = Key('webview.bottomBar');

  static const Color _brand = Color(0xFFFC5000);
  static const Color _inactive = Color(0xFF8A8D92);
  static const Color _surface = Color(0xFFF3F4F6);
  static const Color _gridBg = Color(0xFFE9EDF2);

  static const String _defaultAnnouncement = '無公告';
  static const String _errorAnnouncement = '載入失敗';

  static final InAppWebViewKeepAlive _keepAlive = InAppWebViewKeepAlive();
  static final WebUri _reservationFallback =
      WebUri('https://old.huoduoduo.com.tw/app/rvt/ge.aspx');

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
    pre_page: function () { return emit('pre_page', {}); },
    redirect: function (page) { return emit('redirect', { page: String(page || '') }); },
    openImage: function (url) { return emit('openImage', { url: String(url || '') }); },
    openfile: function (url) { return emit('openfile', { url: String(url || '') }); },
    open_IMG_Scanner: function (type) { return emit('open_IMG_Scanner', { type: String(type || '') }); },
    openMsgExit: function (msg) { return emit('openMsgExit', { msg: String(msg || '') }); },
    cfs_sign: function () { return emit('cfs_sign', {}); },
    APPEvent: function (kind, result) { return emit('APPEvent', { kind: String(kind || ''), result: String(result || '') }); }
  };
})();
''';

  final JsBridgeService _bridgeService = JsBridgeService();
  final WebviewCachePolicyResolver _cachePolicyResolver =
      const WebviewCachePolicyResolver();

  late final List<_BottomTab> _tabs;
  late final Map<_ShellSection, List<_MenuTile>> _menuTiles;

  InAppWebViewController? _controller;
  URLRequest? _pendingRequest;
  bool _inWeb = false;
  bool _loadingWeb = false;
  bool _didErrorFallback = false;
  bool _cookiesBootstrapped = false;

  _ShellSection _currentSection = _ShellSection.reservation;
  String _announcement = _defaultAnnouncement;
  String? _webTitle;
  String? _errorText;
  Timer? _bulletinTimer;

  @override
  void initState() {
    super.initState();
    _tabs = _buildTabs();
    _menuTiles = _buildMenuTiles();
    unawaited(_bootstrapCookies());
    unawaited(_fetchAnnouncement());
    _bulletinTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_fetchAnnouncement());
    });
  }

  @override
  void dispose() {
    _bulletinTimer?.cancel();
    super.dispose();
  }

  List<_BottomTab> _buildTabs() => const <_BottomTab>[
        _BottomTab(
          section: _ShellSection.reservation,
          label: '預約',
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
        ),
        _BottomTab(
          section: _ShellSection.order,
          label: '接單',
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
        ),
        _BottomTab(
          section: _ShellSection.signature,
          label: '簽收',
          icon: Icons.draw_outlined,
          activeIcon: Icons.draw_rounded,
        ),
        _BottomTab(
          section: _ShellSection.wallet,
          label: '錢包',
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
        ),
      ];

  Map<_ShellSection, List<_MenuTile>> _buildMenuTiles() {
    WebUri appUri(String path) =>
        WebUri('https://old.huoduoduo.com.tw/app/$path');

    return <_ShellSection, List<_MenuTile>>{
      _ShellSection.reservation: <_MenuTile>[
        _MenuTile.web(
            label: '預約貨件',
            icon: Icons.event_available_rounded,
            uri: appUri('rvt/ge.aspx')),
        _MenuTile.web(
            label: '取消預約',
            icon: Icons.event_busy_rounded,
            uri: appUri('rvt/ge_c.aspx')),
        _MenuTile.web(
            label: '已到倉庫',
            icon: Icons.warehouse_rounded,
            uri: appUri('inq/strg.aspx')),
        _MenuTile.web(
            label: '大貨預約',
            icon: Icons.local_shipping_rounded,
            uri: appUri('rvt/bh.aspx')),
        _MenuTile.web(
            label: '大貨取消預約',
            icon: Icons.inventory_2_rounded,
            uri: appUri('rvt/bh_c.aspx')),
        _MenuTile.web(
            label: '預約縣市設定',
            icon: Icons.location_city_rounded,
            uri: appUri('rvt/df_area.aspx')),
        _MenuTile.web(
            label: '押金明細',
            icon: Icons.savings_rounded,
            uri: appUri('inq/dep.aspx')),
        const _MenuTile.placeholder(),
      ],
      _ShellSection.order: <_MenuTile>[
        const _MenuTile.scanner(
            label: '接單', icon: Icons.qr_code_scanner_rounded, scanType: '接單'),
        const _MenuTile.scanner(
            label: '接單取消',
            icon: Icons.assignment_late_rounded,
            scanType: '接單取消'),
        _MenuTile.web(
            label: '接單明細',
            icon: Icons.description_rounded,
            uri: appUri('inq/dtl.aspx')),
        const _MenuTile.simple(
            label: '路線導航',
            icon: Icons.route_rounded,
            actionType: _MenuActionType.openMaps),
        const _MenuTile.simple(
            label: '一鍵上傳',
            icon: Icons.cloud_upload_rounded,
            actionType: _MenuActionType.openShipment),
        const _MenuTile.simple(
            label: '即時通知',
            icon: Icons.notifications_active_rounded,
            actionType: _MenuActionType.openNotifications),
        const _MenuTile.simple(
            label: '快速簽名',
            icon: Icons.border_color_rounded,
            actionType: _MenuActionType.openSignature),
        const _MenuTile.placeholder(),
      ],
      _ShellSection.signature: <_MenuTile>[
        const _MenuTile.scanner(
            label: '單筆簽收', icon: Icons.fact_check_rounded, scanType: '單筆簽收'),
        const _MenuTile.scanner(
            label: '多筆簽收', icon: Icons.assignment_rounded, scanType: '多筆簽收'),
        const _MenuTile.simple(
            label: '一鍵上傳',
            icon: Icons.cloud_upload_rounded,
            actionType: _MenuActionType.openShipment),
        const _MenuTile.scanner(
            label: '送達異常',
            icon: Icons.local_shipping_outlined,
            scanType: '送達異常'),
        const _MenuTile.scanner(
            label: '多筆送達異常',
            icon: Icons.playlist_remove_rounded,
            scanType: '多筆送達異常'),
        const _MenuTile.scanner(
            label: '取消送達',
            icon: Icons.cancel_schedule_send_rounded,
            scanType: '取消送達'),
        _MenuTile.web(
            label: '送達明細',
            icon: Icons.list_alt_rounded,
            uri: appUri('inq/arv.aspx')),
        const _MenuTile.simple(
            label: '錯誤重傳',
            icon: Icons.cloud_sync_rounded,
            actionType: _MenuActionType.openNotifications),
      ],
      _ShellSection.wallet: <_MenuTile>[
        _MenuTile.web(
            label: '提現',
            icon: Icons.payments_rounded,
            uri: appUri('currency/wda.aspx')),
        _MenuTile.web(
            label: '帳號管理',
            icon: Icons.badge_rounded,
            uri: appUri('currency/bifm.aspx')),
        _MenuTile.web(
            label: '銀行帳號',
            icon: Icons.credit_card_rounded,
            uri: appUri('currency/bank.aspx')),
        _MenuTile.web(
            label: '帳戶日明細',
            icon: Icons.stacked_bar_chart_rounded,
            uri: appUri('currency/day_cy.aspx')),
        _MenuTile.web(
            label: '帳戶月明細',
            icon: Icons.bar_chart_rounded,
            uri: appUri('currency/month_cy.aspx')),
        const _MenuTile.simple(
            label: '代理',
            icon: Icons.groups_rounded,
            actionType: _MenuActionType.openNotifications),
        const _MenuTile.simple(
            label: '設定',
            icon: Icons.settings_rounded,
            actionType: _MenuActionType.openNotifications),
        const _MenuTile.simple(
            label: '登出',
            icon: Icons.logout_rounded,
            actionType: _MenuActionType.logout),
      ],
    };
  }

  Future<void> _fetchAnnouncement() async {
    try {
      final response = await ref.read(dioProvider).get('/bootstrap/bulletin');
      final payload = response.data;
      String message = '';
      if (payload is Map && payload['message'] != null) {
        message = payload['message'].toString().trim();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _announcement = message.isEmpty ? _defaultAnnouncement : message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _announcement = _errorAnnouncement;
      });
    }
  }

  bool _isAllowedHost(String? host) {
    if (host == null || host.isEmpty) {
      return false;
    }
    return AppConfig.allowedWebHosts
        .map((e) => e.toLowerCase())
        .contains(host.toLowerCase());
  }

  WebUri? _normalizeAllowedUri(WebUri uri) {
    if (uri.scheme.toLowerCase() != 'https') {
      return null;
    }
    if (!_isAllowedHost(uri.host)) {
      return null;
    }
    return uri;
  }

  Future<void> _bootstrapCookies() async {
    if (_cookiesBootstrapped) {
      return;
    }

    final CookieManager cookieManager = CookieManager.instance();
    final WebUri bootstrapUri = WebUri(widget.bootstrap.baseUrl);
    final WebUri baseUri =
        _normalizeAllowedUri(bootstrapUri) ?? _reservationFallback;
    final String baseHost = baseUri.host.toLowerCase();

    final Set<String> cookieHosts = <String>{
      baseHost,
      ...widget.bootstrap.cookies
          .map((cookie) => cookie.domain.trim().toLowerCase())
          .where((host) => host.isNotEmpty && _isAllowedHost(host)),
    };

    for (final String host in cookieHosts) {
      await cookieManager.deleteCookies(
          url: WebUri('https://$host'), domain: host);
    }

    for (final WebCookieModel cookie in widget.bootstrap.cookies) {
      await cookieManager.setCookie(
        url: baseUri,
        name: cookie.name,
        value: cookie.value,
        path: cookie.path,
        isSecure: cookie.secure,
        isHttpOnly: cookie.httpOnly,
      );

      final String cookieHost = cookie.domain.trim().toLowerCase();
      if (cookieHost.isNotEmpty &&
          cookieHost != baseHost &&
          _isAllowedHost(cookieHost)) {
        final WebUri domainUrl =
            WebUri('${cookie.secure ? 'https' : 'http'}://$cookieHost/');
        await cookieManager.setCookie(
          url: domainUrl,
          name: cookie.name,
          value: cookie.value,
          domain: cookieHost,
          path: cookie.path,
          isSecure: cookie.secure,
          isHttpOnly: cookie.httpOnly,
        );
      }
    }

    _cookiesBootstrapped = true;
  }

  bool _isLegacyPrePage(List<dynamic> args) {
    if (args.isEmpty || args.first is! Map) {
      return false;
    }
    return args.first['method']?.toString() == 'pre_page';
  }

  Future<void> _openWebPage(
      {required String title, required WebUri uri}) async {
    final WebUri? normalized = _normalizeAllowedUri(uri);
    if (normalized == null) {
      if (mounted) {
        setState(() {
          _errorText = 'Blocked navigation to non-whitelisted domain.';
        });
      }
      return;
    }

    await _bootstrapCookies();
    final URLRequest request = URLRequest(
      url: normalized,
      cachePolicy: _cachePolicyResolver.cachePolicyFor(normalized),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _inWeb = true;
      _loadingWeb = true;
      _didErrorFallback = false;
      _webTitle = title;
      _errorText = null;
    });

    if (_controller == null) {
      _pendingRequest = request;
      return;
    }
    await _controller!.loadUrl(urlRequest: request);
  }

  Future<void> _openScanner(String scanType) async {
    if (!mounted) {
      return;
    }
    await context
        .push('/scanner', extra: <String, dynamic>{'scanType': scanType});
  }

  Future<void> _logout() async {
    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('登出失敗：$e')));
      }
    }
  }

  Future<void> _onTileTap(_MenuTile tile) async {
    if (!tile.enabled) {
      return;
    }

    switch (tile.actionType) {
      case _MenuActionType.openWeb:
        if (tile.uri != null) {
          await _openWebPage(title: tile.label, uri: tile.uri!);
        }
        break;
      case _MenuActionType.openScanner:
        await _openScanner(tile.value ?? 'default');
        break;
      case _MenuActionType.openShipment:
        if (mounted) {
          await context.push('/shipment');
        }
        break;
      case _MenuActionType.openSignature:
        if (mounted) {
          await context.push('/signature');
        }
        break;
      case _MenuActionType.openNotifications:
        if (mounted) {
          await context.push('/notifications');
        }
        break;
      case _MenuActionType.openMaps:
        if (mounted) {
          await context.push('/maps');
        }
        break;
      case _MenuActionType.logout:
        await _logout();
        break;
      case _MenuActionType.placeholder:
        break;
    }
  }

  Future<void> _handleWebBack() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _inWeb = false;
      _loadingWeb = false;
      _webTitle = null;
      _errorText = null;
    });
  }

  Future<void> _handleBack() async {
    if (_inWeb) {
      await _handleWebBack();
      return;
    }
    if (_currentSection != _ShellSection.reservation) {
      setState(() {
        _currentSection = _ShellSection.reservation;
      });
      return;
    }
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  String _sectionTitle(_ShellSection section) {
    switch (section) {
      case _ShellSection.reservation:
        return '預約';
      case _ShellSection.order:
        return '接單';
      case _ShellSection.signature:
        return '簽收';
      case _ShellSection.wallet:
        return '錢包';
    }
  }

  List<_MenuTile> _slotsForSection(_ShellSection section) {
    final List<_MenuTile> source =
        List<_MenuTile>.from(_menuTiles[section] ?? const <_MenuTile>[]);
    if (source.length >= _menuSlotCount) {
      return source.take(_menuSlotCount).toList();
    }
    source.addAll(List<_MenuTile>.generate(
      _menuSlotCount - source.length,
      (_) => const _MenuTile.placeholder(),
    ));
    return source;
  }

  Widget _buildTopBar() {
    final String title = (_inWeb && _webTitle != null && _webTitle!.isNotEmpty)
        ? _webTitle!
        : _sectionTitle(_currentSection);

    return Container(
      color: _surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 56,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 78,
                  child: Opacity(
                    opacity: _inWeb ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_inWeb,
                      child: IconButton(
                        key: topBackButtonKey,
                        onPressed: _handleWebBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: _brand, size: 20),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _brand,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 78,
                  child: Opacity(
                    opacity: _inWeb ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_inWeb,
                      child: IconButton(
                        onPressed: () => _controller?.reload(),
                        icon: const Icon(Icons.refresh_rounded,
                            color: _brand, size: 22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 42,
            color: Colors.black,
            alignment: Alignment.center,
            child: Text(
              _announcement,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final List<_MenuTile> slots = _slotsForSection(_currentSection);

    return Container(
      color: _gridBg,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          const double spacing = 14;
          const double pad = 14;
          final double usableW = c.maxWidth - pad * 2 - spacing;
          final double usableH = c.maxHeight - pad * 2 - spacing * 3;
          final double cardW = usableW / 2;
          final double cardH = usableH / 4;
          final double ratio = cardH <= 0 ? 1 : cardW / cardH;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(pad),
            itemCount: _menuSlotCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: ratio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemBuilder: (BuildContext context, int index) {
              final _MenuTile tile = slots[index];
              final bool enabled = tile.enabled;
              final Color iconColor = enabled ? _brand : _inactive;
              final Color textColor =
                  enabled ? const Color(0xFF3D4A59) : const Color(0xFF9CA3AF);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: enabled ? () => _onTileTap(tile) : null,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFE4E9EF), width: 1.2),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 12,
                            offset: Offset(0, 6)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(tile.icon, size: 44, color: iconColor),
                          const SizedBox(height: 12),
                          Text(
                            tile.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWebViewLayer() {
    return Stack(
      children: <Widget>[
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
            allowUniversalAccessFromFileURLs: false,
          ),
          onWebViewCreated: (InAppWebViewController controller) async {
            _controller = controller;
            controller.addJavaScriptHandler(
              handlerName: 'bridge',
              callback: (List<dynamic> args) async {
                if (_isLegacyPrePage(args)) {
                  await _handleWebBack();
                  return <String, dynamic>{
                    'ok': true,
                    'action': 'legacy_pre_page_closed'
                  };
                }
                return _bridgeService.handle(args, context);
              },
            );

            final URLRequest? pending = _pendingRequest;
            if (pending != null) {
              _pendingRequest = null;
              await controller.loadUrl(urlRequest: pending);
            }
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final WebUri? uri = navigationAction.request.url;
            if (uri == null) {
              return NavigationActionPolicy.CANCEL;
            }
            final String scheme = uri.scheme.toLowerCase();
            if (scheme == 'about' || scheme == 'data') {
              return NavigationActionPolicy.ALLOW;
            }
            if (!_isAllowedHost(uri.host)) {
              if (mounted) {
                setState(() {
                  _errorText = 'Blocked navigation to non-whitelisted domain.';
                });
              }
              return NavigationActionPolicy.CANCEL;
            }

            final URLRequestCachePolicy cachePolicy =
                _cachePolicyResolver.cachePolicyFor(uri);
            if (cachePolicy ==
                URLRequestCachePolicy.RELOAD_IGNORING_LOCAL_CACHE_DATA) {
              await controller.loadUrl(
                  urlRequest: URLRequest(url: uri, cachePolicy: cachePolicy));
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
          onLoadStart: (controller, url) {
            if (mounted) {
              setState(() {
                _loadingWeb = true;
              });
            }
          },
          onLoadStop: (controller, url) async {
            if (url != null &&
                !_didErrorFallback &&
                url.host.toLowerCase() == 'app.elf.com.tw' &&
                url.path.toLowerCase() == '/error.aspx') {
              _didErrorFallback = true;
              await _openWebPage(title: '預約貨件', uri: _reservationFallback);
              return;
            }
            try {
              await controller.evaluateJavascript(source: _bridgeAdapterScript);
            } catch (e) {
              if (mounted) {
                setState(() {
                  _errorText = 'Bridge injection failed: $e';
                });
              }
            }
            if (mounted) {
              setState(() {
                _loadingWeb = false;
              });
            }
          },
          onReceivedError: (controller, request, error) {
            if (mounted) {
              setState(() {
                _loadingWeb = false;
                _errorText = '${error.type}: ${error.description}';
              });
            }
          },
        ),
        if (_loadingWeb)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x55FFFFFF),
              child: Center(child: CircularProgressIndicator(color: _brand)),
            ),
          ),
        if (_errorText != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade700,
              child: Text(_errorText!,
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      key: bottomBarKey,
      height: 84,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: Color(0xFFD9DADF))),
      ),
      child: Row(
        children: List<Widget>.generate(_tabs.length, (int index) {
          final _BottomTab tab = _tabs[index];
          final bool selected = tab.section == _currentSection;
          final Color color = selected ? _brand : _inactive;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _currentSection = tab.section;
                  _inWeb = false;
                  _loadingWeb = false;
                  _webTitle = null;
                  _errorText = null;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(selected ? tab.activeIcon : tab.icon,
                        color: color, size: 28),
                    const SizedBox(height: 4),
                    Text(tab.label,
                        style: TextStyle(
                            fontSize: 15,
                            color: color,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(_handleBack());
        }
      },
      child: Scaffold(
        key: shellScaffoldKey,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _buildTopBar(),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Offstage(offstage: _inWeb, child: _buildMenuGrid()),
                    Offstage(offstage: !_inWeb, child: _buildWebViewLayer()),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}
