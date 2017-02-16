library dartdocorg.cleaners.package_cleaner;

import 'dart:io';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/package.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

final _logger = new Logger("package_cleaner");

class PackageCleaner {
  final Config config;
  PackageCleaner(this.config);

  /// Deletes whole [config.outputDir]/[config.gcsPrefix] and installed packages in .pub-cache, which are not used by this app.
  ///
  /// Be careful when using that on your local machine - it will wipe out all the installed packages in .pub-cache!!!
  /// I decided to use this approach instead of deleting the packages after we generate them, because this is more
  /// reliable - in case of crashing, and after monit runs the app again, we won't have the leftovers after the previous
  /// run while generating the packages' docs
  void deleteSync() {
    _logger.info("Cleaning old output and pub cache");
    if (new Directory(p.join(config.outputDir, config.gcsPrefix)).existsSync()) {
      new Directory(p.join(config.outputDir, config.gcsPrefix)).deleteSync(recursive: true);
    }
    var usedDirs =
        _usedByDartDocGeneratorPackages.map((p) => p.fullName).toSet();
    new Directory(p.join(config.pubCacheDir, "hosted", "pub.dartlang.org"))
        .listSync(recursive: false)
        .where((e) => e is Directory)
        .forEach((dir) {
      if (!usedDirs.contains(p.basename(dir.path)) && !dir.path.contains("crossdart")) {
        dir.deleteSync(recursive: true);
      }
    });
  }

  Set<Package> _usedByDartDocGeneratorPackagesMemoizer;
  Set<Package> get _usedByDartDocGeneratorPackages {
    if (_usedByDartDocGeneratorPackagesMemoizer == null) {
      var packages = new Set();
      var result = Process.runSync("pub", ["global", "list"]);
      var dirs = ["/dartdoc"];
      var stdout = result.stdout.toString();
      var crossdartLine = stdout.split("\n").firstWhere((String l) => l.startsWith("crossdart"), orElse: () => null);
      if (crossdartLine != null) {
        var crossdartVersion = crossdartLine.split(" ")[1];
        packages.add(new Package.build("crossdart", crossdartVersion));
        dirs.add(p.join(config.pubCacheDir, "hosted", "pub.dartlang.org", "crossdart-${crossdartVersion}"));
      }
      var dartdocLine = stdout.split("\n").firstWhere((String l) => l.startsWith("dartdoc"), orElse: () => null);
      if (dartdocLine != null) {
        var dartdocVersion = dartdocLine.split(" ")[1];
        packages.add(new Package.build("dartdoc", dartdocVersion));
        dirs.add(p.join(config.pubCacheDir, "hosted", "pub.dartlang.org", "dartdoc-${dartdocVersion}"));
      }
      dirs.add(config.dirroot);
      for (var dir in dirs) {
        if (new Directory(dir).existsSync()) {
          var pubspecLock = new File(p.join(dir, "pubspec.lock"));
          if (!pubspecLock.existsSync()) {
            Process.runSync("pub", ["get"], workingDirectory: dir);
          }
          Map<String, Map<String, String>> lockfile = yaml.loadYaml(pubspecLock.readAsStringSync())["packages"];
          lockfile.forEach((String key, Map<String, String> values) {
            packages.add(new Package.build(key, values["version"]));
          });
        }
      }
      _usedByDartDocGeneratorPackagesMemoizer = packages;
    }
    return _usedByDartDocGeneratorPackagesMemoizer;
  }
}
