import 'package:ambrosia/pipeline/extraction.dart';
import 'package:ambrosia/pipeline/extraction_service.dart';
import 'package:ambrosia/pipeline/extractor.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeExtractor implements Extractor {
  FakeExtractor({
    this.modelReady = true,
    this.result = const Extraction(diagnosis: 'Viral fever'),
    this.throwMessage,
  });

  bool modelReady;
  Extraction result;
  String? throwMessage;

  int downloadCount = 0;
  int extractCount = 0;

  @override
  Future<bool> isModelReady() async => modelReady;

  @override
  Future<void> downloadModel() async {
    downloadCount++;
    modelReady = true;
  }

  @override
  Future<Extraction> extract(String transcript) async {
    extractCount++;
    if (throwMessage != null) throw ExtractionException(throwMessage!);
    return result;
  }
}

void main() {
  test('extracts directly when the model is present', () async {
    final fake = FakeExtractor();
    final service = ExtractionService(extractor: fake);

    await service.run('fever three days, paracetamol');

    expect(service.status, ExtractionStatus.done);
    expect(service.extraction?.diagnosis, 'Viral fever');
    expect(fake.downloadCount, 0);
  });

  test('downloads the model first when missing', () async {
    final fake = FakeExtractor(modelReady: false);
    final service = ExtractionService(extractor: fake);

    final seen = <ExtractionStatus>[];
    service.addListener(() => seen.add(service.status));

    await service.run('transcript');

    expect(fake.downloadCount, 1);
    expect(seen, contains(ExtractionStatus.preparingModel));
    expect(seen, contains(ExtractionStatus.extracting));
    expect(service.status, ExtractionStatus.done);
  });

  test('surfaces an extraction failure', () async {
    final service = ExtractionService(
      extractor: FakeExtractor(throwMessage: 'model returned junk'),
    );

    await service.run('transcript');

    expect(service.status, ExtractionStatus.error);
    expect(service.errorMessage, 'model returned junk');
  });

  test('ignores a second run while busy', () async {
    final fake = FakeExtractor();
    final service = ExtractionService(extractor: fake);

    final a = service.run('one');
    final b = service.run('two');
    await Future.wait([a, b]);

    expect(fake.extractCount, 1);
  });
}
