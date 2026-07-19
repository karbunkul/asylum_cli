import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ConfigLoader {
  static const String configFileName = 'asylum.yaml';
  static const String dotEnvFileName = '.env';

  /// Searches for `asylum.yaml` recursively from [startDir] up to the root.
  /// Throws [FileSystemException] if not found.
  File findConfigFile(String startDir) {
    var currentDir = Directory(startDir);

    while (true) {
      final configFile = File(p.join(currentDir.path, configFileName));
      if (configFile.existsSync()) {
        return configFile;
      }

      final parentDir = currentDir.parent;
      if (parentDir.path == currentDir.path) {
        // We reached the root
        throw FileSystemException(
          'Config Not Found: $configFileName not found in any parent directories.',
        );
      }
      currentDir = parentDir;
    }
  }

  /// Looks for a `.env` file in the same directory as [configFile].
  /// Returns a map of parsed key-value pairs, or an empty map if the file doesn't exist.
  Map<String, String> loadDotEnvFile(File configFile) {
    final dotEnvFile = File(p.join(configFile.parent.path, dotEnvFileName));
    if (!dotEnvFile.existsSync()) return {};

    final result = <String, String>{};
    final lines = dotEnvFile.readAsLinesSync();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final eqIndex = trimmed.indexOf('=');
      if (eqIndex == -1) continue;

      final key = trimmed.substring(0, eqIndex).trim();
      if (key.isEmpty) continue;

      var value = trimmed.substring(eqIndex + 1).trim();

      if (value.startsWith('"') && value.endsWith('"') ||
          value.startsWith("'") && value.endsWith("'")) {
        value = value.substring(1, value.length - 1);
      }

      result[key] = value;
    }

    return result;
  }

  /// Loads environment variables from the found `asylum.yaml`, merging with
  /// platform/default context and optionally overriding them with dynamic command results.
  Map<String, String> loadEnvironment({
    required File configFile,
    Map<String, String>? platformEnv,
    Map<String, String>? dynamicConfig,
  }) {
    final content = configFile.readAsStringSync();
    final yamlMap = loadYaml(content);

    if (yamlMap == null || yamlMap is! YamlMap) {
      return {};
    }

    final env = yamlMap['environment'];
    if (env == null || env is! YamlMap) {
      return {};
    }

    final asylumRoot = configFile.parent.absolute.path;

    // 1. Load .env vars as the base layer
    final dotEnv = loadDotEnvFile(configFile);

    // 2. Define the base context for interpolation (Defaults, environment file, ASYLUM_ROOT)
    final baseContext = {
      ...(platformEnv ?? Platform.environment),
      ...dotEnv,
      'ASYLUM_ROOT': asylumRoot,
    };

    // 3. Build the result map by merging layers (Base -> YAML environment -> Dynamic)
    final Map<String, String> mergedEnv = <String, String>{};

    // Start with Base (.env + Platform)
    mergedEnv.addAll(baseContext);

    // Merge YAML environment settings, interpolating values
    final yamlEnvResult = <String, String>{};
    final currentContext = Map<String, String>.from(baseContext);
    for (final entry in env.entries) {
      final key = entry.key.toString();
      final value = entry.value?.toString() ?? '';
      final interpolatedValue = _interpolate(
        value,
        currentContext,
        configFile.parent.path,
      );
      yamlEnvResult[key] = interpolatedValue;
      currentContext[key] = interpolatedValue;
    }
    mergedEnv.addAll(yamlEnvResult);

    // 4. Overlay dynamic configurations (Highest Precedence)
    if (dynamicConfig != null) {
      mergedEnv.addAll(dynamicConfig);
    }

    return mergedEnv;
  }

  /// Loads aliases from the found `asylum.yaml`.
  Map<String, String> loadAliases({
    required File configFile,
    Map<String, String>? platformEnv,
  }) {
    final content = configFile.readAsStringSync();
    final yamlMap = loadYaml(content);

    if (yamlMap == null || yamlMap is! YamlMap) {
      return {};
    }

    final aliases = yamlMap['aliases'];
    if (aliases == null || aliases is! YamlMap) {
      return {};
    }

    final asylumRoot = configFile.parent.absolute.path;

    // Define the base context for interpolation
    final baseContext = {
      ...(platformEnv ?? Platform.environment),
      'ASYLUM_ROOT': asylumRoot,
    };

    final result = <String, String>{};
    final currentContext = Map<String, String>.from(baseContext);
    for (final entry in aliases.entries) {
      final key = entry.key.toString();
      final value = entry.value?.toString() ?? '';
      final interpolatedValue = _interpolate(
        value,
        currentContext,
        configFile.parent.path,
      );
      result[key] = interpolatedValue;
      currentContext[key] = interpolatedValue;
    }
    return result;
  }

  String _interpolate(
    String value,
    Map<String, String> environment,
    String workingDirectory,
  ) {
    // 1. Variable interpolation: $VAR or ${VAR}
    final varRegex = RegExp(
      r'\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}|\$([a-zA-Z_][a-zA-Z0-9_]*)',
    );
    var result = value.replaceAllMapped(varRegex, (match) {
      final name = match.group(1) ?? match.group(2)!;
      return environment[name] ?? '';
    });

    // 2. Exec interpolation: {exec: command}
    final execRegex = RegExp(r'\{exec:\s*(.*?)\}');
    result = result.replaceAllMapped(execRegex, (match) {
      final command = match.group(1)!;
      try {
        final shell = Platform.isWindows ? 'cmd' : 'sh';
        final flag = Platform.isWindows ? '/c' : '-c';

        final processResult = Process.runSync(
          shell,
          [flag, command],
          environment: environment,
          workingDirectory: workingDirectory,
        );

        if (processResult.exitCode == 0) {
          return processResult.stdout.toString().trim();
        } else {
          return '';
        }
      } catch (e) {
        return '';
      }
    });

    return result;
  }
}
