library dartdocorg.uploaders.latest_uploader;

import 'dart:async';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/storage.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:dartdocorg/package.dart';

Logger _logger = new Logger("latest_uploader");

class LatestUploader {
  final Config config;
  final Storage storage;
  LatestUploader(this.config, this.storage);

  Future<Null> uploadLatestFiles(Map<Package, String> latestHtmlByPackages) async {
    for (var package in latestHtmlByPackages.keys) {
      _logger.info("Pointing latest to the package $package");
      var html = latestHtmlByPackages[package];
      await storage.insertContent(
          p.join(config.gcsPrefix, package.name, "latest", "index.html"),
          html,
          "text/html",
          maxAge: 60);
    }
  }
}
