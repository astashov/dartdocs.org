library dartdoc_runner.uploader;

import 'package:dartdoc_runner/config.dart';
import 'dart:async';

import 'package:dartdoc_runner/package.dart';
import 'package:dartdoc_runner/utils.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:dartdoc_runner/storage.dart';

Logger _logger = new Logger("uploader");

class Uploader {
  final Config config;
  final Storage storage;
  Uploader(this.config, this.storage);

  Future<Null> uploadSuccessfulPackages(Iterable<Package> packages) async {
    for (var package in packages) {
      _logger.info("Uploading package files $package to GCS");
      var entities = await new Directory(package.outputDir(config)).list(recursive: true).toList();
      var groups = inGroupsOf(entities.where((e) => e is File), 10);
      for (Iterable group in groups) {
        await Future.wait(group.map((entity) async {
          var relative = entity.path.replaceFirst("${package.outputDir(config)}/", "");
          var path = p.join(config.gcsPrefix, package.name, package.version.toString(), relative);
          return storage.insertFile(path, entity);
        }));
      }
    }
  }

  Future<Null> uploadErroredPackages(Iterable<Package> packages) async {
    await Future.wait(packages.map((package) async {
      _logger.info("Uploading error log file for $package to GCS");
      var logFile = new File(p.join(package.outputDir(config), "log.txt"));
      var path = p.join(config.gcsPrefix, package.name, package.version.toString(), "log.txt");
      return storage.insertFile(path, logFile);
    }));
  }

  Future<Null> markSuccessfulPackages(Iterable<Package> packages) async {
    var timeString = _getTimeString();
    await Future.wait(packages.map((package) async {
      return _uploadMeta("success", timeString, package);
    }));
  }

  Future<Null> markErroredPackages(Iterable<Package> packages) async {
    var timeString = _getTimeString();
    await Future.wait(packages.map((package) async {
      return _uploadMeta("error", timeString, package);
    }));
  }

  String _getTimeString() {
    return new DateFormat("yyyyMMddHHmmss").format(new DateTime.now());
  }

  Future<Null> _uploadMeta(String type, String timeString, Package package) async {
    _logger.info("Uploading package $type meta $package to GCS");
    var path = p.join(config.gcsMeta, type, timeString, package.name, package.version.toString());
    await storage.insertKey(path);
  }

}