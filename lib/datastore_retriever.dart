library dartdocorg.datastore_retriever;

import 'dart:async';

import 'package:dartdocorg/package.dart';
import 'package:dartdocorg/datastore.dart';
import 'package:logging/logging.dart';

var _logger = new Logger("datastore_retriever");

class DatastoreRetriever {
  Set<Package> _successList = new Set();
  Set<Package> _errorList = new Set();
  DateTime _lastUpdatedAt;
  int _lastDocsVersion;

  final Datastore _datastore;

  DatastoreRetriever(this._datastore);

  Set<Package> get allPackages =>
      new Set()..addAll(successPackages)..addAll(errorPackages);
  Set<Package> get errorPackages => _errorList;
  Set<Package> get successPackages => _successList;

  Future<Null> update([int docsVersion]) async {
    if (_lastUpdatedAt == null || docsVersion != _lastDocsVersion) {
      _logger.info(
          "Retrieving the initial list of meta packages from Google Datastore");
      _lastUpdatedAt = new DateTime.now();
      _successList = (await _datastore.getPackages(
          docsVersion: docsVersion, status: "success")).toSet();
      _errorList = (await _datastore.getPackages(
          docsVersion: docsVersion, status: "error")).toSet();
      _logger.info(
          "Successful packages - ${successPackages.length}, erroneous packages - ${errorPackages.length}");
      _lastDocsVersion = docsVersion;
    } else {
      _logger.info(
          "Retrieving the updated list of meta packages from Google Datastore");
      var newSuccessPackages = await _datastore.getPackages(
          docsVersion: docsVersion,
          status: "success",
          updatedAt: _lastUpdatedAt);
      _successList.addAll(newSuccessPackages);
      var newErrorPackages = await _datastore.getPackages(
          docsVersion: docsVersion, status: "error", updatedAt: _lastUpdatedAt);
      _errorList.addAll(newErrorPackages);
      _logger.info(
          "New successful packages - ${newSuccessPackages.length}, new erroneous packages - ${newErrorPackages.length}");
      _lastUpdatedAt = new DateTime.now();
    }
  }
}
