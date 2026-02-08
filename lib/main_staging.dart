import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/app/providers.dart';
import 'src/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final config = AppConfig.fromDartDefines(
      defaultEnv: AppEnvironment.staging,
      defaultLogHttp: false,
    );

    runApp(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const RecallApp(),
      ),
    );
  } on AppConfigException catch (error) {
    runApp(RecallApp(configError: error.message));
  }
}
