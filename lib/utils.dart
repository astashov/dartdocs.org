library dartdocorg.utils;

import 'dart:async';
import 'dart:io';

Map groupBy(Iterable collection, condition(i)) {
  return collection.fold({}, (memo, item) {
    var key = condition(item);
    if (memo[key] == null) {
      memo[key] = [];
    }
    memo[key].add(item);
    return memo;
  });
}

Map groupByOne(Iterable collection, condition(i)) {
  return collection.fold({}, (memo, item) {
    memo[condition(item)] = item;
    return memo;
  });
}

/// Combines the hash codes for a list of objects.
///
/// Useful when computing the hash codes based on the properties of a custom class.
///
/// For example:
///
///     class Person {
///       String firstName;
///       String lastName;
///
///       int get hashCode => hash([firstName, lastName]);
///     }
///
int hash(Iterable<Object> objects) {
  // 31 seems to be the defacto number when generating hash codes. It's also used in WebUI.
  //
  // See:
  // - http://stackoverflow.com/questions/299304/why-does-javas-hashcode-in-string-use-31-as-a-multiplier
  // - http://stackoverflow.com/questions/1835976/what-is-a-sensible-prime-for-hashcode-calculation
  // - https://github.com/dart-lang/web-ui/blob/022d3312c4f84c57732bd3fbff1627cae4014b60/lib/src/utils_observe.dart#L11
  return objects.fold(0, (prev, curr) => (prev * 31) + curr.hashCode);
}

/// inGroups([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 3).forEach((i) => print(i));
///
/// ["1", "2", "3", "4"]
/// ["5", "6", "7"]
/// ["8", "9", "10"]
Iterable<Iterable> inGroups(Iterable collection, int number,
    [fillWith = null]) {
  var coll = collection.toList();
  var division = collection.length ~/ number;
  var modulo = collection.length % number;

  var groups = [];
  var start = 0;

  for (int index = 0; index < number; index += 1) {
    var length = division + (modulo > 0 && modulo > index ? 1 : 0);
    var lastGroup = coll.getRange(start, start + length);
    groups.add(lastGroup);
    if (fillWith != null && modulo > 0 && length == division) {
      lastGroup.add(fillWith);
    }
    start += length;
  }

  return groups;
}

/// inGroupsOf([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 3).forEach((e) => print(e));
///
/// ["1", "2", "3"]
/// ["4", "5", "6"]
/// ["7", "8", "9"]
/// ["10"]
Iterable<Iterable> inGroupsOf(Iterable collection, int number) {
  if (collection.isEmpty) {
    return [];
  } else {
    var result = [[]];
    for (var item in collection) {
      List lastColl = result.last;
      if (lastColl.length >= number) {
        lastColl = [];
        result.add(lastColl);
      }
      lastColl.add(item);
    }
    return result;
  }
}

Future<ProcessResult> runProcessWithTimeout(
    String executable, List<String> arguments, Duration timeout,
    {String workingDirectory}) async {
  Process proc = await Process.start(executable, arguments,
      workingDirectory: workingDirectory);

  var timer = new Timer(timeout, () {
    proc.kill();
  });

  var stdout = await SYSTEM_ENCODING.decodeStream(proc.stdout);
  var stderr = await SYSTEM_ENCODING.decodeStream(proc.stderr);

  var exitCode = await proc.exitCode;

  timer.cancel();

  return new ProcessResult(proc.pid, exitCode, stdout, stderr);
}
