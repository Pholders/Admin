import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import 'package:pholders_admin/store.dart';
import '../../core/routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../sidebar/app_sidebar.dart';
import '../top_bar/top_bar.dart';

/// Every screen (Dashboard, Patients, All Orders, Returns, ...) shares the
/// same frame: sidebar on the left, a rounded teal content panel on the
/// right with the top bar pinned above a scrollable body. Building this
/// once means new screens only need to supply a breadcrumb label and body.
class AppShell extends StatelessWidget {
  final String currentPage;
  final Widget body;

  const AppShell({super.key, required this.currentPage, required this.body});

  @override
  Widget build(BuildContext context) {
    // Every authenticated screen sits inside this shell, so it is the one
    // place that has to notice a session dying mid-session. The API answers
    // 401/403 once the token is revoked or expired; middleware turns that
    // into a `SessionExpiredAction`, and this routes out of the shell —
    // GoRouter's redirect only re-runs on navigation, so nothing else would.
    return StoreConnector<AppState, bool>(
      converter: (store) => store.state.authState.isAuthenticated,
      distinct: true,
      onDidChange: (wasAuthenticated, isAuthenticated) {
        if (wasAuthenticated == true && !isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session expired. Please sign in again.'),
            ),
          );
          context.go(AppRoutes.adminLogin);
        }
      },
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSidebar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.contentBackground,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TopBar(
                          breadcrumbTrail: 'Pholders',
                          currentPage: currentPage,
                        ),
                        const SizedBox(height: 24),
                        Expanded(child: body),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
