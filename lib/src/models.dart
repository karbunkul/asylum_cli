class AsylumContext {
  final Map<String, String> environment;
  final Map<String, String> aliases;
  final List<String> commands;

  AsylumContext({
    required this.environment,
    required this.aliases,
    required this.commands,
  });
}

abstract class AsylumPlugin {
  Future<void> apply(AsylumContext context);
}
