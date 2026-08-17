import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  final store = await createAppStore();

  runApp(PholdersAdminApp(store: store));
}

class PholdersAdminApp extends StatelessWidget {
  const PholdersAdminApp({super.key, required this.store});

  final Store<AppState> store;

  @override
  Widget build(BuildContext context) {
    final router = createRouter(store);

    return StoreProvider<AppState>(
      store: store,
      child: MaterialApp.router(
        title: 'Pholders Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
