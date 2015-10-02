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

main(List<String> args) async {
  logging.initialize();
  var config = new Config.buildFromFiles("config.yaml", "credentials.yaml");
  var pubRetriever = new PubRetriever();
  var storage = new Storage(config);
  var storageRetriever = new StorageRetriever(config, storage);
  var generator = new PackageGenerator(config);
  var uploader = new PackageUploader(config, storage);
  while (true) {
    Set<Package> allPackages = (await pubRetriever.update());
    await storageRetriever.update();
    var shard = await getShard(config);
    allPackages.removeAll(storageRetriever.allPackages);
    var packages = shard.part(allPackages.toList()).getRange(0, 1);
    if (packages.isNotEmpty) {
      var erroredPackages = await generator.generate(packages);
      var successfulPackages = packages.toSet()..removeAll(erroredPackages);
      await uploader.uploadSuccessfulPackages(successfulPackages);
      await uploader.markSuccessfulPackages(successfulPackages);
      await uploader.uploadErroredPackages(erroredPackages);
      await uploader.markErroredPackages(erroredPackages);
    } else {
      sleep(new Duration(minutes: 3));
    }
  }
}

Logger _logger = new Logger("dartdoc_generator");
