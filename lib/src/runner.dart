import 'dart:io';

import 'config_loader.dart';
import 'models.dart';
import 'shell_strategy.dart';

class AsylumRunner {
  final List<AsylumPlugin> plugins;

  AsylumRunner({required this.plugins});

  ShellStrategy _detectShell() {
    final shellPath = Platform.environment['SHELL'] ?? '';
    if (shellPath.contains('zsh')) {
      return ZshStrategy();
    } else if (shellPath.contains('bash')) {
      return BashStrategy();
    }
    // Default to Zsh if unknown, or we could throw an error
    return ZshStrategy();
  }

  Future<int> run() async {
    final shellStrategy = _detectShell();

    // Load configuration
    Map<String, String> configEnv = {};
    try {
      final configLoader = ConfigLoader();
      final configFile = configLoader.findConfigFile(Directory.current.path);
      configEnv = configLoader.loadEnvironment(configFile);
    } catch (e) {
      if (e is FileSystemException) {
        // Log that config wasn't found, but it's optional.
        print('ℹ️ No asylum.yaml found. Proceeding with default environment.');
      } else {
        print('⚠️ Error loading asylum.yaml: $e');
      }
    }

    final tempDir = await Directory.systemTemp.createTemp('asylum_ctx_');

    final context = AsylumContext(
      environment: {...Platform.environment, ...configEnv},
      commands: [],
    );

    // Apply plugins
    for (final plugin in plugins) {
      await plugin.apply(context);
    }

    // Prepare shell environment
    await shellStrategy.prepareEnvironment(context, tempDir);

    print(
      '🎭 Entering Asylum using ${shellStrategy.name}... Type "exit" to leave.',
    );

    final shellPath = Platform.environment['SHELL'] ?? '/bin/sh';
    final process = await Process.start(
      shellPath,
      shellStrategy.getShellArguments(tempDir),
      environment: context.environment,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;

    await tempDir.delete(recursive: true);
    print('\n🚪 Exited Asylum. (Exit code: $exitCode)');

    return exitCode;
  }
}
