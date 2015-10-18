library dartdoc_generator.bin.index_generator;

import 'dart:io';
import 'dart:math';

import 'package:dartdoc_generator/config.dart';
import 'package:dartdoc_generator/generators/index_generator.dart';
import 'package:dartdoc_generator/logging.dart' as logging;
import 'package:dartdoc_generator/storage.dart';
import 'package:dartdoc_generator/datastore_retriever.dart';
import 'package:dartdoc_generator/uploaders/index_uploader.dart';
import 'package:logging/logging.dart';
import 'package:dartdoc_generator/datastore.dart';
import 'package:args/args.dart';
import 'dart:async';

main(List<String> args) async {
  try {
    var parser = new ArgParser();
    parser.addOption('dirroot');
    parser.addFlag('help', negatable: false);
    var argsResults = parser.parse(args);
    if (argsResults["help"]) {
      print(parser.usage);
      exit(0);
    }
    logging.initialize();
    var config = new Config.buildFromFiles(argsResults["dirroot"], "config.yaml", "credentials.yaml");
    var datastore = new Datastore(config);
    var storage = new Storage(config);
    var datastoreRetriever = new DatastoreRetriever(datastore);
    var indexGenerator = new IndexGenerator(config);
    var indexUploader = new IndexUploader(config, storage);
    await datastoreRetriever.update();
    var previousSuccessfulPackagesLength = 0;
    var previousErroredPackagesLength = 0;
    await indexGenerator.generate404();
    while (true) {
      _logger.info("Retrieving the list of generated packages from GCS");
      await datastoreRetriever.update();

      var successPackages = datastoreRetriever.successPackages;
      _logger.info("Last number of successfully generated packages is $previousSuccessfulPackagesLength");
      _logger.info("Current number of successfully generated packages is ${successPackages.length}");
      if (previousSuccessfulPackagesLength != successPackages.length) {
        _logger.info("There are new packages available, regenerating the index");
        await indexGenerator.generateHome(successPackages);
        await indexGenerator.generateJsonIndex(successPackages);
        _logger.info("Done");
      }

      var errorPackages = datastoreRetriever.errorPackages;
      _logger.info("Last number of erroneously generated packages is $previousErroredPackagesLength");
      _logger.info("Current number of erroneously generated packages is ${errorPackages.length}");
      if (previousErroredPackagesLength != errorPackages.length) {
        _logger.info("There are new failed packages available, regenerating the errors index");
        await indexGenerator.generateErrors(errorPackages);
        _logger.info("Done");
      }

      if (previousSuccessfulPackagesLength != successPackages.length ||
          previousErroredPackagesLength != errorPackages.length) {
        _logger.info("There are new packages available, regenerating the history");
        var sortedPackages = datastoreRetriever.allPackages.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        await indexGenerator.generateHistory(
            sortedPackages.getRange(0, min(sortedPackages.length, 100)).toList(), successPackages);
        _logger.info("Done");

        await indexUploader.uploadIndexFiles();
      }

      previousSuccessfulPackagesLength = successPackages.length;
      previousErroredPackagesLength = errorPackages.length;
      var duration = new Duration(minutes: 1);
      _logger.info("Waiting for ${duration.inSeconds}s...");
      await new Future.delayed(duration);
    }
  } catch (error, stackTrace) {
    print(error);
    print(stackTrace);
    exit(1);
  }
}

Logger _logger = new Logger("dartdoc_generator");
