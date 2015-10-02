library dartdoc_runner.index_uploader;

import 'dart:async';
import 'dart:io';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/generators/index_generator.dart';
import 'package:dartdoc_runner/storage.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

Logger _logger = new Logger("index_uploader");

class IndexUploader {
  final Config config;
  final Storage storage;
  IndexUploader(this.config, this.storage);

  Future<Null> uploadIndexFiles() async {
    _logger.info("Uploading index files...");
    await Future.wait(MenuItem.all.map((menuItem) {
      return storage.insertFile(menuItem.url, new File(p.join(config.outputDir, menuItem.url)));
    }));
  }
}
