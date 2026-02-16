import 'package:flutter/widgets.dart';
import 'analytics_service.dart';
import 'package:hafiz_app/injection_container.dart';
import '../utils/logger.dart';

class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  AnalyticsRouteObserver();

  String _name(Route<dynamic> route) =>
      route.settings.name ?? route.runtimeType.toString();

  void _start(Route<dynamic> route) {
    if (route is PageRoute) {
      final name = _name(route);
      try {
        final analytics = sl<AnalyticsService>();
        analytics.logScreenView(name: name, className: route.settings.name);
        analytics.startScreenTimer(name);
      } catch (e) {
        Logger.debug(
          'Analytics error in route start',
          feature: 'Analytics',
          error: e,
        );
      }
    }
  }

  void _end(Route<dynamic> route) {
    if (route is PageRoute) {
      try {
        final analytics = sl<AnalyticsService>();
        analytics.endScreenTimer(_name(route));
      } catch (e) {
        Logger.debug(
          'Analytics error in route end',
          feature: 'Analytics',
          error: e,
        );
      }
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _start(route);
    if (previousRoute != null) _end(previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _end(route);
    if (previousRoute != null) _start(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _end(oldRoute);
    if (newRoute != null) _start(newRoute);
  }
}
