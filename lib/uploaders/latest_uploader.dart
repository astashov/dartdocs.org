library dartdocorg.uploaders.latest_uploader;

import 'dart:async';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/storage.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:dartdocorg/package.dart';
import 'package:dartdocorg/utils.dart';

Logger _logger = new Logger("latest_uploader");

class LatestUploader {
  final Config config;
  final Storage storage;
  LatestUploader(this.config, this.storage);

  Future<Null> uploadLatestFiles(
      Map<Package, Map<String, String>> latestHtmlByPackages) async {
    for (var package in latestHtmlByPackages.keys) {
      _logger.info("Pointing latest to the package $package");
      var htmlsByRelativePaths = latestHtmlByPackages[package];
      var groupedRelativePaths = inGroupsOf(htmlsByRelativePaths.keys, 30);
      for (var relativePaths in groupedRelativePaths) {
        await Future.wait(relativePaths.map((relativePath) {
          var html = htmlsByRelativePaths[relativePath];
          return storage.insertContent(
              p.join(config.gcsPrefix, package.name, "latest", relativePath),
              html,
              "text/html",
              maxAge: 60);
        }));
      }
    }
  }
}
