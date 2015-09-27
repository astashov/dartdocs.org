library dartdoc_runner.storage_retriever;

import 'dart:async';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/package.dart';
import 'package:dartdoc_runner/version.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:dartdoc_runner/storage.dart';

var _logger = new Logger("storage_retriever");

Future<Set<Package>> retrieveFromStorage(Config config, Storage storage) async {
  var items = await storage.list(prefix: p.join(config.gcsMeta));
  if (items.isNotEmpty) {
    var regexp = new RegExp(r"([^/]+)/([^/]+)/?$"); // meta/success/(path)/(1.3.5)
    return items.fold(new Set(), (Set set, item) {
      var match = regexp.firstMatch(item);
      if (match != null) {
        var name = match[1];
        var version = match[2];
        set.add(new Package(name, new Version(version)));
      }
      return set;
    });
  } else {
    return new Set();
  }
}
