import 'dart:io';
import 'package:asylum_cli/asylum_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Asylum Plugin System', () {
    test('SecretKeyPlugin should add SECRET_KEY to environment', () async {
      final context = AsylumContext(environment: {}, commands: []);
      final plugin = SecretKeyPlugin();

      await plugin.apply(context);

      expect(context.environment['SECRET_KEY'], 'asylum_v1_activated');
    });
  });

  group('Shell Strategies', () {
    test('ZshStrategy should set ZDOTDIR and create .zshrc', () async {
      final context = AsylumContext(environment: {}, commands: []);
      final strategy = ZshStrategy();
      final tempDir = await Directory.systemTemp.createTemp('asylum_test_');

      try {
        await strategy.prepareEnvironment(context, tempDir);

        expect(context.environment['ZDOTDIR'], tempDir.path);
        
        final zshrc = File('${tempDir.path}/.zshrc');
        expect(await zshrc.exists(), isTrue);
        
        final content = await zshrc.readAsString();
        expect(content, contains('PROMPT="[asylum] \$PROMPT"'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('BashStrategy should create .bashrc', () async {
      final context = AsylumContext(environment: {}, commands: []);
      final strategy = BashStrategy();
      final tempDir = await Directory.systemTemp.createTemp('asylum_test_');

      try {
        await strategy.prepareEnvironment(context, tempDir);

        final bashrc = File('${tempDir.path}/.bashrc');
        expect(await bashrc.exists(), isTrue);
        
        final content = await bashrc.readAsString();
        expect(content, contains('PS1="[asylum] \$PS1"'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
