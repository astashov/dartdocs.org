library dartdocorg.storage;

import 'dart:async';
import 'dart:io';

import 'package:dartdocorg/config.dart';
import 'package:googleapis/storage/v1.dart' as s;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import 'package:dartdocorg/utils/retry.dart';
import 'package:logging/logging.dart';

Logger _logger = new Logger("storage");

class Storage {
  static const _scopes = const [s.StorageApi.DevstorageReadWriteScope];

  final Config config;

  Future<s.StorageApi> _storageApiInst;

  Storage(this.config);
  Future<s.StorageApi> get _storageApi async {
    if (_storageApiInst == null) {
      _storageApiInst = clientViaServiceAccount(config.credentials, _scopes).then((httpClient) {
        return new s.StorageApi(httpClient);
      });
    }
    return _storageApiInst;
  }

  Future<Null> insertFile(String path, File file, {String contentType, int maxAge: 3600}) async {
    contentType = contentType ?? _getContentType(path);
    await retry(() async {
      var length = await file.openRead().transform(GZIP.encoder).fold(0, (memo, b) => memo + b.length);
      var stream = file.openRead().transform(GZIP.encoder);
      var media = new s.Media(stream, length, contentType: contentType);
      _logger.fine("Uploading $path");
      var future = (await _storageApi).objects.insert(new s.Object.fromJson({"cacheControl": "public, max-age=$maxAge"}), config.bucket,
          contentEncoding: "gzip",
          name: path,
          uploadMedia: media,
          predefinedAcl: "publicRead");
      var microseconds = length * 200 + 5000000; // give 5 seconds minimum
      return future.timeout(new Duration(microseconds: microseconds), onTimeout: () {
        throw 'Timed out ${microseconds}mks - $path';
      });
    });
  }

  Future<Null> insertKey(String path) async {
    var media = new s.Media(new Stream.empty(), 0, contentType: "text/plain");
    await retry(() async {
      return (await _storageApi)
          .objects
          .insert(null, config.bucket, name: path, uploadMedia: media, predefinedAcl: "publicRead");
    });
  }

  Future<Iterable<String>> list({String prefix, String delimiter}) async {
    List<String> results = [];
    String pageToken;
    do {
      var objects = await retry(() async {
        return (await _storageApi)
            .objects
            .list(config.bucket, prefix: prefix, delimiter: delimiter, pageToken: pageToken);
      });
      pageToken = objects.nextPageToken;
      if (objects.items != null && objects.items.isNotEmpty) {
        results.addAll(objects.items.map((i) => i.name));
      }
    } while (pageToken != null);
    return results;
  }

  String _getContentType(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.html':
        return "text/html";
      case '.css':
        return "text/css";
      case '.js':
        return "application/javascript";
      case '.png':
        return "image/png";
      case '.jpg':
        return "image/jpeg";
      case '.jpeg':
        return "image/jpeg";
      case '.json':
        return "application/json";
      case '.txt':
        return "text/plain";
      default:
        return "application/octet-stream";
    }
  }
}
