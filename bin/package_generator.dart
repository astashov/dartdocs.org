library dartdoc_runner.bin.package_generator;

import 'dart:io';

import 'package:args/args.dart';
import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/generators/package_generator.dart';
import 'package:dartdoc_runner/logging.dart' as logging;
import 'package:dartdoc_runner/package.dart';
import 'package:dartdoc_runner/pub_retriever.dart';
import 'package:dartdoc_runner/shard.dart';
import 'package:dartdoc_runner/storage.dart';
import 'package:dartdoc_runner/datastore_retriever.dart';
import 'package:dartdoc_runner/uploaders/package_uploader.dart';
import 'package:logging/logging.dart';
import 'package:dartdoc_runner/cleaners/package_cleaner.dart';
import 'dart:math';
import 'package:dartdoc_runner/datastore.dart';
import 'dart:async';
import 'package:dartdoc_runner/version.dart';
import 'package:dartdoc_runner/cleaners/cdn_cleaner.dart';

class _PackageGenerator {
  final Config config;
  final PubRetriever pubRetriever;
  final Storage storage;
  final Datastore datastore;
  final DatastoreRetriever datastoreRetriever;
  final PackageGenerator generator;
  final PackageCleaner packageCleaner;
  final CdnCleaner cdnCleaner;
  final PackageUploader uploader;

  int docsVersion;

  _PackageGenerator(this.config, this.pubRetriever, this.storage, this.datastore, this.datastoreRetriever,
      this.generator, this.packageCleaner, this.cdnCleaner, this.uploader);

  factory _PackageGenerator.build() {
    var config = new Config.buildFromFiles("config.yaml", "credentials.yaml");
    var pubRetriever = new PubRetriever();
    var storage = new Storage(config);
    var datastore = new Datastore(config);
    var storageRetriever = new DatastoreRetriever(config, datastore);
    var generator = new PackageGenerator(config);
    var packageCleaner = new PackageCleaner(config);
    var cdnCleaner = new CdnCleaner(config);
    var uploader = new PackageUploader(config, storage);
    return new _PackageGenerator(
        config, pubRetriever, storage, datastore, storageRetriever, generator, packageCleaner, cdnCleaner, uploader);
  }

  Future<Null> initialize() async {
    this.docsVersion = await datastore.docsVersion();
    await generator.activateDartdoc();
  }

  Future<Iterable<Package>> retrieveNextPackages() async {
    Set<Package> allPackages = (await pubRetriever.update());
    await datastoreRetriever.update(docsVersion);
    var shard = await getShard(config);
    allPackages.removeAll(datastoreRetriever.allPackages);
    _logger.info("The number of the new packages - ${allPackages.length}");
    return shard.part(allPackages.toList()).getRange(0, min(1, allPackages.length));
  }

  Future<Null> handlePackages(Iterable<Package> packages) async {
    var erroredPackages = await generator.generate(packages);
    var successfulPackages = packages.toSet()..removeAll(erroredPackages);
    await uploader.uploadSuccessfulPackages(successfulPackages);
    _logger.info("Marking successful packages in datastore");
    await Future.wait(successfulPackages.map((package) async {
      return datastore.upsert(package, docsVersion, status: "success");
    }));
    await uploader.uploadErroredPackages(erroredPackages);
    _logger.info("Marking errored packages in datastore");
    await Future.wait(erroredPackages.map((package) async {
      return datastore.upsert(package, docsVersion, status: "error");
    }));
    await packageCleaner.delete(packages);
  }
}

main(List<String> args) async {
  var parser = new ArgParser();
  parser.addOption('name');
  parser.addOption('version');
  parser.addFlag('help', negatable: false);
  var argsResults = parser.parse(args);
  if (argsResults["help"]) {
    print(parser.usage);
    exit(0);
  }
  logging.initialize();
  var packageGenerator = new _PackageGenerator.build();

  if (argsResults["name"] != null && argsResults["version"] != null) {
    await packageGenerator.initialize();
    var package = new Package(argsResults["name"], new Version(argsResults["version"]));
    await packageGenerator.handlePackages([package]);
    exit(0);
  } else {
    while (true) {
      await packageGenerator.initialize();
      var packages = await packageGenerator.retrieveNextPackages();
      if (packages.isNotEmpty) {
        await packageGenerator.handlePackages(packages);
      } else {
        _logger.info("Sleeping for 3 minutes...");
        sleep(new Duration(minutes: 3));
      }
    }
  }
}

Logger _logger = new Logger("dartdoc_generator");
