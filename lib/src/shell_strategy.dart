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
  Future<void> prepareEnvironment(AsylumContext context, Directory tempDir) async {
    final home = Platform.environment['HOME'] ?? '';
    final originalZshrc = '$home/.zshrc';
    final tempZshrc = File('${tempDir.path}/.zshrc');

    final buffer = StringBuffer();
    buffer.writeln('if [ -f "$originalZshrc" ]; then source "$originalZshrc"; fi');
    
    for (final command in context.commands) {
      buffer.writeln(command);
    }
    
    buffer.writeln('PROMPT="[asylum] \$PROMPT"');

    await tempZshrc.writeAsString(buffer.toString());
    context.environment['ZDOTDIR'] = tempDir.path;
  }
}

class BashStrategy extends ShellStrategy {
  @override
  String get name => 'bash';

  @override
  List<String> getShellArguments(Directory tempDir) => ['--rcfile', '${tempDir.path}/.bashrc', '-i'];

  @override
  Future<void> prepareEnvironment(AsylumContext context, Directory tempDir) async {
    final home = Platform.environment['HOME'] ?? '';
    final originalBashrc = '$home/.bashrc';
    final tempBashrc = File('${tempDir.path}/.bashrc');

    final buffer = StringBuffer();
    buffer.writeln('if [ -f "$originalBashrc" ]; then source "$originalBashrc"; fi');
    
    for (final command in context.commands) {
      buffer.writeln(command);
    }
    
    buffer.writeln('PS1="[asylum] \$PS1"');

    await tempBashrc.writeAsString(buffer.toString());
  }
}
