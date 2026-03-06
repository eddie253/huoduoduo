import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mobile_flutter/features/webview_shell/domain/shell_navigation_state.dart';

void main() {
  test('initial state starts at reservation root', () {
    final state = ShellNavigationState.initial();

    expect(state.currentSection, ShellSection.reservation);
    expect(state.inWeb, isFalse);
    expect(state.loadingWeb, isFalse);
    expect(state.webTitle, isNull);
    expect(state.errorText, isNull);
    expect(state.pendingRequest, isNull);
  });

  test('enteringWeb stores pending request when webview is not ready', () {
    final request =
        URLRequest(url: WebUri('https://old.huoduoduo.com.tw/app/'));
    final state = ShellNavigationState.initial().enteringWeb(
      title: '預約貨件',
      request: request,
      controllerReady: false,
    );

    expect(state.inWeb, isTrue);
    expect(state.loadingWeb, isTrue);
    expect(state.webTitle, '預約貨件');
    expect(state.pendingRequest, isNotNull);
  });

  test('enteringWeb clears pending request when webview is ready', () {
    final request =
        URLRequest(url: WebUri('https://old.huoduoduo.com.tw/app/'));
    final state = ShellNavigationState.initial().enteringWeb(
      title: '預約貨件',
      request: request,
      controllerReady: true,
    );

    expect(state.pendingRequest, isNull);
  });

  test('leavingWeb returns to tab root and clears transient fields', () {
    final request =
        URLRequest(url: WebUri('https://old.huoduoduo.com.tw/app/'));
    final state = ShellNavigationState.initial()
        .enteringWeb(
          title: '接單明細',
          request: request,
          controllerReady: false,
        )
        .copyWith(errorText: 'error')
        .leavingWeb();

    expect(state.inWeb, isFalse);
    expect(state.loadingWeb, isFalse);
    expect(state.webTitle, isNull);
    expect(state.errorText, isNull);
    expect(state.pendingRequest, isNull);
  });

  test('isSectionStale returns true when section has never been active', () {
    final state = ShellNavigationState.initial();
    expect(state.isSectionStale(ShellSection.wallet), isTrue);
  });

  test('markSectionActive records timestamp so section is no longer stale', () {
    final state =
        ShellNavigationState.initial().markSectionActive(ShellSection.wallet);
    expect(
      state.isSectionStale(ShellSection.wallet,
          threshold: const Duration(seconds: 60)),
      isFalse,
    );
  });

  test('markSectionStale removes timestamp so section becomes stale again', () {
    final state = ShellNavigationState.initial()
        .markSectionActive(ShellSection.wallet)
        .markSectionStale(ShellSection.wallet);
    expect(state.isSectionStale(ShellSection.wallet), isTrue);
  });

  test('copyWith carries sectionLastActiveAt through', () {
    final original =
        ShellNavigationState.initial().markSectionActive(ShellSection.order);
    final copied = original.copyWith(inWeb: true);
    expect(
      copied.isSectionStale(ShellSection.order,
          threshold: const Duration(seconds: 60)),
      isFalse,
    );
  });

  test('selectSection keeps selected tab and resets web overlay state', () {
    final request =
        URLRequest(url: WebUri('https://old.huoduoduo.com.tw/app/'));
    final state = ShellNavigationState.initial()
        .enteringWeb(
          title: '送達明細',
          request: request,
          controllerReady: false,
        )
        .selectSection(ShellSection.wallet);

    expect(state.currentSection, ShellSection.wallet);
    expect(state.inWeb, isFalse);
    expect(state.loadingWeb, isFalse);
    expect(state.webTitle, isNull);
    expect(state.pendingRequest, isNull);
  });
}
