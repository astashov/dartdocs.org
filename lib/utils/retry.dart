library dartdoc_runner.utils.retry;

import 'dart:async';
import 'package:logging/logging.dart';

Logger _logger = new Logger("retry");

const _defaultDurations = const [const Duration(seconds: 3), const Duration(seconds: 5), const Duration(seconds: 15)];

Future<dynamic> retry(body(), {int number: 3, Iterable<Duration> durations: _defaultDurations}) async {
  try {
    var result = await body();
    return result;
  } catch (error, _) {
    if (number > 0) {
      var duration = durations.first;
      var newDurations = new List.from(durations);
      if (newDurations.length > 1) {
        newDurations.removeAt(0);
      }
      var newNumber = number - 1;
      _logger.warning(
          "Got an exception: $error, retrying, retries left: $newNumber, waiting for ${duration.inSeconds}s");
      return new Future.delayed(duration, () => retry(body, number: newNumber, durations: newDurations));
    } else {
      _logger.warning("Got an exception: $error, out of retries, rethrowing...");
      rethrow;
    }
  }
}
