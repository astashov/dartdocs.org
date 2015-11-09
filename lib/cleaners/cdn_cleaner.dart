library dartdocorg.cleaners.cdn_cleaner;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/generators/index_generator.dart';
import 'package:dartdocorg/package.dart';
import 'package:dartdocorg/utils.dart';
import 'package:dartdocorg/utils/retry.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _logger = new Logger("cdn_cleaner");

class CdnCleaner {
  final Config config;
  final Client client;

  CdnCleaner(this.config) : this.client = new Client();

  Future<Null> purgeIndex() async {
    _logger.info("Cleaning the CDN cache for the index pages");
    var relativePaths = []
      ..add("")
      ..addAll(allIndexUrls);
    return _purgeFiles(relativePaths);
  }

  Future<Null> purgePackages(Iterable<Package> packages) {
    _logger.info("Cleaning the CDN cache for the packages");
    var relativePaths = packages.map((package) {
      return new Directory(package.outputDir(config))
          .listSync(recursive: true)
          .where((f) => f is File)
          .map((file) {
        return p.relative(file.path, from: package.outputDir(config));
      });
    }).expand((i) => i);
    return _purgeFiles(relativePaths);
  }

  Future<Null> purgeAll() async {
    return _purgeCache({"purge_everything": true});
  }

  Future<Null> _purgeFiles(Iterable<String> relativePaths) async {
    // https://api.cloudflare.com/#zone-purge-individual-files-by-url-and-cache-tags
    var groupedRelativePaths =
        inGroupsOf(relativePaths, 30); // 30 is max, API limit
    await Future.wait(groupedRelativePaths.map((pathsAndNulls) async {
      var paths = pathsAndNulls.where((path) => path != null);
      var files = paths
          .map((f) => f == "" ? config.hostedUrl : "${config.hostedUrl}/$f")
          .toList();
      return _purgeCache({"files": files});
    }));
  }

  Future<Null> _purgeCache(Map<String, Object> payload) async {
    var request = new Request(
        "DELETE",
        Uri.parse(
            "https://api.cloudflare.com/client/v4/zones/${config.cloudflareZone}/purge_cache"));
    request.body = JSON.encode(payload);
    request.headers["X-Auth-Email"] = config.cloudflareEmail;
    request.headers["X-Auth-Key"] = config.cloudflareApiKey;
    request.headers["Content-Type"] = "application/json";
    try {
      StreamedResponse response = await retry(() => client.send(request));
      var string = await response.stream.bytesToString();
      _logger.info("Cloudfront response: $string");
    } catch (_, __) {
      _logger.warning("Couldn't clean CDN cache, but let's continue");
    }
  }
}
