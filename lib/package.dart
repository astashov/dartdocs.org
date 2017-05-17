library dartdocorg.package;

import 'dart:convert';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/utils.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'dart:io';
import "package:yaml/yaml.dart" as yaml;

const flutterPackageNames = const [
  "flutter",
  "flutter_driver",
  "flutter_test",
  "flutter_tools"
];

class Package implements Comparable<Package> {
  static const String logFileName = "log.txt";
  final String name;
  final Version version;
  final DateTime updatedAt;
  final String hashVersion;

  Package(this.name, Version version, [this.updatedAt, String hashVersion]) :
      this.version = version,
      this.hashVersion = hashVersion ?? version.toString();

  factory Package.fromJson(String json) {
    final map = JSON.decode(json);
    return new Package.build(map["name"], map["version"]);
  }

  factory Package.sdk(Config config) {
    var version = new File(path.join(config.dartSdkPath, "version")).readAsStringSync().trim();
    return new Package.build("sdk", version);
  }

  factory Package.flutter(String packageName, Config config) {
    var pubspec = new File(path.join(config.flutterDir, "packages", packageName, "pubspec.yaml"));
    String version = yaml.loadYaml(pubspec.readAsStringSync().trim())["version"];
    var dir = path.join(config.flutterDir, "packages", packageName);
    String hashVersion = Process.runSync("git", ["-C", dir, "rev-parse", "HEAD"]).stdout.toString().trim();
    return new Package.build(packageName, version ?? "0.0.1", null, hashVersion);
  }

  factory Package.build(String name, String version, [DateTime updatedAt, String hashVersion]) {
    return new Package(name, new Version.parse(version), updatedAt, hashVersion);
  }

  String canonicalUrl(Config config) {
    return path.join(config.hostedUrl, config.gcsPrefix, name, "latest");
  }

  bool get isSdk => name == "sdk";

  bool get isFlutter => flutterPackageNames.contains(name);

  String get fullName => "$name-$version";

  int get hashCode => hash([name, version, hashVersion]);

  bool operator ==(other) =>
      other is Package && name == other.name && version == other.version && hashVersion == other.hashVersion;

  int compareTo(Package other) {
    if (name == other.name) {
      return version.compareTo(other.version);
    } else {
      return name.compareTo(other.name);
    }
  }

  String logFile(Config config) {
    return path.join(outputDir(config), logFileName);
  }

  String logUrl(Config config) {
    return path.join(url(config), logFileName);
  }

  String outputDir(Config config) {
    return path.join(config.outputDir, url(config));
  }

  String pubCacheDir(Config config) {
    if (isSdk) {
      return config.dartSdkPath;
    } else if (isFlutter) {
      return path.join(config.flutterDir, "packages", name);
    } else {
      return path.join(
          config.pubCacheDir, "hosted", "pub.dartlang.org", "$name-$version");
    }
  }

  String toJson() {
    return JSON.encode(toMap());
  }

  Map<String, String> toMap() {
    var result = {"name": name, "version": version.toString()};
    if (updatedAt != null) {
      result["updatedAt"] = updatedAt;
    }
    if (hashVersion != null) {
      result["hashVersion"] = hashVersion;
    }
    return result;
  }

  String toString() {
    return "<PackageInfo ${toMap()}>";
  }

  Package update({String name, Version version, DateTime updatedAt}) {
    return new Package(name ?? this.name, version ?? this.version,
        updatedAt ?? this.updatedAt);
  }

  String url(Config config) {
    return path.join(config.gcsPrefix, name, version.toString());
  }
}
