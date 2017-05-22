library dartdocorg.generators.package_generator;

import 'dart:async';
import 'dart:io';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/logging.dart' as logging;
import 'package:dartdocorg/package.dart';
import 'package:dartdocorg/utils.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:tasks/utils.dart';

final Logger _logger = new Logger("package_generator");

class PackageGenerator {
  final Config config;
  PackageGenerator(this.config);

  Future<Null> activateDartdoc() async {
    await _runCommand([], "pub", ["global", "activate", "dartdoc"]);
  }

  Future<Null> activateCrossdart() async {
    await _runCommand([], "pub", ["global", "activate", "crossdart"]);
  }

  Future<Set<Package>> generateDartdocsOrg(Iterable<Package> allPackages) async {
    var erroredPackages = new Set<Package>();
    await pmap(allPackages, (Package package) async {
      List<LogRecord> logs = [];
      try {
        if (package.name == "angular2") {
          var file = new File(path.join(config.dirroot, "resources", "angular2.html"));
          var dir = package.outputDir(config);
          new Directory(dir).createSync(recursive: true);
          file.copySync(path.join(dir, "index.html"));
        } else {
          await _runCommand(logs, "pub", ["--version"]);
          if (!package.isSdk && !package.isFlutter) {
            await _install(logs, package);
          }
          var options = [
            "--input=${package.pubCacheDir(config)}",
            "--output=${package.pubCacheDir(config)}",
            "--hosted-url=${config.crossdartHostedUrl}",
            "--url-path-prefix=${config.crossdartGcsPrefix}",
            "--output-format=json",
            "--dart-sdk=${config.dartSdkPath}"
          ];
          try {
            await _runCommand(logs, "pub", ["global", "run", "crossdart"]..addAll(options));
          } on RunCommandError catch (e, _) {
            _addLog(logs, Level.SEVERE, e.stdout);
            _addLog(logs, Level.SEVERE, e.stderr);
          }

          options = [
            "--output=${package.outputDir(config)}",
            "--hosted-url=${config.hostedUrl}",
            "--rel-canonical-prefix=${package.canonicalUrl(config)}",
            "--exclude=dart.collection,dart.math,dart.core,dart.developer,dart.io,dart.ui,dart.isolate,dart.convert,dart.async,dart.typed_data",
            "--header=${path.join(config.dirroot, "resources", "redirector.html")}",
            "--footer=${path.join(config.dirroot, "resources", "google_analytics_dartdocs.html")}",
            "--add-crossdart"
          ];
          if (package.isSdk) {
            options.add("--sdk-docs");
            options.add("--input=${config.dartSdkPath}");
          } else {
            options.add("--input=${package.pubCacheDir(config)}");
          }
          await _runCommand(logs, "pub", ["global", "run", "dartdoc"]..addAll(options));
          await _archivePackage(logs, package);
        }
      } on RunCommandError catch (e, _) {
        _addLog(logs, Level.WARNING, "Got RunCommandError exception\n${e}");
        erroredPackages.add(package);
      } catch (e, s) {
        var chain = new Chain.forTrace(s).terse;
        _addLog(logs, Level.WARNING, "EXCEPTION:\n$e\nSTACK:\n$chain");
        erroredPackages.add(package);
      } finally {
        await _saveLogsToFile(logs, package);
      }
    }, concurrencyCount: config.numberOfConcurrentBuilds);
    return erroredPackages;
  }

  Future<Set<Package>> generateCrossdartInfo(Iterable<Package> allPackages) async {
    var erroredPackages = new Set();
    await pmap(allPackages, (Package package) async {
      List<LogRecord> logs = [];
      try {
        await _runCommand(logs, "pub", ["--version"]);
        if (!package.isSdk && !package.isFlutter) {
          await _install(logs, package);
        }
        var options = [
          "--input=${package.pubCacheDir(config)}",
          "--output=${package.outputDir(config)}",
          "--hosted-url=${config.hostedUrl}",
          "--url-path-prefix=${config.gcsPrefix}",
          "--output-format=html",
          "--dart-sdk=${config.dartSdkPath}"
        ];
        await _runCommand(logs, "pub", ["global", "run", "crossdart"]..addAll(options));
      } on RunCommandError catch (e, _) {
        _addLog(logs, Level.WARNING, "Got RunCommandError exception\n${e}");
        erroredPackages.add(package);
      } catch (e, s) {
        var chain = new Chain.forTrace(s).terse;
        _addLog(logs, Level.WARNING, "EXCEPTION:\n$e\nSTACK:\n$chain");
        erroredPackages.add(package);
      } finally {
        await _saveLogsToFile(logs, package);
      }
    }, concurrencyCount: config.numberOfConcurrentBuilds);
    return erroredPackages;
  }

