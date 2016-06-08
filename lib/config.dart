library dartdocorg.config;

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

enum ConfigMode { DARTDOCS, CROSSDART }

class Config {
  final String dirroot;
  final String dartSdkPath;
  final String bucket;
  final String pubCacheDir;
  final String outputDir;
  final String hostedUrl;
  final String crossdartHostedUrl;
  final String gcProjectName;
  final String gcZone;
  final String gcGroupName;
  final String gcsPrefix;
  final String crossdartGcsPrefix;
  final String gcsMeta;
  final String cloudflareApiKey;
  final String cloudflareEmail;
  final String cloudflareZone;
  final int installTimeout;
  final ServiceAccountCredentials credentials;
  final ConfigMode mode;
  final bool shouldDeleteOldPackages;
  final int numberOfConcurrentBuilds;

  factory Config.buildFromFiles(
      String dirroot, String configFile, String credentialsFile) {
    dirroot ??= Directory.current.path;
    var configValues =
        yaml.loadYaml(new File(p.join(dirroot, configFile)).readAsStringSync());
    var credentialsValues = yaml.loadYaml(
        new File(p.join(dirroot, credentialsFile)).readAsStringSync());
    var cloudflareValues = credentialsValues["cloudflare"];
    var serviceAccountCredentials = new ServiceAccountCredentials.fromJson(
        JSON.encode(credentialsValues["google_cloud"]));
    return new Config._(
        dirroot,
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
        cloudflareValues["api_key"],
        cloudflareValues["email"],
        cloudflareValues["zone"],
        configValues["install_timeout"],
        serviceAccountCredentials,
        configValues["mode"] == "crossdart" ? ConfigMode.CROSSDART : ConfigMode.DARTDOCS,
        configValues["should_delete_old_packages"],
        configValues["number_of_concurrent_builds"],
        configValues["crossdart_hosted_url"],
        configValues["crossdart_gcs_prefix"]);
  }

  Config._(
      this.dirroot,
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
      this.cloudflareApiKey,
      this.cloudflareEmail,
      this.cloudflareZone,
      this.installTimeout,
      this.credentials,
      this.mode,
      this.shouldDeleteOldPackages,
      this.numberOfConcurrentBuilds,
      this.crossdartHostedUrl,
      this.crossdartGcsPrefix);
}
