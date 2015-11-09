library dartdocorg.bin.purge_cdn_cache;

import 'package:args/args.dart';
import 'package:dartdocorg/cleaners/cdn_cleaner.dart';
import 'package:dartdocorg/config.dart';
import 'package:dartdocorg/logging.dart' as logging;
import 'package:logging/logging.dart';

final Logger _logger = new Logger("purge_cdn_cache");

main(List<String> args) async {
  logging.initialize();
  var parser = new ArgParser();
  parser.addOption('dirroot',
      help: "Specify the application directory, if not current");
  parser.addFlag('help', negatable: false, help: "Show help");
  var argsResults = parser.parse(args);
  if (argsResults["help"]) {
    print(
        "Purges the CloudFront CDN cache for the whole site. Useful when we need "
        "to regenerate everything with the new dartdoc verion\n");
    print(parser.usage);
    return;
  }
  var config = new Config.buildFromFiles(
      argsResults["dirroot"], "config.yaml", "credentials.yaml");
  var cdnCleaner = new CdnCleaner(config);
  _logger.info("Clearing all CDN cache");
  await cdnCleaner.purgeAll();
  _logger.info("Done");
}
