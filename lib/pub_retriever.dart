library dartdocorg.pub_retriever;

import 'dart:async';
import 'dart:convert';

import 'package:dartdocorg/package.dart';
import 'package:dartdocorg/utils/retry.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _logger = new Logger("pub_retriever");

String _getUrl(int page) => "https://pub.dartlang.org/packages.json?page=$page";

class PubRetriever {
  List<Package> _currentList = [];
  Iterable<Package> get currentList => _currentList;

  Map<String, List<Package>> _packagesByName = {};
  Map<String, Iterable<Package>> get packagesByName => _packagesByName;

  PubRetriever();

  Future<List<Package>> update() async {
    _logger.info("Retrieving available packages...");
    var page = 1;

    var json;
    do {
      _logger.info("Retrieving page $page");
      json = await retry(
          () => http.get(_getUrl(page)).then((r) => JSON.decode(r.body)));
      page += 1;
      var pageOfPackages = await Future.wait(json["packages"].map((packageUrl) {
        return retry(
            () => http.get(packageUrl).then((r) => JSON.decode(r.body)));
      }));
      var packages = pageOfPackages.map((packageMap) {
        return packageMap["versions"].map((version) {
          return new Package.build(packageMap["name"], version);
        });
      }).expand((i) => i);
      if (packages.every((p) => _currentList.contains(p))) {
        break;
      } else {
        packages.forEach((package) {
          if (!_currentList.contains(package)) {
            _currentList.add(package);
            if (_packagesByName[package.name] == null) {
              _packagesByName[package.name] = [];
            }
            _packagesByName[package.name].add(package);
          }
        });
      }
    } while (json["next"] != null);
    //} while (page < 2);

    _logger
        .info("The number of the available packages - ${_currentList.length}");
    return new List.from(_currentList);
  }
}
