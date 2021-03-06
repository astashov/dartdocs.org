library dartdocorg.uploaders.latest_uploader;

import 'dart:async';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/package.dart';
import 'package:dartdocorg/storage.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:tasks/utils.dart';

final Logger _logger = new Logger("latest_uploader");

class LatestUploader {
  final Config config;
  final Storage storage;
  LatestUploader(this.config, this.storage);

  Future<Null> uploadLatestFiles(
      Map<Package, Map<String, String>> latestHtmlByPackages) async {
    for (var package in latestHtmlByPackages.keys) {
      _logger.info("Pointing latest to the package $package");
      var htmlsByRelativePaths = latestHtmlByPackages[package];
      await pmap(htmlsByRelativePaths.keys, (relativePath) {
        var html = htmlsByRelativePaths[relativePath];
        return storage.insertContent(
            p.join(config.gcsPrefix, package.name, "latest", relativePath),
            html,
            "text/html",
            maxAge: 60);
      }, concurrencyCount: 30);
    }
  }
}
