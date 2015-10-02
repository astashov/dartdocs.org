library dartdoc_runner.storage_retriever;

import 'dart:async';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/package.dart';
import 'package:dartdoc_runner/storage.dart';
import 'package:dartdoc_runner/version.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

var _logger = new Logger("storage_retriever");

class StorageRetriever {
  Set<Package> _successList = new Set();
  Set<Package> _errorList = new Set();

  Config _config;
  Storage _storage;

  StorageRetriever(this._config, this._storage);

  Set<Package> get allPackages => new Set()..addAll(successPackages)..addAll(errorPackages);
  Set<Package> get errorPackages => _errorList;

  Set<Package> get successPackages => _successList;

  Future<Null> update() async {
    var items = await _storage.list(prefix: p.join(_config.gcsMeta));
    if (items.isNotEmpty) {
      var regexp = new RegExp(r"([^/]+)/([^/]+)/([^/]+)/([^/]+)/?$"); // meta/(success)/(20150927155516)/(path)/(1.3.5)
      for (var item in items) {
        var match = regexp.firstMatch(item);
        if (match != null) {
          var type = match[1];
          var dateMatch = new RegExp(r'(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})').firstMatch(match[2]);
          var createdAt = new DateTime(int.parse(dateMatch[1]), int.parse(dateMatch[2]), int.parse(dateMatch[3]),
              int.parse(dateMatch[4]), int.parse(dateMatch[5]), int.parse(dateMatch[6]));
          var name = match[3];
          var version = match[4];
          var package = new Package(name, new Version(version), createdAt);
          if (type == "success") {
            _successList.add(package);
          } else if (type == "error") {
            _errorList.add(package);
          }
        }
      }
    }
  }
}
