library dartdoc_runner.config;

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth.dart';
import 'package:yaml/yaml.dart' as yaml;

class Config {
  final String dartSdkPath;
  final String bucket;
  final String pubCacheDir;
  final String outputDir;
  final String hostedUrl;
  final String gcProjectName;
  final String gcZone;
  final String gcGroupName;
  final String gcsPrefix;
  final String gcsMeta;
  final int installTimeout;
  final int concurrencyCount;
  final ServiceAccountCredentials credentials;

  factory Config.buildFromFiles(String configFile, String credentialsFile) {
    var configValues = yaml.loadYaml(new File(configFile).readAsStringSync());
    var credentialsValues = yaml.loadYaml(new File(credentialsFile).readAsStringSync());
    var serviceAccountCredentials = new ServiceAccountCredentials.fromJson(JSON.encode(credentialsValues));
    return new Config._(
        configValues["dart_sdk"],
        configValues["bucket"],
        configValues["pub_cache_dir"],
        configValues["output_dir"],
        configValues["hosted_url"],
        configValues["gc_project_name"],
        configValues["gc_zone"],
        configValues["gc_group_name"],
        configValues["gcs_prefix"],
        configValues["gcs_meta"],
        configValues["install_timeout"],
        configValues["concurrency_count"],
        serviceAccountCredentials);
  }

  Config._(
      this.dartSdkPath,
      this.bucket,
      this.pubCacheDir,
      this.outputDir,
      this.hostedUrl,
      this.gcProjectName,
      this.gcZone,
      this.gcGroupName,
      this.gcsPrefix,
      this.gcsMeta,
      this.installTimeout,
      this.concurrencyCount,
      this.credentials);
}
