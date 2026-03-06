import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/features/webview_shell/domain/bridge_action_models.dart';

void main() {
  test('AppEventKind maps legacy aliases', () {
    expect(AppEventKind.fromRaw('map'), AppEventKind.map);
    expect(AppEventKind.fromRaw('GM\u5c0e\u822a'), AppEventKind.map);
    expect(AppEventKind.fromRaw('GM\u5916\u90e8'), AppEventKind.map);
    expect(AppEventKind.fromRaw('\u5c0e\u822a'), AppEventKind.map);
    expect(AppEventKind.fromRaw('\u5730\u5716\u5b9a\u4f4d'), AppEventKind.map);
    expect(
      AppEventKind.fromRaw('\u5b9a\u4f4d\u55ae\u9ede\u898f\u5283'),
      AppEventKind.map,
    );

    expect(AppEventKind.fromRaw('dial'), AppEventKind.dial);
    expect(AppEventKind.fromRaw('\u64a5\u865f'), AppEventKind.dial);
    expect(AppEventKind.fromRaw('\u624b\u6a5f'), AppEventKind.dial);
    expect(AppEventKind.fromRaw('\u96fb\u8a71'), AppEventKind.dial);

    expect(AppEventKind.fromRaw('close'), AppEventKind.close);
    expect(AppEventKind.fromRaw('\u95dc\u9589'), AppEventKind.close);
    expect(AppEventKind.fromRaw('\u4e0a\u4e00\u9801'), AppEventKind.close);

    expect(AppEventKind.fromRaw('contract'), AppEventKind.contract);
    expect(AppEventKind.fromRaw('\u5408\u7d04'), AppEventKind.contract);
  });
}
