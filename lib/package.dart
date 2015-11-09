library dartdocorg.package;

import 'dart:convert';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/utils.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

class Package implements Comparable<Package> {
  static const String logFileName = "log.txt";
  final String name;
  final Version version;
  final DateTime updatedAt;

  Package(this.name, this.version, [this.updatedAt]);

  factory Package.fromJson(String json) {
    final map = JSON.decode(json);
    return new Package.build(map["name"], map["version"]);
  }

  factory Package.build(String name, String version, [DateTime updatedAt]) {
    return new Package(name, new Version.parse(version), updatedAt);
  }

  String canonicalUrl(Config config) {
    return path.join(config.hostedUrl, config.gcsPrefix, name, "latest");
  }

  String get fullName => "$name-$version";

  int get hashCode => hash([name, version]);

  bool operator ==(other) =>
      other is Package && name == other.name && version == other.version;

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
    return path.join(
        config.pubCacheDir, "hosted", "pub.dartlang.org", "$name-$version");
  }

  String toJson() {
    return JSON.encode(toMap());
  }

  Map<String, String> toMap() {
    var result = {"name": name, "version": version.toString()};
    if (updatedAt != null) {
      result["updatedAt"] = updatedAt;
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
