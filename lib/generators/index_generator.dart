library dartdoc_runner.index_generator;

import 'dart:async';
import 'dart:io';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/package.dart';
import 'package:dartdoc_runner/utils.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

var _logger = new Logger("index_generator");

class IndexGenerator {
  final Config config;
  IndexGenerator(this.config);

  Future<Null> generateErrors(Iterable<Package> packages) async {
    Map<String, Iterable<Package>> groupedPackages = groupBy(packages, (package) => package.name);
    var html = new StringBuffer();
    html.writeln(_generateHeader(MenuItem.failed));
    html.writeln("<dl>");
    groupedPackages.forEach((name, packageVersions) {
      html.writeln("<dt>${packageVersions.first.name}</dt><dd>");
      for (var package in packageVersions) {
        html.writeln(
            "<a href='/${config.gcsPrefix}/${package.name}/${package.version}/log.txt'>${package.version}</a> ");
      }
      html.writeln("</dd>");
    });
    html.writeln("</dl>");
    html.writeln(_generateFooter());
    var file = new File(path.join(config.outputDir, MenuItem.failed.url));
    await file.create(recursive: true);
    await file.writeAsString(html.toString());
  }

  Future<Null> generateHistory(List<Package> sortedPackages, Set<Package> successfulPackages) async {
    var html = new StringBuffer();
    html.writeln(_generateHeader(MenuItem.history));
    html.writeln("<table class='table table-hover'>");
    html.writeln("<thead><tr><th>Package</th><th>Time</th><th>Status</th><th>Log</th></thead>");
    html.writeln("<tbody>");
    sortedPackages.forEach((package) {
      var isSuccessful = successfulPackages.contains(package);
      html.writeln("<tr${isSuccessful ? '' : ' class="danger"'}>");
      html.writeln("<td>${package.fullName}</td>");
      html.writeln("<td>${package.createdAt}</td>");
      html.writeln("<td>${isSuccessful ? 'Success' : '<strong>FAILURE</strong>'}</td>");
      html.writeln("<td><a href='/${package.logUrl(config)}'>build log</a></td>");
      html.writeln("</tr>");
    });
    html.writeln("</tbody></table>");
    html.writeln(_generateFooter());
    var file = new File(path.join(config.outputDir, MenuItem.history.url));
    await file.create(recursive: true);
    await file.writeAsString(html.toString());
  }

  Future<Null> generateHome(Iterable<Package> packages) async {
    Map<String, Iterable<Package>> groupedPackages = groupBy(packages, (package) => package.name);
    var html = new StringBuffer();
    html.writeln(_generateHeader(MenuItem.home));
    html.writeln("<dl>");
    groupedPackages.forEach((name, packageVersions) {
      html.writeln("<dt>${packageVersions.first.name}</dt><dd>");
      for (var package in packageVersions) {
        html.writeln(
            "<a href='/${config.gcsPrefix}/${package.name}/${package.version}/index.html'>${package.version}</a> ");
      }
      html.writeln("</dd>");
    });
    html.writeln("</dl>");
    html.writeln(_generateFooter());
    var file = new File(path.join(config.outputDir, MenuItem.home.url));
    await file.create(recursive: true);
    await file.writeAsString(html.toString());
  }

  String _generateFooter() {
    return "</div></body></html>";
  }

  String _generateHeader(MenuItem activeItem) {
    return """<html>
  <head>
    <title>Dartdocs - Documentation for Dart packages</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
  </head>
  <body>
    <nav class="navbar navbar-default" role="navigation">
      <div class="container-fluid">
        <ul class="nav navbar-nav">
          ${MenuItem.all.map((mi) => mi.toHtml(mi == activeItem)).join("\n")}
        </ul>
      </div>
    </nav>
    <div class="container">""";
  }
}

class MenuItem {
  static const MenuItem home = const MenuItem("index.html", "Home");
  static const MenuItem history = const MenuItem("history/index.html", "Build history");
  static const MenuItem failed = const MenuItem("failed/index.html", "Build failures");
  static const Iterable<MenuItem> all = const [home, history, failed];

  final String url;
  final String title;
  const MenuItem(this.url, this.title);

  String toHtml(bool isActive) {
    return "<li${isActive ? " class='active'" : ""}><a href='/$url'>$title</a></li>";
  }
}
