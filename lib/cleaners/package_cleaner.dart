library dartdoc_generator.cleaners.package_cleaner;

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

  void deleteSync() {
    _logger.info("Cleaning old output and pub cache");
    if (new Directory(config.outputDir).existsSync()) {
      new Directory(config.outputDir).deleteSync(recursive: true);
    }
    var usedDirs = _usedByDartDocGeneratorPackages.map((p) => p.fullName).toSet();
    new Directory(p.join(config.pubCacheDir, "hosted", "pub.dartlang.org")).listSync(recursive: false).where((e) => e is Directory).forEach((dir) {
      if (!usedDirs.contains(p.basename(dir.path))) {
        dir.deleteSync(recursive: true);
      }
    });
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
