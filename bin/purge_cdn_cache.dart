library dartdoc_generator.bin.purge_cdn_cache;

import 'dart:io';

import 'package:dartdoc_generator/config.dart';
import 'package:dartdoc_generator/logging.dart' as logging;
import 'package:logging/logging.dart';
import 'package:dartdoc_generator/cleaners/cdn_cleaner.dart';
import 'package:args/args.dart';

main(List<String> args) async {
  logging.initialize();
  var parser = new ArgParser();
  parser.addOption('dirroot');
  parser.addFlag('help', negatable: false);
  var argsResults = parser.parse(args);
  if (argsResults["help"]) {
    print(parser.usage);
    exit(0);
  }
  var config = new Config.buildFromFiles(argsResults["dirroot"], "config.yaml", "credentials.yaml");
  var cdnCleaner = new CdnCleaner(config);
  _logger.info("Clearing all CDN cache");
  await cdnCleaner.purgeAll();
  _logger.info("Done");
  exit(0);
}

Logger _logger = new Logger("purge_cdn_cache");
