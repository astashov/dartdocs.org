library dartdocorg.datastore;

import 'dart:async';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/package.dart';
import 'package:dartdocorg/utils/retry.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/datastore/v1.dart';
import 'package:logging/logging.dart';

final Logger _logger = new Logger("datastore");

class Datastore {
  static const _scopes = const [DatastoreApi.DatastoreScope];

  final Config config;

  Future<DatastoreApi> _datastoreApiInst;

  Datastore(this.config);

  Future<DatastoreApi> get _datastoreApi async {
    if (_datastoreApiInst == null) {
      _datastoreApiInst = clientViaServiceAccount(config.credentials, _scopes)
          .then((httpClient) {
        return new DatastoreApi(httpClient);
      });
    }
    return _datastoreApiInst;
  }

  Future<int> docsVersion() async {
    DatastoreApi api = (await _datastoreApi);
    LookupResponse result = await retry(() {
      return api.projects.lookup(
          new LookupRequest.fromJson({
            "keys": [
              {
                "path": [
                  {"kind": "DocsVersion", "name": "docsVersion"}
                ]
              }
            ]
          }),
          config.gcProjectName);
    });
    if (result.found.isNotEmpty) {
      return int
          .parse(result.found.first.entity.properties["value"].integerValue);
    } else {
      return null;
    }
  }

  Future<Null> bumpDocsVersion(int version) async {
    await _upsert([
      {
        "key": {
          "path": [
            {"kind": "DocsVersion", "name": "docsVersion"}
          ]
        },
        "properties": {
          "value": {"integerValue": version.toString()},
        }
      }
    ]);
  }

  Future<Null> upsert(Package package, int docsVersion,
      {String status: "success"}) async {
    var updatedAt = new DateTime.now().toUtc().toIso8601String();
    await _upsert([
      {
        "key": {
          "path": [
            {"kind": "Package", "name": "${package.name}/${package.version}"}
          ]
        },
        "properties": {
          "packageName": {"stringValue": package.name},
          "packageVersion": {"stringValue": package.version.toString()},
          "status": {"stringValue": status ?? "success", "indexed": true},
          "docsVersion": {"integerValue": docsVersion.toString()},
          "updatedAt": {"timestampValue": updatedAt}
        }
      }
    ]);
  }

  Future<CommitResponse> _upsert(List<Map> maps) async {
    DatastoreApi api = (await _datastoreApi);
    return retry(() async {
      var transaction = (await (api.projects.beginTransaction(
          new BeginTransactionRequest(), config.gcProjectName))).transaction;
      return api.projects.commit(
          new CommitRequest.fromJson({
            "transaction": transaction,
            "mutations": maps.map((map) => {"upsert": map})
          }),
          config.gcProjectName);
    });
  }

  Future<Iterable<Package>> getPackages(
      {int docsVersion, String status, DateTime updatedAt}) async {
    DatastoreApi api = (await _datastoreApi);
    var filters = [];
    if (docsVersion != null) {
      filters.add({
        "propertyFilter": {
          "property": {"name": "docsVersion"},
          "op": 'EQUAL',
          "value": {"integerValue": docsVersion.toString()}
        }
      });
    }
    if (status != null) {
      filters.add({
        "propertyFilter": {
          "property": {"name": "status"},
          "op": 'EQUAL',
          "value": {"stringValue": status}
        }
      });
    }
    if (updatedAt != null) {
      filters.add({
        "propertyFilter": {
          "property": {"name": "updatedAt"},
          "op": 'GREATER_THAN_OR_EQUAL',
          "value": {"timestampValue": updatedAt.toUtc().toIso8601String()}
        }
      });
    }

    var shouldContinue = true;
    var packages = [];
    var cursor = "";
    while (shouldContinue) {
      var result = await retry(() {
        return api.projects.runQuery(
            new RunQueryRequest.fromJson({
              "query": {
                "startCursor": cursor,
                "kind": [{"name": "Package"}],
                "filter": {
                  "compositeFilter": {"op": "AND", "filters": filters}
                }
              }
            }),
            config.gcProjectName);
      });
      packages.addAll((result.batch.entityResults ?? []).map((er) {
        var entity = er.entity;
        return new Package.build(
            entity.properties["packageName"].stringValue,
            entity.properties["packageVersion"].stringValue,
            entity.properties["updatedAt"].timestampValue);
      }));
      cursor = result.batch.endCursor;
      shouldContinue = result.batch.moreResults == "NOT_FINISHED";
    }
    return packages;
  }
}
