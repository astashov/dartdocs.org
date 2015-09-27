library dartdoc_runner.bin.main;

import 'package:dartdoc_runner/pub_retriever.dart';
import 'package:dartdoc_runner/storage_retriever.dart';
import 'package:dartdoc_runner/shard.dart';
import 'package:dartdoc_runner/logging.dart' as logging;
import 'package:dartdoc_runner/package.dart';
import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/generator.dart';
import 'package:logging/logging.dart';
import 'dart:io';
import 'package:dartdoc_runner/uploader.dart';
import 'package:dartdoc_runner/storage.dart';

Logger _logger = new Logger("main");

main(List<String> args) async {
  logging.initialize();
  var config = new Config.buildFromFiles("config.yaml", "credentials.yaml");
  var service = new PubRetriever();
  var generator = new Generator(config);
  var storage = new Storage(config);
  var uploader = new Uploader(config, storage);
  while (true) {
    Set<Package> allPackages = (await service.update());
    var shard = await getShard(config);
    allPackages.removeAll(await retrieveFromStorage(config, storage));
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
