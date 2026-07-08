import 'dart:io';

import 'package:asylum_cli/asylum_cli.dart';

void main(List<String> arguments) async {
  final runner = AsylumRunner(plugins: [SecretKeyPlugin()]);

  final exitCode = await runner.run();
  exit(exitCode);
}
