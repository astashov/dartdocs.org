library dartdoc_runner.shard;

import 'dart:async';
import 'dart:io';

import 'package:dartdoc_runner/config.dart';
import 'package:dartdoc_runner/utils.dart';
import 'package:googleapis/compute/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logging/logging.dart';

var _logger = new Logger("shard");

const _scopes = const [ComputeApi.ComputeReadonlyScope];

Future<Shard> getShard(Config config) async {
  var instances = await _retrieveInstances(config);
  List<String> list = instances.toList()..sort();
  var hostname = Platform.localHostname;
  var index = list.indexOf(hostname);
  if (index >= 0) {
    return new Shard(index, list.length);
  } else {
    return new Shard(0, 1);
  }
}

Future<Set<String>> _retrieveInstances(Config config) async {
  var httpClient = await clientViaServiceAccount(config.credentials, _scopes);
  var compute = new ComputeApi(httpClient);
  var instanceGroupsListInstances = await compute.instanceGroups
      .listInstances(new InstanceGroupsListInstancesRequest(), config.gcProjectName, config.gcZone, config.gcGroupName);
  if (instanceGroupsListInstances?.items != null && instanceGroupsListInstances.items.isNotEmpty) {
    var regexp = new RegExp(r"\/([^\/]+)$");
    return instanceGroupsListInstances.items.map((item) {
      var name = regexp.firstMatch(item.instance)[1];
      return name;
    }).toSet();
  } else {
    return new Set();
  }
}

class Shard {
  final int index;
  final int total;
  Shard(this.index, this.total);
  List part(List list) {
    return inGroups(list, total).toList()[index].toList();
  }

  String toString() => "<Shard index: $index, total: $total>";
}
