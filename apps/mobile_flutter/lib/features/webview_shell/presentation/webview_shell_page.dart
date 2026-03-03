import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/dio_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../application/js_bridge_service.dart';
import '../application/map_navigation_preflight_service.dart';
import '../application/webview_shell_navigation_helper.dart';
import '../domain/legacy_menu_mapping.dart';
import '../domain/shell_navigation_state.dart';
import '../domain/webview_cache_policy.dart';

enum _MenuActionType {
  openWeb,
  openScanner,
  openShipment,
  openSignature,
  openArrivalUploadErrors,
  openProxyMenu,
  openSettings,
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

  final ShellSection section;
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
          label: '?喳??',
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
  static const int _bridgeLogMaxLength = 240;

  static const Key shellScaffoldKey = Key('webview.shell.scaffold');
  static const Key topBackButtonKey = Key('webview.top.backButton');
  static const Key topSettingsButtonKey = Key('webview.top.settingsButton');
  static const Key bottomBarKey = Key('webview.bottomBar');

  static const String _defaultAnnouncement = '系統公告';
  static const String _errorAnnouncement = '頛憭望?';

  static final InAppWebViewKeepAlive _keepAlive = InAppWebViewKeepAlive();
  static final WebUri _reservationFallback =
      WebUri('https://old.huoduoduo.com.tw/app/rvt/ge.aspx');

