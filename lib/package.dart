library dartdoc_runner.package;

import 'dart:convert';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/utils.dart';
import 'package:dartdoc_runner/version.dart';
import 'package:path/path.dart' as path;

class Package implements Comparable<Package> {
  final String name;
  final Version version;

  Package(this.name, this.version);

  factory Package.fromJson(String json) {
    final map = JSON.decode(json);
    return new Package(map["name"], new Version(map["version"]));
  }

  String get dirname => "$name-$version";

  int get hashCode => hash([name, version]);

  bool operator ==(other) =>
      other is Package && name == other.name && version == other.version;

  int compareTo(Package other) {
    return dirname.compareTo(other.dirname);
  }

  String outputDir(Config config) {
    return path.join(config.outputDir, dirname);
  }

  String pubCacheDir(Config config) {
    return path.join(config.pubCacheDir, "hosted", "pub.dartlang.org", dirname);
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

  Package update({String name, Version version}) {
    return new Package(name ?? this.name, version ?? this.version);
  }
}
