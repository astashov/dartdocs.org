library dartdocorg.uploaders.package_uploader;

import 'dart:async';
import 'dart:io';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/package.dart';
import 'package:dartdocorg/storage.dart';
import 'package:dartdocorg/utils.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

Logger _logger = new Logger("package_uploader");

class PackageUploader {
  final Config config;
  final Storage storage;
  PackageUploader(this.config, this.storage);

  Future<Null> markErroredPackages(Iterable<Package> packages) async {
    var timeString = _getTimeString();
    await Future.wait(packages.map((package) async {
      return _uploadMeta("error", timeString, package);
    }));
  }

  Future<Null> markSuccessfulPackages(Iterable<Package> packages) async {
    var timeString = _getTimeString();
    await Future.wait(packages.map((package) async {
      return _uploadMeta("success", timeString, package);
    }));
  }

  Future<Null> uploadErroredPackages(Iterable<Package> packages) async {
    await Future.wait(packages.map((package) async {
      _logger.info("Uploading error log file for $package to GCS");
      var logFile = new File(p.join(package.logFile(config)));
      var path = p.join(config.gcsPrefix, package.name, package.version.toString(), "log.txt");
      return storage.insertFile(path, logFile);
    }));
  }

  Future<Null> uploadSuccessfulPackages(Iterable<Package> packages) async {
    for (var package in packages) {
      _logger.info("Uploading package files $package to GCS");
      var entities = await new Directory(package.outputDir(config)).list(recursive: true).toList();
      var groups = inGroupsOf(entities.where((e) => e is File), 10);
      for (Iterable group in groups) {
        await Future.wait(group.map((entity) {
          var relative = entity.path.replaceFirst("${package.outputDir(config)}/", "");
          var path = p.join(config.gcsPrefix, package.name, package.version.toString(), relative);
          return storage.insertFile(path, entity);
        }));
      }
    }
  }

  String _getTimeString() {
    return new DateFormat("yyyyMMddHHmmss").format(new DateTime.now().toUtc());
  }

  Future<Null> _uploadMeta(String type, String timeString, Package package) async {
    _logger.info("Uploading package $type meta $package to GCS");
    var path = p.join(config.gcsMeta, type, timeString, package.name, package.version.toString());
    await storage.insertKey(path);
  }
}
