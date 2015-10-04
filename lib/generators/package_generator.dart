library dartdoc_runner.package_generator;

import 'dart:async';
import 'dart:io';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/logging.dart' as logging;
import 'package:dartdoc_runner/package.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:dartdoc_runner/utils.dart';

var _logger = new Logger("package_generator");

class PackageGenerator {
  final Config config;
  PackageGenerator(this.config);

  Future<Set<Package>> generate(Iterable allPackages) async {
    var groupedPackages = inGroupsOf(allPackages, 4);
    var erroredPackages = new Set();
    for (var packages in groupedPackages) {
      var futures = packages.map((Package package) async {
        List<LogRecord> logs = [];
        try {
          await _runCommand(logs, "pub", ["--version"]);
          await _install(logs, package);
          await _runCommand(logs, "pub", [
            "global",
            "run",
            "dartdoc",
            "--input=${package.pubCacheDir(config)}",
            "--output=${package.outputDir(config)}",
            "--hosted-url=${config.hostedUrl}",
            "--add-crossdart",
            "--dart-sdk=${config.dartSdkPath}"
          ]);
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
    var pubGlobalFuture = _runCommand(logs, "pub", ["cache", "add", package.name, "-v", package.version.toString()]);

    await pubGlobalFuture.timeout(new Duration(seconds: 30), onTimeout: () {
      throw new RunCommandError("Install error - timeout", "");
    });

    var workingDirectory = package.pubCacheDir(config);
    await _runCommand(logs, "pub", ["get"], workingDirectory: workingDirectory);
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
}

class RunCommandError implements Exception {
  final String stdout;
  final String stderr;
  RunCommandError(this.stdout, this.stderr);
}