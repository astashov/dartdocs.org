library dartdocorg.logging;

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

void initialize([int index]) {
  Logger.root.onRecord.listen((record) {
    if (record.loggerName != "ConnectionPool") {
      print(logFormatter(record, index: index));
    }
  });

  Logger.root.level = Level.FINE;
}

String logFormatter(LogRecord record,
    {int index, bool shouldConvertToPTZ: false}) {
  var timeString = new DateFormat("H:m:s.S").format(record.time);
  var buffer = new StringBuffer();
  var name = record.loggerName.replaceAll(new RegExp(r"^crossdart\."), "");
  if (index != null) {
    buffer.write("$index - ");
  }
  buffer.write("$timeString ");

  // make an indent string that's the length of the buffer so far
  // used to indent multi-line messages
  var indent = ' ' * buffer.length;

  buffer.write("[${record.level.name}] $name:");

  var lines =
      _linesForObjectStrings([record.message, record.error, record.stackTrace])
          .toList();

  if (lines.length == 1) {
    // If the message is only one line, put it on the line with the header
    buffer.write(lines.single);
  } else if (lines.length > 1) {
    // If it's more than one line, indent the contents
    buffer.writeln();
    buffer.writeAll(lines.map((line) => "$indent$line"), '\n');
  }
  return buffer.toString();
}

Iterable<String> _linesForObjectStrings(List objects) sync* {
  for (var object in objects) {
    if (object != null) {
      yield* LineSplitter.split('$object');
    }
  }
}
