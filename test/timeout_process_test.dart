library dartdocorg.test.timeout_processtest;

import 'package:dartdocorg/utils.dart';
import 'package:test/test.dart';

main() {
  test('quick enough', () async {
    var result =
        await runProcessWithTimeout('sleep', ['1'], const Duration(seconds: 2));
    expect(result.exitCode, 0);
  });

  test('too slow', () async {
    var result =
        await runProcessWithTimeout('sleep', ['2'], const Duration(seconds: 1));
    expect(result.exitCode, lessThan(0));
  });
}
