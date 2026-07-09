import 'dart:io';

import 'package:asylum_cli/asylum_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Asylum Plugin System', () {
    test('SecretKeyPlugin should add SECRET_KEY to environment', () async {
      final context = AsylumContext(environment: {}, commands: [], aliases: {});
      final plugin = SecretKeyPlugin();

      await plugin.apply(context);

      expect(context.environment['SECRET_KEY'], 'asylum_v1_activated');
    });
  });

  group('Shell Strategies', () {
    test(
      'ZshStrategy should set ZDOTDIR and create .zshrc with aliases',
      () async {
        final context = AsylumContext(
          environment: {},
          commands: [],
          aliases: {'ll': 'ls -la', 'say-hi': "echo 'Hi'"},
        );
        final strategy = ZshStrategy();
        final tempDir = await Directory.systemTemp.createTemp('asylum_test_');

        try {
          await strategy.prepareEnvironment(context, tempDir);

          expect(context.environment['ZDOTDIR'], tempDir.path);

          final zshrc = File('${tempDir.path}/.zshrc');
          expect(await zshrc.exists(), isTrue);

          final content = await zshrc.readAsString();
          expect(content, contains('PROMPT="[asylum] \$PROMPT"'));
          expect(content, contains("alias ll='ls -la'"));
          expect(content, contains("alias say-hi='echo '\\''Hi'\\'''"));
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('BashStrategy should create .bashrc with aliases', () async {
      final context = AsylumContext(
        environment: {},
        commands: [],
        aliases: {'ll': 'ls -la'},
      );
      final strategy = BashStrategy();
      final tempDir = await Directory.systemTemp.createTemp('asylum_test_');

      try {
        await strategy.prepareEnvironment(context, tempDir);

        final bashrc = File('${tempDir.path}/.bashrc');
        expect(await bashrc.exists(), isTrue);

        final content = await bashrc.readAsString();
        expect(content, contains('PS1="[asylum] \$PS1"'));
        expect(content, contains("alias ll='ls -la'"));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
