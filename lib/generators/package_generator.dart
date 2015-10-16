library dartdoc_generator.package_generator;

import 'dart:async';
import 'dart:io';

import 'package:dartdoc_generator/config.dart';
import 'package:dartdoc_generator/logging.dart' as logging;
import 'package:dartdoc_generator/package.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:dartdoc_generator/utils.dart';

var _logger = new Logger("package_generator");

class PackageGenerator {
  final Config config;
  PackageGenerator(this.config);

  Future<Null> activateDartdoc() async {
    await _runCommand([], "pub", ["global", "activate", "dartdoc"]);
  }

  Future<Set<Package>> generate(Iterable allPackages) async {
    var groupedPackages = inGroupsOf(allPackages, 4);
    var erroredPackages = new Set();
    for (var packages in groupedPackages) {
      var futures = packages.map((Package package) async {
        List<LogRecord> logs = [];
        try {
          await _runCommand(logs, "pub", ["--version"]);
          await _install(logs, package);
          await _runCommand(logs, "dartdoc", [
            "--input=${package.pubCacheDir(config)}",
            "--output=${package.outputDir(config)}",
            "--hosted-url=${config.hostedUrl}",
            "--header=${path.join(config.dirroot, "resources", "redirector.html")}",
            "--footer=${path.join(config.dirroot, "resources", "google_analytics.html")}",
            "--dart-sdk=${config.dartSdkPath}"
          ]);
          await _archivePackage(logs, package);
        } on RunCommandError catch (e, s) {
          _addLog(logs, Level.WARNING, "Got RunCommandError exception,\nstdout: ${e.stdout},\nstderr: ${e.stderr}");
          erroredPackages.add(package);
        } catch (e, s) {
          _addLog(logs, Level.WARNING, "Got $e exception,\nstacktrace: $s");
          erroredPackages.add(package);
        } finally {
          await _saveLogsToFile(logs, package);
        }
      });
      await Future.wait(futures);
    }
    return erroredPackages;
  }

  void _addLog(List<LogRecord> logs, Level level, String message) {
    logs.add(new LogRecord(Level.INFO, message, "dartdoc"));
    _logger.info(message);
  }

  Future<Null> _install(List<LogRecord> logs, Package package) async {
    RunCommandError potentialFailure;
    try {
      var pubGlobalFuture = _runCommand(logs, "pub", ["cache", "add", package.name, "-v", package.version.toString()]);

      await pubGlobalFuture.timeout(new Duration(seconds: 30), onTimeout: () {
        throw new RunCommandError("Install error - timeout", "");
      });
      throw new RunCommandError("Blah", "Foo");
    } on RunCommandError catch (e, _) {
      potentialFailure = e;
      _addLog(logs, Level.WARNING, "While installing, got RunCommandError exception,\nstdout: ${e.stdout},\nstderr: ${e.stderr}");
    }
    var workingDirectory = package.pubCacheDir(config);

    if (new Directory(workingDirectory).existsSync()) {
      try {
        await _runCommand(logs, "pub", ["get"], workingDirectory: workingDirectory);
        throw new RunCommandError("Blah2", "Foo2");
      } on RunCommandError catch (e, _) {
        _addLog(logs, Level.WARNING, "While doing pub get, got RunCommandError exception,\nstdout: ${e.stdout},\nstderr: ${e.stderr}");
      }
    } else if (potentialFailure != null) {
      throw potentialFailure;
    }
  }

  Future _runCommand(List<LogRecord> logs, String command, Iterable<String> arguments,
      {String workingDirectory}) async {
    _addLog(logs, Level.INFO, "Running '$command ${arguments.join(" ")}'");
    var result = await Process.run(command, arguments, workingDirectory: workingDirectory);

    if (result.stdout != "") {
      _addLog(logs, Level.INFO, "Stdout: ${result.stdout}");
    }
    if (result.stderr != "") {
      _addLog(logs, Level.INFO, "Stderr: ${result.stderr}");
    }

    if (result.exitCode != 0) {
      throw new RunCommandError(result.stdout, result.stderr);
    }
  }

  Future<Null> _saveLogsToFile(List<LogRecord> logs, Package package) async {
    var directory = new Directory(package.outputDir(config));
    if (!await (directory.exists())) {
      await directory.create(recursive: true);
    }
    var file = new File(path.join(package.outputDir(config), "log.txt"));
    var contents = logs.map((logRecord) => logging.logFormatter(logRecord)).join("\n");
    await file.writeAsString(contents);
  }

  Future<Null> _archivePackage(List<LogRecord> logs, Package package) async {
    var workingDir = path.join(config.outputDir, config.gcsPrefix);
    var archivePath = path.join(config.outputDir, config.gcsPrefix, "${package.fullName}.tar.gz");
    await _runCommand(logs, "tar", [
        "-C", workingDir, "-czf", archivePath, path.join(package.name, package.version.toString())]);
    await new File(archivePath).rename(path.join(package.outputDir(config), "package.tar.gz"));
  }
}

class RunCommandError implements Exception {
  final String stdout;
  final String stderr;
  RunCommandError(this.stdout, this.stderr);
}