  void _addLog(List<LogRecord> logs, Level level, String message) {
    logs.add(new LogRecord(level, message, "dartdoc"));
    _logger.log(level, message);
  }

  Future<Null> _install(List<LogRecord> logs, Package package) async {
    RunCommandError potentialFailure;
    try {
      await _runCommand(logs, "pub",
          ["cache", "add", package.name, "-v", package.version.toString()],
          duration: new Duration(seconds: config.installTimeout));
    } on RunCommandError catch (e) {
      potentialFailure = e;
      _addLog(logs, Level.WARNING,
          "While installing, got RunCommandError exception\n${e}");
    }
    var workingDirectory = package.pubCacheDir(config);

    if (new Directory(workingDirectory).existsSync()) {
      try {
        await _runCommand(logs, 'pub', ["get"],
            workingDirectory: workingDirectory,
            duration: const Duration(minutes: 5));
      } on RunCommandError catch (e) {
        _addLog(logs, Level.WARNING,
            "While doing pub get, got RunCommandError exception\n${e}");
      }
    } else if (potentialFailure != null) {
      throw potentialFailure;
    }
  }

  Future _runCommand(
      List<LogRecord> logs, String command, List<String> arguments,
      {String workingDirectory, Duration duration}) async {
    _addLog(logs, Level.INFO, "Running '$command ${arguments.join(" ")}'");

    ProcessResult result;
    if (duration == null) {
      result = await Process.run(command, arguments,
          workingDirectory: workingDirectory);
    } else {
      result = await runProcessWithTimeout(command, arguments, duration,
          workingDirectory: workingDirectory);
    }

    if (result.stdout != "") {
      _addLog(logs, Level.INFO, "Stdout: ${result.stdout}");
    }
    if (result.stderr != "") {
      _addLog(logs, Level.INFO, "Stderr: ${result.stderr}");
    }

    if (result.exitCode != 0) {
      throw new RunCommandError(
          command, arguments, result.exitCode, result.stdout, result.stderr);
    }
  }

  Future<Null> _saveLogsToFile(List<LogRecord> logs, Package package) async {
    var directory = new Directory(package.outputDir(config));
    if (!await (directory.exists())) {
      await directory.create(recursive: true);
    }
    var file = new File(path.join(package.outputDir(config), "log.txt"));
    var contents =
        logs.map((logRecord) => logging.logFormatter(logRecord)).join("\n");
    await file.writeAsString(contents);
  }

  Future<Null> _archivePackage(List<LogRecord> logs, Package package) async {
    var workingDir = path.join(config.outputDir, config.gcsPrefix);
    var archivePath = path.join(
        config.outputDir, config.gcsPrefix, "${package.fullName}.tar.gz");
    await _runCommand(logs, "tar", [
      "-C",
      workingDir,
      "-czf",
      archivePath,
      path.join(package.name, package.version.toString())
    ]);
    await new File(archivePath)
        .rename(path.join(package.outputDir(config), "package.tar.gz"));
  }
}

class RunCommandError extends ProcessException {
  final String stdout;
  final String stderr;

  RunCommandError(String executable, List<String> arguments, int errorCode,
      this.stdout, this.stderr)
      : super(executable, arguments, '', errorCode);

  String toString() {
    var buffer = new StringBuffer(super.toString());
    if (stdout != null && stdout.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('stdout:');
      buffer.write(stdout.trim());
    }

    if (stderr != null && stderr.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('stderr:');
      buffer.write(stderr.trim());
    }

    return buffer.toString();
  }
}
