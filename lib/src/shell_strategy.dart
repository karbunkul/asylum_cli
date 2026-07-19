import 'dart:io';

import 'models.dart';

abstract class ShellStrategy {
  String get name;
  Future<void> prepareEnvironment(AsylumContext context, Directory tempDir);
  List<String> getShellArguments(Directory tempDir);
}

class ZshStrategy extends ShellStrategy {
  @override
  String get name => 'zsh';

  @override
  List<String> getShellArguments(Directory tempDir) => ['-i'];

  @override
  Future<void> prepareEnvironment(
    AsylumContext context,
    Directory tempDir,
  ) async {
    final home = Platform.environment['HOME'] ?? '';
    final tempZshrc = File('${tempDir.path}/.zshrc');

    final buffer = StringBuffer();

    // Zsh sources these files in order. Since we redirect ZDOTDIR,
    // we must manually source the original ones from HOME.
    buffer.writeln('[[ -f "$home/.zshenv" ]] && . "$home/.zshenv"');
    buffer.writeln('[[ -f "$home/.zprofile" ]] && . "$home/.zprofile"');
    buffer.writeln('[[ -f "$home/.zshrc" ]] && . "$home/.zshrc"');

    for (final command in context.commands) {
      buffer.writeln(command);
    }

    for (final entry in context.aliases.entries) {
      final name = entry.key;
      final value = entry.value.replaceAll("'", "'\\''");
      buffer.writeln("alias $name='$value'");
    }

    buffer.writeln('PROMPT="[asylum] \$PROMPT"');

    // Handle Ctrl+C (SIGINT) by exiting the shell
    buffer.writeln('trap "exit 130" INT');

    // Unset ZDOTDIR so that subshells started from within asylum
    // don't use this temporary directory and instead use the default ~/.zshrc
    buffer.writeln('unset ZDOTDIR');

    await tempZshrc.writeAsString(buffer.toString());
    context.environment['ZDOTDIR'] = tempDir.path;
  }
}

class BashStrategy extends ShellStrategy {
  @override
  String get name => 'bash';

  @override
  List<String> getShellArguments(Directory tempDir) => [
    '--rcfile',
    '${tempDir.path}/.bashrc',
    '-i',
  ];

  @override
  Future<void> prepareEnvironment(
    AsylumContext context,
    Directory tempDir,
  ) async {
    final home = Platform.environment['HOME'] ?? '';
    final originalBashrc = '$home/.bashrc';
    final tempBashrc = File('${tempDir.path}/.bashrc');

    final buffer = StringBuffer();
    buffer.writeln(
      'if [ -f "$originalBashrc" ]; then source "$originalBashrc"; fi',
    );

    for (final command in context.commands) {
      buffer.writeln(command);
    }

    for (final entry in context.aliases.entries) {
      final name = entry.key;
      final value = entry.value.replaceAll("'", "'\\''");
      buffer.writeln("alias $name='$value'");
    }

    buffer.writeln('PS1="[asylum] \$PS1"');

    // Handle Ctrl+C (SIGINT) by exiting the shell
    buffer.writeln('trap "exit 130" SIGINT');

    await tempBashrc.writeAsString(buffer.toString());
  }
}
