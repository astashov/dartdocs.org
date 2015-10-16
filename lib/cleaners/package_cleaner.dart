library dartdoc_generator.cleaners.package_cleaner;

import 'dart:async';
import 'dart:io';

import 'package:dartdoc_generator/config.dart';
import 'package:dartdoc_generator/package.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:path/path.dart' as p;
import 'package:dartdoc_generator/version.dart';

var _logger = new Logger("package_cleaner");

class PackageCleaner {
  final Config config;
  PackageCleaner(this.config);

  Future<Null> delete(Iterable packages) async {
    var futures = packages.map((Package package) async {
      _logger.info("Deleting output directory for the package $package");
      await new Directory(package.outputDir(config)).delete(recursive: true);
      if (!_usedByDartDocGeneratorPackages.contains(package)) {
        _logger.info("Deleting pubcache directory for the package $package");
        await new Directory(package.pubCacheDir(config)).delete(recursive: true);
      }
    });
    await Future.wait(futures);
  }

  Set<Package> _usedByDartDocGeneratorPackagesMemoizer;
  Set<Package> get _usedByDartDocGeneratorPackages {
    if (_usedByDartDocGeneratorPackagesMemoizer == null) {
      Map<String, Map<String, String>> lockfile = yaml.loadYaml(new File(p.join(config.dirroot, "pubspec.lock")).readAsStringSync())["packages"];
      var packages = new Set();
      lockfile.forEach((String key, Map<String, String> values) {
        packages.add(new Package(key, new Version(values["version"])));
      });
      _usedByDartDocGeneratorPackagesMemoizer = packages;
    }
    return _usedByDartDocGeneratorPackagesMemoizer;
  }
}
