import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/account/account_screen.dart';
import 'features/account/advertise_screen.dart';
import 'features/account/favorites_screen.dart';
import 'features/account/notifications_screen.dart';
import 'features/account/order_detail_screen.dart';
import 'features/account/orders_screen.dart';
import 'features/account/profile_edit_screen.dart';
import 'features/account/theme_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/blogs/blog_detail_screen.dart';
import 'features/blogs/blogs_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/cart/checkout_screen.dart';
import 'features/cart/order_success_screen.dart';
import 'features/home/home_screen.dart';
import 'features/notebook/notebook_builder_screen.dart';
import 'features/sellback/sellback_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/shop/listing_detail_screen.dart';
import 'features/shop/shop_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/shop', builder: (_, state) {
                return ShopScreen(
                  initialCategorySlug: state.uri.queryParameters['cat'],
                  initialSearch: state.uri.queryParameters['q'],
                );
              }),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/sell', builder: (_, _) => const SellbackScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/account', builder: (_, _) => const AccountScreen()),
            ]),
          ],
        ),
        GoRoute(
            path: '/login',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, state) =>
                LoginScreen(next: state.uri.queryParameters['next'])),
        GoRoute(
            path: '/register',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const RegisterScreen()),
        GoRoute(
            path: '/forgot-password',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const ForgotPasswordScreen()),
        GoRoute(
            path: '/listing/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, state) =>
                ListingDetailScreen(id: state.pathParameters['id']!)),
        GoRoute(
            path: '/checkout',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const CheckoutScreen()),
        GoRoute(
            path: '/order-success/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, state) =>
                OrderSuccessScreen(orderId: state.pathParameters['id']!)),
        GoRoute(
            path: '/notebook',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const NotebookBuilderScreen()),
        GoRoute(
            path: '/blogs',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const BlogsScreen()),
        GoRoute(
            path: '/blogs/:slug',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, state) =>
                BlogDetailScreen(slug: state.pathParameters['slug']!)),
        GoRoute(
            path: '/orders',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const OrdersScreen()),
        GoRoute(
            path: '/orders/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, state) =>
                OrderDetailScreen(id: state.pathParameters['id']!)),
        GoRoute(
            path: '/favorites',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const FavoritesScreen()),
        GoRoute(
            path: '/notifications',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const NotificationsScreen()),
        GoRoute(
            path: '/advertise',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const AdvertiseScreen()),
        GoRoute(
            path: '/profile-edit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const ProfileEditScreen()),
        GoRoute(
            path: '/theme',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const ThemeScreen()),
      ],
    );
