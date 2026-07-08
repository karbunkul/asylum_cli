import '../models.dart';

class SecretKeyPlugin implements AsylumPlugin {
  @override
  Future<void> apply(AsylumContext context) async {
    context.environment['SECRET_KEY'] = 'asylum_v1_activated';
  }
}
