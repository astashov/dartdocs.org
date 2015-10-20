library dartdocorg.bin.bump_docs_version;

import 'dart:io';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/logging.dart' as logging;
import 'package:logging/logging.dart';
import 'package:dartdocorg/datastore.dart';
import 'package:intl/intl.dart';
import 'package:args/args.dart';

main(List<String> args) async {
  logging.initialize();
  var parser = new ArgParser();
  parser.addOption('dirroot', help: "Specify the application directory, if not current");
  parser.addFlag('help', negatable: false, help: "Show help");
  var argsResults = parser.parse(args);
  if (argsResults["help"]) {
    print("Bumps the docsVersion global variable, which will cause regenerating all the packages from pub.\n");
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

Logger _logger = new Logger("dartdocorg");
