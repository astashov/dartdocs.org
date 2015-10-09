library dartdoc_runner.bin.purge_cdn_cache;

import 'dart:io';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/logging.dart' as logging;
import 'package:logging/logging.dart';
import 'package:dartdoc_runner/cleaners/cdn_cleaner.dart';

main(List<String> args) async {
  logging.initialize();
  var config = new Config.buildFromFiles("config.yaml", "credentials.yaml");
  var cdnCleaner = new CdnCleaner(config);
  _logger.info("Clearing all CDN cache");
  await cdnCleaner.purgeAll();
  _logger.info("Done");
  exit(0);
}

Logger _logger = new Logger("purge_cdn_cache");
