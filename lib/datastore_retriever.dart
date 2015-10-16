library dartdoc_generator.datastore_retriever;

import 'dart:async';

import 'package:dartdoc_generator/config.dart';
import 'package:dartdoc_generator/package.dart';
import 'package:dartdoc_generator/datastore.dart';
import 'package:logging/logging.dart';

var _logger = new Logger("datastore_retriever");

class DatastoreRetriever {
  Set<Package> _successList = new Set();
  Set<Package> _errorList = new Set();

  final Config _config;
  final Datastore _datastore;

  DatastoreRetriever(this._config, this._datastore);

  Set<Package> get allPackages => new Set()..addAll(successPackages)..addAll(errorPackages);
  Set<Package> get errorPackages => _errorList;
  Set<Package> get successPackages => _successList;

  Future<Null> update([int docsVersion]) async {
    // TODO: Use updatedAt to avoid retrieving the whole list every time.
    // TODO: Then, in this case we need to clear the lists once docsVersion is changed
    _successList = await _datastore.getPackages(docsVersion: docsVersion, status: "success");
    _errorList = await _datastore.getPackages(docsVersion: docsVersion, status: "error");
  }
}