  static const String _bridgeAdapterScript = '''
(function () {
  if (window.android && window.android.__bridgeVersion === '1.0') return;
  function logBridge(tag, payload) {
    try {
      console.log('[BRIDGE][' + tag + '] ' + JSON.stringify(payload));
    } catch (_) {
      console.log('[BRIDGE][' + tag + ']');
    }
  }
  function emit(method, params) {
    var payload = {
      id: String(Date.now()) + '-' + Math.random().toString(16).slice(2),
      version: '1.0',
      method: method,
      params: params || {},
      timestamp: Date.now()
    };
    logBridge('emit', payload);
    return window.flutter_inappwebview.callHandler('bridge', payload)
      .then(function (result) {
        logBridge('result', { id: payload.id, method: method, result: result });
        return result;
      })
      .catch(function (error) {
        logBridge('error', { id: payload.id, method: method, error: String(error || '') });
        throw error;
      });
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
  final MapNavigationPreflightPort _mapNavigationPreflight =
      const DefaultMapNavigationPreflightService();
  final WebviewShellNavigationHelper _navigationHelper =
      WebviewShellNavigationHelper();
  final WebviewCachePolicyResolver _cachePolicyResolver =
      const WebviewCachePolicyResolver();

  late final List<_BottomTab> _tabs;
  late final Map<ShellSection, List<_MenuTile>> _menuTiles;

  InAppWebViewController? _controller;
  bool _didErrorFallback = false;
  bool _cookiesBootstrapped = false;

  ShellNavigationState _navState = ShellNavigationState.initial();
  String _announcement = _defaultAnnouncement;
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

  bool get _inWeb => _navState.inWeb;
  bool get _loadingWeb => _navState.loadingWeb;
  ShellSection get _currentSection => _navState.currentSection;
  String? get _webTitle => _navState.webTitle;
  String? get _errorText => _navState.errorText;

  String _truncateBridgeLog(Object? value) {
    final String raw = value?.toString() ?? '';
    if (raw.length <= _bridgeLogMaxLength) {
      return raw;
    }
    final int hidden = raw.length - _bridgeLogMaxLength;
    return '${raw.substring(0, _bridgeLogMaxLength)}...(+$hidden chars)';
  }

  void _logBridgeIncoming(List<dynamic> args) {
    if (args.isEmpty) {
      debugPrint('[Bridge][incoming] empty args');
      return;
    }
    final dynamic payload = args.first;
    if (payload is Map) {
      final dynamic params = payload['params'];
      final dynamic kind = params is Map ? params['kind'] : null;
      final dynamic result = params is Map ? params['result'] : null;
      debugPrint(
        '[Bridge][incoming] method=${_truncateBridgeLog(payload['method'])} '
        'kind=${_truncateBridgeLog(kind)} '
        'result=${_truncateBridgeLog(result)}',
      );
      return;
    }
    debugPrint('[Bridge][incoming] payload=${_truncateBridgeLog(payload)}');
  }

  void _logBridgeOutgoing(Map<String, dynamic> result) {
    final dynamic error = result['error'];
    final dynamic errorCode = error is Map ? error['code'] : null;
    debugPrint(
      '[Bridge][outgoing] ok=${result['ok']} '
      'action=${_truncateBridgeLog(result['action'])} '
      'errorCode=${_truncateBridgeLog(errorCode)}',
    );
  }

  void _showBridgeErrorIfNeeded(Map<String, dynamic> response) {
    if (!mounted || response['ok'] == true) {
      return;
    }
    final dynamic error = response['error'];
    if (error is! Map) {
      return;
    }
    final String message = error['message']?.toString().trim() ?? '';
    if (message.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<_BottomTab> _buildTabs() => const <_BottomTab>[
        _BottomTab(
          section: ShellSection.reservation,
          label: '??',
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
        ),
        _BottomTab(
          section: ShellSection.order,
          label: '?亙',
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
        ),
        _BottomTab(
          section: ShellSection.signature,
          label: '蝪賣',
          icon: Icons.draw_outlined,
          activeIcon: Icons.draw_rounded,
        ),
        _BottomTab(
          section: ShellSection.wallet,
          label: '?Ｗ?',
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
        ),
      ];
  Map<ShellSection, List<_MenuTile>> _buildMenuTiles() {
    final mapping = buildLegacyMenuMapping();
    return mapping.map((section, tiles) {
      return MapEntry(
        section,
        tiles.map(_menuTileFromLegacyMapping).toList(growable: false),
      );
    });
  }

  _MenuTile _menuTileFromLegacyMapping(LegacyMenuTileMapping tile) {
    switch (tile.actionType) {
      case LegacyMenuActionType.openWeb:
        final uri = WebUri(legacyAppUri(tile.webPath!).toString());
        return _MenuTile.web(label: tile.label, icon: tile.icon, uri: uri);
      case LegacyMenuActionType.openScanner:
        return _MenuTile.scanner(
          label: tile.label,
          icon: tile.icon,
          scanType: tile.scanType ?? 'default',
        );
      case LegacyMenuActionType.openShipment:
        return _MenuTile.simple(
          label: tile.label,
          icon: tile.icon,
          actionType: _MenuActionType.openShipment,
        );
      case LegacyMenuActionType.openSignature:
        return _MenuTile.simple(
          label: tile.label,
          icon: tile.icon,
          actionType: _MenuActionType.openSignature,
        );
      case LegacyMenuActionType.openSettings:
        return _MenuTile.simple(
          label: tile.label,
          icon: tile.icon,
          actionType: _MenuActionType.openSettings,
        );
      case LegacyMenuActionType.openMaps:
        return _MenuTile.simple(
          label: tile.label,
          icon: tile.icon,
          actionType: _MenuActionType.openMaps,
        );
      case LegacyMenuActionType.openArrivalUploadErrors:
        return _MenuTile.simple(
          label: tile.label,
          icon: tile.icon,
          actionType: _MenuActionType.openArrivalUploadErrors,
        );
      case LegacyMenuActionType.openProxyMenu:
        return _MenuTile.simple(
          label: tile.label,
          icon: tile.icon,
          actionType: _MenuActionType.openProxyMenu,
        );
      case LegacyMenuActionType.logout:
        return _MenuTile.simple(
          label: tile.label,
          icon: tile.icon,
          actionType: _MenuActionType.logout,
        );
      case LegacyMenuActionType.placeholder:
        return const _MenuTile.placeholder();
    }
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
    return _navigationHelper.isAllowedHost(host);
  }

  WebUri? _normalizeAllowedUri(WebUri uri) {
    final parsed = Uri.tryParse(uri.toString());
    if (parsed == null) {
      return null;
    }
    final normalized = _navigationHelper.normalizeAllowedHttpsUri(parsed);
    if (normalized == null) {
      return null;
    }
    return WebUri(normalized.toString());
  }

  Future<bool> _tryLaunchExternal(WebUri webUri) async {
    final parsed = Uri.tryParse(webUri.toString());
    if (parsed == null) {
      return false;
    }

    final decision = _navigationHelper.classifyExternalUri(parsed);
    if (!decision.shouldLaunchExternally) {
      return false;
    }

    if (decision.requiresMapPreflight) {
      final preflight = await _mapNavigationPreflight.ensureReady();
      if (!preflight.allowed) {
        if (mounted) {
          setState(() {
            _navState = _navState.copyWith(
              errorText: _navigationHelper.resolvePreflightError(preflight),
            );
          });
        }
        return false;
      }
    }

    return launchUrl(parsed, mode: LaunchMode.externalApplication);
  }

  Future<bool> _ensureLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return true;
    }
    if (status.isDenied || status.isRestricted || status.isLimited) {
      status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
    return false;
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
          _navState = _navState.copyWith(
            errorText: WebviewShellNavigationHelper.blockedNavigationMessage,
          );
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
      _didErrorFallback = false;
      _navState = _navState.enteringWeb(
        title: title,
        request: request,
        controllerReady: _controller != null,
      );
    });

    if (_controller == null) {
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

  Future<void> _openProxyMenu() async {
    if (!mounted) {
      return;
    }
    final selectedPath = await context.push<String>('/proxy-menu');
    if (!mounted || selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    final path = selectedPath.trim();
    final uri = path.startsWith('http')
        ? WebUri(path)
        : WebUri(legacyAppUri(path).toString());
    await _openWebPage(title: '代理', uri: uri);
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
            .showSnackBar(const SnackBar(content: Text('?餃憭望?嚗?e')));
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
      case _MenuActionType.openArrivalUploadErrors:
        if (mounted) {
          await context.push('/arrival-upload-errors');
        }
        break;
      case _MenuActionType.openProxyMenu:
        if (mounted) {
          await _openProxyMenu();
        }
        break;
      case _MenuActionType.openSettings:
        if (mounted) {
          await context.push('/settings');
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
      _navState = _navState.leavingWeb();
    });
  }

  Future<void> _handleBack() async {
    if (_inWeb) {
      await _handleWebBack();
      return;
    }
    if (_currentSection != ShellSection.reservation) {
      setState(() {
        _navState =
            _navState.copyWith(currentSection: ShellSection.reservation);
      });
      return;
    }
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  String _sectionTitle(ShellSection section) {
    switch (section) {
      case ShellSection.reservation:
        return '??';
      case ShellSection.order:
        return '?亙';
      case ShellSection.signature:
        return '蝪賣';
      case ShellSection.wallet:
        return '?Ｗ?';
    }
  }

  List<_MenuTile> _slotsForSection(ShellSection section) {
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color brand = colors.primary;

    final String title = (_inWeb && _webTitle != null && _webTitle!.isNotEmpty)
        ? _webTitle!
        : _sectionTitle(_currentSection);

    return Container(
      color: colors.surfaceContainerLowest,
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
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: brand,
                          size: 20,
                        ),
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
                      style: TextStyle(
                        color: brand,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 78,
                  child: IconButton(
                    key: !_inWeb ? topSettingsButtonKey : null,
                    onPressed: _inWeb
                        ? () => _controller?.reload()
                        : () => context.push('/settings'),
                    icon: Icon(
                      _inWeb ? Icons.refresh_rounded : Icons.settings_rounded,
                      color: brand,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 42,
            color: colors.inverseSurface,
            alignment: Alignment.center,
            child: Text(
              _announcement,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: colors.onInverseSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color brand = colors.primary;
    final Color inactive = colors.onSurfaceVariant;

    final List<_MenuTile> slots = _slotsForSection(_currentSection);

    return Container(
      color: Color.alphaBlend(
        colors.primary.withValues(alpha: 0.05),
        colors.surface,
      ),
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
              final Color iconColor = enabled ? brand : inactive;
              final Color textColor =
                  enabled ? colors.onSurface : colors.onSurfaceVariant;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: enabled ? () => _onTileTap(tile) : null,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.7),
                          width: 1.2),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6)),
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color brand = colors.primary;

    return Stack(
      children: <Widget>[
        InAppWebView(
          keepAlive: _keepAlive,
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            javaScriptCanOpenWindowsAutomatically: false,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: true,
            geolocationEnabled: true,
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
                _logBridgeIncoming(args);
                if (_isLegacyPrePage(args)) {
                  await _handleWebBack();
                  final response = <String, dynamic>{
                    'ok': true,
                    'action': 'legacy_pre_page_closed'
                  };
                  _logBridgeOutgoing(response);
                  return response;
                }
                final response = await _bridgeService.handle(args, context);
                _logBridgeOutgoing(response);
                _showBridgeErrorIfNeeded(response);
                return response;
              },
            );

            final URLRequest? pending = _navState.pendingRequest;
            if (pending != null) {
              if (mounted) {
                setState(() {
                  _navState = _navState.copyWith(clearPendingRequest: true);
                });
              }
              await controller.loadUrl(urlRequest: pending);
            }
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final WebUri? uri = navigationAction.request.url;
            if (uri == null) {
              return NavigationActionPolicy.CANCEL;
            }
            final String scheme = uri.scheme.toLowerCase();
            if (scheme == 'about' ||
                scheme == 'data' ||
                scheme == 'javascript') {
              return NavigationActionPolicy.ALLOW;
            }
            if (!_isAllowedHost(uri.host)) {
              if (await _tryLaunchExternal(uri)) {
                return NavigationActionPolicy.CANCEL;
              }
              if (mounted) {
                setState(() {
                  _navState = _navState.copyWith(
                    errorText:
                        WebviewShellNavigationHelper.blockedNavigationMessage,
                  );
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
                _navState = _navState.copyWith(loadingWeb: true);
              });
            }
          },
          onGeolocationPermissionsShowPrompt: (controller, origin) async {
            final originUri = Uri.tryParse(origin);
            final originHost = originUri?.host;
            final bool allowedOrigin = _isAllowedHost(originHost);
            final bool locationGranted =
                allowedOrigin ? await _ensureLocationPermission() : false;
            return GeolocationPermissionShowPromptResponse(
              allow: allowedOrigin && locationGranted,
              origin: origin,
              retain: allowedOrigin && locationGranted,
            );
          },
          onLoadStop: (controller, url) async {
            if (url != null &&
                !_didErrorFallback &&
                url.host.toLowerCase() == 'app.elf.com.tw' &&
                url.path.toLowerCase() == '/error.aspx') {
              _didErrorFallback = true;
              await _openWebPage(title: '??鞎其辣', uri: _reservationFallback);
              return;
            }
            try {
              await controller.evaluateJavascript(source: _bridgeAdapterScript);
            } catch (e) {
              if (mounted) {
                setState(() {
                  _navState = _navState.copyWith(
                      errorText: 'Bridge injection failed: $e');
                });
              }
            }
            if (mounted) {
              setState(() {
                _navState = _navState.copyWith(loadingWeb: false);
              });
            }
          },
          onReceivedError: (controller, request, error) {
            if (mounted) {
              setState(() {
                _navState = _navState.copyWith(
                  loadingWeb: false,
                  errorText: '${error.type}: ${error.description}',
                );
              });
            }
          },
          onConsoleMessage: (controller, consoleMessage) {
            final message = consoleMessage.message;
            if (message.contains('[BRIDGE]')) {
              debugPrint(
                '[WebConsole][${consoleMessage.messageLevel}] '
                '${_truncateBridgeLog(message)}',
              );
            }
          },
        ),
        if (_loadingWeb)
          Positioned.fill(
            child: ColoredBox(
              color: colors.surface.withValues(alpha: 0.55),
              child: Center(child: CircularProgressIndicator(color: brand)),
            ),
          ),
        if (_errorText != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade700,
              child: Text(_errorText!, style: TextStyle(color: colors.onError)),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color brand = colors.primary;
    final Color inactive = colors.onSurfaceVariant;

    return Container(
      key: bottomBarKey,
      height: 84,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: List<Widget>.generate(_tabs.length, (int index) {
          final _BottomTab tab = _tabs[index];
          final bool selected = tab.section == _currentSection;
          final Color color = selected ? brand : inactive;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _navState = _navState.selectSection(tab.section);
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
