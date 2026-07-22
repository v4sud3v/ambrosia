import 'package:ambrosia/pipeline/explainer.dart';
import 'package:ambrosia/pipeline/explanation.dart';
import 'package:ambrosia/pipeline/explanation_service.dart';
import 'package:ambrosia/pipeline/extraction.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeExplainer implements Explainer {
  FakeExplainer({
    this.modelReady = true,
    this.result = const Explanation(condition: 'A mild viral fever.'),
    this.throwMessage,
  });

  bool modelReady;
  Explanation result;
  String? throwMessage;

  int downloadCount = 0;
  int explainCount = 0;
  Extraction? lastInput;

  @override
  Future<bool> isModelReady() async => modelReady;

  @override
  Future<void> downloadModel() async {
    downloadCount++;
    modelReady = true;
  }

  @override
  Future<Explanation> explain(Extraction extraction) async {
    explainCount++;
    lastInput = extraction;
    if (throwMessage != null) throw ExplanationException(throwMessage!);
    return result;
  }
}

const _extraction = Extraction(diagnosis: 'Viral fever');

void main() {
  test('explains directly when the model is present', () async {
    final fake = FakeExplainer();
    final service = ExplanationService(explainer: fake);

    await service.run(_extraction);

    expect(service.status, ExplanationStatus.done);
    expect(service.explanation?.condition, 'A mild viral fever.');
    expect(fake.downloadCount, 0);
    expect(fake.lastInput?.diagnosis, 'Viral fever');
  });

  test('downloads the model first when missing', () async {
    final fake = FakeExplainer(modelReady: false);
    final service = ExplanationService(explainer: fake);

    final seen = <ExplanationStatus>[];
    service.addListener(() => seen.add(service.status));

    await service.run(_extraction);

    expect(fake.downloadCount, 1);
    expect(seen, contains(ExplanationStatus.preparingModel));
    expect(seen, contains(ExplanationStatus.explaining));
    expect(service.status, ExplanationStatus.done);
  });

  test('surfaces a failure', () async {
    final service = ExplanationService(
      explainer: FakeExplainer(throwMessage: 'no plain words'),
    );

    await service.run(_extraction);

    expect(service.status, ExplanationStatus.error);
    expect(service.errorMessage, 'no plain words');
  });

  test('ignores a second run while busy', () async {
    final fake = FakeExplainer();
    final service = ExplanationService(explainer: fake);

    final a = service.run(_extraction);
    final b = service.run(_extraction);
    await Future.wait([a, b]);

    expect(fake.explainCount, 1);
  });
}
