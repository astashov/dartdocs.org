library dartdoc_generator.logging;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

void initialize([int index]) {
  Logger.root.onRecord.listen((record) {
    if (record.loggerName != "ConnectionPool") {
      print(logFormatter(record, index: index));
    }
  });

  Logger.root.level = Level.INFO;
}

String logFormatter(LogRecord record, {int index, bool shouldConvertToPTZ: false}) {
  var timeString = new DateFormat("H:m:s.S").format(record.time);
  String message = "";
  var name = record.loggerName.replaceAll(new RegExp(r"^crossdart\."), "");
  if (index != null) {
    message += "$index - ";
  }
  message += "$timeString [${record.level.name}] $name: ${record.message}";
  if (record.error != null) {
    message += "\n${record.error}\n${record.stackTrace}";
  }
  return message;
}
