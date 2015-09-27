import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task("Analyzes the project for errors and warnings.")
analyze() {
  new PubApp.local('tuneup').run(['check']);
}

@Task("Lints the project for Dart formatting errors.")
lint() {
  new PubApp.local('linter').run(["bin/", "lib/", "test/", "tool/"]);
}
