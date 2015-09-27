library dartdoc_runner.storage;

import 'dart:async';

import 'package:dartdoc_runner/config.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class Storage {
  final Config config;

  static const _scopes = const [StorageApi.DevstorageReadWriteScope];

  Storage(this.config);

  Future<StorageApi> _storageApiInst;
  Future<StorageApi> get _storageApi async {
    if (_storageApiInst == null) {
      _storageApiInst = clientViaServiceAccount(config.credentials, _scopes).then((httpClient) {
        return new StorageApi(httpClient);
      });
    }
    return _storageApiInst;
  }

  Future<Iterable<String>> list({String prefix, String delimiter}) async {
    List<String> results = [];
    String pageToken;
    do {
      var objects = await (await _storageApi).objects.list(
          config.bucket, prefix: prefix, delimiter: delimiter, pageToken: pageToken);
      pageToken = objects.nextPageToken;
      if (objects.items != null && objects.items.isNotEmpty) {
        results.addAll(objects.items.map((i) => i.name));
      }
    } while (pageToken != null);
    return results;
  }

  Future<Null> insertFile(String path, File file, {String contentType}) async {
    contentType = contentType ?? _getContentType(path);
    var media = new Media(file.openRead(), await file.length(), contentType: contentType);
    await (await _storageApi).objects.insert(null, config.bucket, name: path, uploadMedia: media, predefinedAcl: "publicRead");
  }

  Future<Null> insertKey(String path) async {
    var media = new Media(new Stream.empty(), 0, contentType: "text/plain");
    await (await _storageApi).objects.insert(null, config.bucket, name: path, uploadMedia: media, predefinedAcl: "publicRead");
  }

  String _getContentType(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.html': return "text/html";
      case '.css': return "text/css";
      case '.js': return "application/javascript";
      case '.png': return "image/png";
      case '.jpg': return "image/jpeg";
      case '.jpeg': return "image/jpeg";
      case '.json': return "application/json";
      case '.txt': return "text/plain";
      default: return "application/octet-stream";
    }
  }

}