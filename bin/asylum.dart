import 'dart:io';

import 'package:args/args.dart';
import 'package:asylum_cli/asylum_cli.dart';

const String version = '0.9.7';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help information.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Show the current version of Asylum.',
    )
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Specify a custom path to asylum.yaml.',
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('🎭 Asylum CLI - Project-specific shell environment manager\n');
      print('Usage: asylum [options]\n');
      print(parser.usage);
      exit(0);
    }

    if (results['version'] as bool) {
      print('Asylum version: $version');
      exit(0);
    }

    final configPath = results['config'] as String?;

    final runner = AsylumRunner(plugins: [SecretKeyPlugin()]);
    final exitCode = await runner.run(configPath: configPath);
    exit(exitCode);
  } catch (e) {
    print('❌ Error: ${e.toString()}');
    print('\nUsage: asylum [options]');
    print(parser.usage);
    exit(1);
  }
}
