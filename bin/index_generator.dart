library dartdoc_runner.bin.index_generator;

import 'dart:io';
import 'dart:math';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/generators/index_generator.dart';
import 'package:dartdoc_runner/logging.dart' as logging;
import 'package:dartdoc_runner/storage.dart';
import 'package:dartdoc_runner/storage_retriever.dart';
import 'package:dartdoc_runner/uploaders/index_uploader.dart';
import 'package:logging/logging.dart';

main(List<String> args) async {
  logging.initialize();
  var config = new Config.buildFromFiles("config.yaml", "credentials.yaml");
  var storage = new Storage(config);
  var storageRetriever = new StorageRetriever(config, storage);
  var indexGenerator = new IndexGenerator(config);
  var indexUploader = new IndexUploader(config, storage);
  await storageRetriever.update();
  var previousSuccessfulPackagesLength = 0;
  var previousErroredPackagesLength = 0;
  await indexGenerator.generate404();
  while (true) {
    _logger.info("Retrieving the list of generated packages from GCS");
    await storageRetriever.update();

    var successPackages = storageRetriever.successPackages;
    _logger.info("Last number of successfully generated packages is $previousSuccessfulPackagesLength");
    _logger.info("Current number of successfully generated packages is ${successPackages.length}");
    if (previousSuccessfulPackagesLength != successPackages.length) {
      _logger.info("There are new packages available, regenerating the index");
      await indexGenerator.generateHome(successPackages);
      _logger.info("Done");
    }

    var errorPackages = storageRetriever.errorPackages;
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
      var sortedPackages = storageRetriever.allPackages.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await indexGenerator.generateHistory(
          sortedPackages.getRange(0, min(sortedPackages.length, 100)).toList(), successPackages);
      _logger.info("Done");

      await indexUploader.uploadIndexFiles();
    }

    previousSuccessfulPackagesLength = errorPackages.length;
    var duration = new Duration(minutes: 1);
    _logger.info("Waiting for ${duration.inSeconds}s...");
    sleep(duration);
  }
}

Logger _logger = new Logger("dartdoc_generator");
