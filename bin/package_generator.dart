library dartdoc_runner.bin.package_generator;

import 'dart:io';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/generators/package_generator.dart';
import 'package:dartdoc_runner/logging.dart' as logging;
import 'package:dartdoc_runner/package.dart';
import 'package:dartdoc_runner/pub_retriever.dart';
import 'package:dartdoc_runner/shard.dart';
import 'package:dartdoc_runner/storage.dart';
import 'package:dartdoc_runner/storage_retriever.dart';
import 'package:dartdoc_runner/uploaders/package_uploader.dart';
import 'package:logging/logging.dart';
import 'package:dartdoc_runner/cleaners/package_cleaner.dart';
import 'package:dartdoc_runner/utils.dart';

main(List<String> args) async {
  logging.initialize();
  var config = new Config.buildFromFiles("config.yaml", "credentials.yaml");
  var pubRetriever = new PubRetriever();
  var storage = new Storage(config);
  var storageRetriever = new StorageRetriever(config, storage);
  var generator = new PackageGenerator(config);
  var cleaner = new PackageCleaner(config);
  var uploader = new PackageUploader(config, storage);
  while (true) {
    Set<Package> allPackages = (await pubRetriever.update());
    await generator.activateDartdoc();
    await storageRetriever.update();
    var shard = await getShard(config);
    allPackages.removeAll(storageRetriever.allPackages);
    var packageGroups = inGroupsOf(shard.part(allPackages.toList()), 20);
    if (packageGroups.isNotEmpty) {
      for (var packages in packageGroups) {
        var erroredPackages = await generator.generate(packages);
        var successfulPackages = packages.toSet()..removeAll(erroredPackages);
        await uploader.uploadSuccessfulPackages(successfulPackages);
        await uploader.markSuccessfulPackages(successfulPackages);
        await uploader.uploadErroredPackages(erroredPackages);
        await uploader.markErroredPackages(erroredPackages);
        await cleaner.delete(packages);
      }
    } else {
      _logger.info("Sleeping for 3 minutes...");
      sleep(new Duration(minutes: 3));
    }
  }
}

Logger _logger = new Logger("dartdoc_generator");
