import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mandena/core/shared_preferences.dart';
import 'package:mandena/home/pages/items_page.dart';
import 'package:mandena/home/pages/offers_page.dart';
import 'package:mandena/modules/account/account_banned_view.dart';
import 'package:mandena/modules/branch/branch_controller.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import 'package:mandena/modules/categories/categories_view.dart';
import 'package:mandena/modules/connection/network_controller.dart';
import 'package:mandena/modules/connection/no_connection_view.dart';
import 'package:mandena/modules/favorites/favorites_controller.dart';
import 'package:mandena/modules/item_detail/item_detail_controller.dart';
import 'package:mandena/modules/item_detail/item_detail_view.dart';
import 'package:mandena/modules/orders/my_orders_page.dart';
import 'package:mandena/modules/orders/order_details_controller.dart';
import 'package:mandena/modules/orders/order_details_view.dart';
import 'package:mandena/modules/orders/order_tracking_view.dart';
import 'core/notification_service.dart';

import 'modules/account/profile_view.dart';
import 'core/session.dart';
import 'theme/app_theme.dart';
import 'app_routes.dart';

import 'modules/addresses/addresses_view.dart';
import 'auth/login/login_view.dart';
import 'auth/register/register_view.dart';

import 'modules/root/root_view.dart';
import 'modules/cart/cart_view.dart';
import 'modules/favorites/favorites_view.dart';

import 'modules/items/items_controller.dart';
import 'modules/items/items_view.dart';

import 'modules/splash/splash_screen.dart';
import 'modules/account/account_view.dart';
import 'modules/account/account_controller.dart';

import 'modules/addresses/map_pick_view.dart';
import 'modules/account/developers_view.dart';
import 'core/theme_service.dart';

void setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔥 [Flutter Error] ${details.exception}');
    debugPrint(details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔥 [Dart Error] $error');
    debugPrint(stack.toString());
    return true;
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupErrorHandling();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await GetStorage.init();

  final branchController = Get.put(BranchController(), permanent: true);
  await branchController.initBranching();

  await Session.init();
  Get.put(ConnectionController(), permanent: true);
  await PrefsService.init();

  await NotificationService.init();

  runApp(const MandenaApp());
}

class MandenaApp extends StatelessWidget {
  const MandenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF6F5F3);

    final baseLight = AppTheme.light;
    final baseDark = AppTheme.dark;

    final lightTheme = baseLight.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: cream,
      canvasColor: cream,
      cardColor: Colors.white,
      colorScheme: baseLight.colorScheme.copyWith(
        brightness: Brightness.light,
        surface: Colors.white,
        primary: const Color(0xFFFF5A00),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFF5A00);
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFF5A00).withOpacity(.35);
          }
          return null;
        }),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    final darkTheme = baseDark.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      canvasColor: const Color(0xFF0B1220),
      cardColor: const Color(0xFF111827),
      colorScheme: baseDark.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: const Color(0xFFFF5A00),
        surface: const Color(0xFF111827),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B1220),
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFF5A00);
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFFF5A00).withOpacity(.35);
          }
          return null;
        }),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF111827)),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ماندينا',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeService().theme,

      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final safeTextScale = mq.textScaleFactor.clamp(0.9, 1.1);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(safeTextScale)),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },

      locale: const Locale('ar', 'LY'),
      fallbackLocale: const Locale('ar', 'LY'),

      initialRoute: AppRoutes.splash,

      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 260),
      opaqueRoute: false,
      popGesture: true,

      initialBinding: BindingsBuilder(() {
        Get.lazyPut<CartController>(() => CartController(), fenix: true);
        Get.lazyPut<FavoritesController>(
          () => FavoritesController(),
          fenix: true,
        );
        Get.lazyPut<AccountController>(() => AccountController(), fenix: true);
      }),

      getPages: [
        GetPage(
          name: AppRoutes.splash,
          page: () => const SplashView(),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 250),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.register,
          page: () => const RegisterView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.home,
          page: () => const RootView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.cart,
          page: () => const CartView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.addresses,
          page: () => const AddressesView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.favorites,
          page: () => const FavoritesScreen(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.developersView,
          page: () => const DevelopersViewPage(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: '/orders',
          page: () => const MyOrdersPage(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.items,
          page: () => const ItemsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ItemsController>(() => ItemsController(), fenix: true);
          }),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: '/order-details',
          page: () => const OrderDetailsView(),
          binding: BindingsBuilder(() => Get.put(OrderDetailsController())),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.profileView,
          page: () => const ProfileViewPage(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.mapPick,
          page: () => const MapPickView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.account,
          page: () => const AccountView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AccountController>(
              () => AccountController(),
              fenix: true,
            );
          }),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.itemDetail,
          page: () => ItemDetailView(),
          binding: BindingsBuilder(() => Get.put(ItemDetailController())),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.ordertracking,
          page: () => OrderTrackingView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: '/my-orders',
          page: () => const MyOrdersPage(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.categories,
          page: () => const CategoriesView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.orderDetails,
          page: () => const OrderDetailsView(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<OrderDetailsController>()) {
              Get.put(OrderDetailsController());
            }
          }),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: AppRoutes.banned,
          page: () => const AccountBannedView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 260),
          opaque: false,
        ),
        GetPage(
          name: '/no_connection',
          page: () => const NoConnectionView(),
          transition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 220),
          opaque: false,
        ),
        GetPage(name: AppRoutes.homeOffers, page: () => OffersPage()),
        GetPage(
          name: AppRoutes.homeCategories,
          page: () => const CategoriesView(),
        ),
        GetPage(name: AppRoutes.homeItems, page: () => ItemsPage()),
      ],
    );
  }
}
