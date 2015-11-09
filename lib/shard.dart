/// Implements "sharding", i.e. a way to split documentation generation work between many instances
///
/// The algorithm is simple - we just get the list of all the instances in particular instance group on Google Cloud
/// (defined in config.yaml:gc_group_name), sort them and then try to find the index of the current instance name
/// in the list. If found, then it will take that part of the package list.
///
/// Example:
///
/// Sorted instance group's instances:
///
/// * dartdocs-package-generators-a734
/// * dartdocs-package-generators-m6nl
/// * dartdocs-package-generators-nfqz
/// * dartdocs-package-generators-vudu
///
/// Name of the current instance - dartdocs-package-generators-m6nl. Then let's say after retrieving the total list of
/// packages from pub and filtering out already processed ones, we ended up with the list of 100 packages. Then,
/// this instance will take care of the packages from 25 to 50 (second quarter)

import 'dart:async';
import 'dart:io';

import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/utils.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/compute/v1.dart';
import 'package:logging/logging.dart';

final _logger = new Logger("shard");

const _scopes = const [ComputeApi.ComputeReadonlyScope];

Future<Shard> getShard(Config config) async {
  var instances = await _retrieveInstanceGroupInstances(config);
  List<String> list = instances.toList()..sort();
  var hostname = Platform.localHostname;
  var index = list.indexOf(hostname);
  if (index >= 0) {
    return new Shard(index, list.length);
  } else {
    return new Shard(0, 1);
  }
}

Future<Set<String>> _retrieveInstanceGroupInstances(Config config) async {
  var httpClient = await clientViaServiceAccount(config.credentials, _scopes);
  var compute = new ComputeApi(httpClient);
  var instanceGroupsListInstances = await compute.instanceGroups.listInstances(
      new InstanceGroupsListInstancesRequest(),
      config.gcProjectName,
      config.gcZone,
      config.gcGroupName);
  if (instanceGroupsListInstances?.items != null &&
      instanceGroupsListInstances.items.isNotEmpty) {
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
