import 'dart:io';

import 'package:asylum_cli/src/config_loader.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ConfigLoader', () {
    late Directory tempDir;
    late ConfigLoader loader;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asylum_test_');
      loader = ConfigLoader();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('findConfigFile finds file in current directory', () {
      final configFile = File(p.join(tempDir.path, 'asylum.yaml'));
      configFile.writeAsStringSync('environment: { TEST_VAR: "true" }');

      final found = loader.findConfigFile(tempDir.path);
      expect(found.path, equals(configFile.path));
    });

    test('findConfigFile finds file in parent directory', () {
      final configFile = File(p.join(tempDir.path, 'asylum.yaml'));
      configFile.writeAsStringSync('environment: { TEST_VAR: "true" }');

      final subDir = Directory(p.join(tempDir.path, 'sub', 'dir'))
        ..createSync(recursive: true);

      final found = loader.findConfigFile(subDir.path);
      expect(found.path, equals(configFile.path));
    });

    test('findConfigFile throws FileSystemException if not found', () {
      expect(
        () => loader.findConfigFile(tempDir.path),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('loadEnvironment parses yaml correctly', () {
      final configFile = File(p.join(tempDir.path, 'asylum.yaml'));
      configFile.writeAsStringSync('''
environment:
  KEY1: value1
  KEY2: 123
''');

      final env = loader.loadEnvironment(configFile);
      expect(env['KEY1'], 'value1');
      expect(env['KEY2'], '123');
      expect(env['ASYLUM_ROOT'], equals(tempDir.path));
    });

    test('loadEnvironment returns empty map if environment key is missing', () {
      final configFile = File(p.join(tempDir.path, 'asylum.yaml'));
      configFile.writeAsStringSync('foo: bar');

      final env = loader.loadEnvironment(configFile);
      expect(env, isEmpty);
    });

    test('loadEnvironment interpolates environment variables', () {
      final configFile = File(p.join(tempDir.path, 'asylum.yaml'));
      configFile.writeAsStringSync('''
environment:
  PATH: \$HOST_PATH:./bin
  USER_HOME: \${HOME}/.asylum
  MIXED: \$VAR1 and \${VAR2}
  MISSING: \$NON_EXISTENT
''');

      final mockEnv = {
        'HOST_PATH': '/usr/bin',
        'HOME': '/home/user',
        'VAR1': 'val1',
        'VAR2': 'val2',
      };

      final env = loader.loadEnvironment(configFile, mockEnv);
      expect(env['PATH'], '/usr/bin:./bin');
      expect(env['USER_HOME'], '/home/user/.asylum');
      expect(env['MIXED'], 'val1 and val2');
      expect(env['MISSING'], '');
      expect(env['ASYLUM_ROOT'], equals(tempDir.path));
    });

    test('loadEnvironment handles unbalanced interpolation braces', () {
      final configFile = File(p.join(tempDir.path, 'asylum.yaml'));
      configFile.writeAsStringSync('''
environment:
  UNBALANCED_OPEN: \${VAR
  UNBALANCED_CLOSE: \$VAR}
''');

      final mockEnv = {'VAR': 'value'};

      final env = loader.loadEnvironment(configFile, mockEnv);

      // Strict behavior: ${VAR is literal, $VAR} interpolates $VAR
      expect(env['UNBALANCED_OPEN'], equals('\${VAR'));
      expect(env['UNBALANCED_CLOSE'], equals('value}'));
    });

    test('loadEnvironment injects and interpolates ASYLUM_ROOT', () {
      final configFile = File(p.join(tempDir.path, 'asylum.yaml'));
      configFile.writeAsStringSync('''
environment:
  PROJECT_BIN: \$ASYLUM_ROOT/bin
  PROJECT_LIB: \${ASYLUM_ROOT}/lib
''');

      final env = loader.loadEnvironment(configFile, {});

      expect(env['ASYLUM_ROOT'], equals(tempDir.path));
      expect(env['PROJECT_BIN'], equals('${tempDir.path}/bin'));
      expect(env['PROJECT_LIB'], equals('${tempDir.path}/lib'));
    });
  });
}
