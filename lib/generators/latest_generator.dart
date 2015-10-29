library dartdocorg.generators.latest_generator;

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/package.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

var _logger = new Logger("latest_generator");

class LatestGenerator {
  final Config config;

  LatestGenerator(this.config);

  Map<Package, Map<String, String>> generate(Iterable<Package> packages) {
    return packages.fold({}, (Map<Package, String> pkgs, Package package) {
      var files = new Directory(package.outputDir(config)).listSync(recursive: true).where((f) => f is File && f.path.endsWith(".html"));
      pkgs[package] = files.fold({}, (fls, file) {
        var relativePath = file.path.replaceAll(package.outputDir(config) + "/", "");
        var url = path.join(config.hostedUrl, config.gcsPrefix, package.name, package.version.toString(), relativePath);
        fls[relativePath] = """<html>
          <head>
            <title>www.dartdocs.org</title>
            <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
            <meta http-equiv="Pragma" content="no-cache" />
            <meta http-equiv="Expires" content="0" />
            <script>
              var meta = document.createElement("meta");
              var hash = document.location.hash;
              var latestUrl = '$url';
              var refreshTime = '0';
              var content = refreshTime + "; url='" + latestUrl + hash +"'";
              meta.setAttribute("http-equiv", "refresh");
              meta.setAttribute("content", content);
              document.head.appendChild(meta);
            </script>
            </head>
          <body></body>
        </html>""";
        return fls;
      });
      return pkgs;
    });
  }
}
