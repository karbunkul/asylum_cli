import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ConfigLoader {
  static const String configFileName = 'asylum.yaml';

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

  /// Loads environment variables from the found `asylum.yaml`.
  Map<String, String> loadEnvironment(
    File configFile, [
    Map<String, String>? environment,
  ]) {
    final content = configFile.readAsStringSync();
    final yamlMap = loadYaml(content);

    if (yamlMap == null || yamlMap is! YamlMap) {
      return {};
    }

    final env = yamlMap['environment'];
    if (env == null || env is! YamlMap) {
      return {};
    }

    final result = <String, String>{};
    final asylumRoot = configFile.parent.absolute.path;

    // Use a context that includes ASYLUM_ROOT for interpolation
    final context = {
      ...(environment ?? Platform.environment),
      'ASYLUM_ROOT': asylumRoot,
    };

    // Pre-populate result with ASYLUM_ROOT
    result['ASYLUM_ROOT'] = asylumRoot;

    for (final entry in env.entries) {
      final key = entry.key.toString();
      final value = entry.value.toString();
      result[key] = _interpolate(value, context);
    }
    return result;
  }

  String _interpolate(String value, Map<String, String> environment) {
    final regex = RegExp(
      r'\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}|\$([a-zA-Z_][a-zA-Z0-9_]*)',
    );
    return value.replaceAllMapped(regex, (match) {
      final name = match.group(1) ?? match.group(2)!;
      return environment[name] ?? '';
    });
  }
}
