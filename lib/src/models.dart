class AsylumContext {
  final Map<String, String> environment;
  final List<String> commands;

  AsylumContext({
    required this.environment,
    required this.commands,
  });
}

abstract class AsylumPlugin {
  Future<void> apply(AsylumContext context);
}
