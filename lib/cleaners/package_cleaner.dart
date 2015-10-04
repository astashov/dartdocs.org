library dartdoc_runner.cleaners.package_cleaner;

import 'dart:async';
import 'dart:io';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/logging.dart' as logging;
import 'package:dartdoc_runner/package.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

var _logger = new Logger("package_cleaner");

class PackageCleaner {
  final Config config;
  PackageCleaner(this.config);

  Future<Null> delete(Iterable packages) async {
    var futures = packages.map((Package package) async {
      _logger.info("Deleting pubcache and output directory for the package $package");
      await new Directory(package.pubCacheDir(config)).delete(recursive: true);
      await new Directory(package.outputDir(config)).delete(recursive: true);
    });
    await Future.wait(futures);
  }
}
