import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/bridge/ambrosia_bridge.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('shows recording action', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(engine: _FakeEngine()));

    expect(find.text('Ambrosia'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
  });
}

class _FakeEngine implements AmbrosiaEngine {
  @override
  AmbrosiaAudioResult processAudioFile(String path) {
    return const AmbrosiaAudioResult(
      message: 'audio processed locally',
      bytes: 1,
    );
  }
}
