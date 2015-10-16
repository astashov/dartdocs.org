library dartdoc_generator.bin.bump_docs_version;

import 'dart:io';

import 'package:dartdoc_generator/config.dart';
import 'package:dartdoc_generator/logging.dart' as logging;
import 'package:logging/logging.dart';
import 'package:dartdoc_generator/datastore.dart';
import 'package:intl/intl.dart';
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
  var datastore = new Datastore(config);
  var docsVersion = int.parse(new DateFormat("yyyyMMddHHmmss").format(new DateTime.now().toUtc()));
  _logger.info("Setting new docsVersion: $docsVersion");
  await datastore.bumpDocsVersion(docsVersion);
  _logger.info("Done");
  exit(0);
}

Logger _logger = new Logger("dartdoc_generator");
