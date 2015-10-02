library dartdoc_runner.package;

import 'dart:convert';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/utils.dart';
import 'package:dartdoc_runner/version.dart';
import 'package:path/path.dart' as path;

class Package implements Comparable<Package> {
  static const String logFileName = "log.txt";
  final String name;
  final Version version;
  final DateTime createdAt;

  Package(this.name, this.version, [this.createdAt]);

  factory Package.fromJson(String json) {
    final map = JSON.decode(json);
    return new Package(map["name"], new Version(map["version"]));
  }

  String get fullName => "$name-$version";

  int get hashCode => hash([name, version]);

  bool operator ==(other) => other is Package && name == other.name && version == other.version;

  int compareTo(Package other) {
    return fullName.compareTo(other.fullName);
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
    return path.join(config.pubCacheDir, "hosted", "pub.dartlang.org", "$name-$version");
  }

  String toJson() {
    return JSON.encode(toMap());
  }

  Map<String, String> toMap() {
    return {"name": name, "version": version.toString()};
  }

  String toString() {
    return "<PackageInfo ${toMap()}>";
  }

  Package update({String name, Version version, DateTime createdAt}) {
    return new Package(name ?? this.name, version ?? this.version, createdAt ?? this.createdAt);
  }

  String url(Config config) {
    return path.join(config.gcsPrefix, name, version.toString());
  }
}
