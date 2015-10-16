library dartdoc_generator.datastore;

import 'dart:async';

import 'package:dartdoc_generator/config.dart';
import 'package:googleapis_beta/datastore/v1beta2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:dartdoc_generator/package.dart';
import 'package:dartdoc_generator/version.dart';
import 'package:dartdoc_generator/utils/retry.dart';
import 'package:logging/logging.dart';

Logger _logger = new Logger("datastore");

class Datastore {
  static const _scopes = const [DatastoreApi.DatastoreScope, DatastoreApi.UserinfoEmailScope];

  final Config config;

  Future<DatastoreApi> _datastoreApiInst;

  Datastore(this.config);

  Future<DatastoreApi> get _datastoreApi async {
    if (_datastoreApiInst == null) {
      _datastoreApiInst = clientViaServiceAccount(config.credentials, _scopes).then((httpClient) {
        return new DatastoreApi(httpClient);
      });
    }
    return _datastoreApiInst;
  }

  Future<int> docsVersion() async {
    DatastoreApi api = (await _datastoreApi);
    LookupResponse result = await retry(() {
      return api.datasets.lookup(
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
      return int.parse(result.found.first.entity.properties["value"].integerValue);
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
          "value": {"integerValue": version},
        }
      }
    ]);
  }

  Future<Null> upsert(Package package, int docsVersion, {String status: "success"}) async {
    var updatedAt = new DateTime.now().toUtc().toIso8601String();
    await _upsert([
      {
        "key": {
          "path": [
            {"kind": "Package", "name": "${package.name}/${package.version}"}
          ]
        },
        "properties": {
          "packageName": {"stringValue": package.name, "indexed": true},
          "packageVersion": {"stringValue": package.version.toString()},
          "status": {"stringValue": status ?? "success", "indexed": true},
          "docsVersion": {"integerValue": docsVersion, "indexed": true},
          "updatedAt": {"dateTimeValue": updatedAt, "indexed": true}
        }
      }
    ]);
  }

  Future<CommitResponse> _upsert(List<Map> maps) async {
    DatastoreApi api = (await _datastoreApi);
    var transaction = await retry(() async {
      return (await (api.datasets.beginTransaction(new BeginTransactionRequest(), config.gcProjectName))).transaction;
    });
    return retry(() {
      return api.datasets.commit(
          new CommitRequest.fromJson({
            "transaction": transaction,
            "mutation": {"upsert": maps}
          }),
          config.gcProjectName);
    });
  }

  Future<Iterable<Package>> getPackages({int docsVersion, String status, DateTime updatedAt}) async {
    DatastoreApi api = (await _datastoreApi);
    var filters = [];
    if (docsVersion != null) {
      filters.add({
        "propertyFilter": {
          "property": {"name": "docsVersion"},
          "operator": 'EQUAL',
          "value": {"integerValue": docsVersion}
        }
      });
    }
    if (status != null) {
      filters.add({
        "propertyFilter": {
          "property": {"name": "status"},
          "operator": 'EQUAL',
          "value": {"stringValue": status}
        }
      });
    }
    if (updatedAt != null) {
      filters.add({
        "propertyFilter": {
          "property": {"name": "updatedAt"},
          "operator": 'GREATER_THAN_OR_EQUAL',
          "value": {"dateTimeValue": updatedAt}
        }
      });
    }

    var result = await retry(() {
      return api.datasets.runQuery(
          new RunQueryRequest.fromJson({
            "query": {
              "kinds": [
                {"name": 'Package'}
              ],
              "filter": {
                "compositeFilter": {"operator": "AND", "filters": filters}
              }
            }
          }),
          config.gcProjectName);
    });
    return result.batch.entityResults.map((er) {
      var entity = er.entity;
      return new Package(entity.properties["packageName"].stringValue,
          new Version(entity.properties["packageVersion"].stringValue), entity.properties["updatedAt"].dateTimeValue);
    });
  }
}
