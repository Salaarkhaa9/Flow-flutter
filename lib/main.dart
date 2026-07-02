import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/id_upload_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/cdl_upload_screen.dart';
import 'screens/main_shell.dart';
import 'screens/shipment_detail_screen.dart';
import 'screens/load_board_screen.dart';
import 'screens/load_details_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/customer_support_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/vehicle_registration_screen.dart';
import 'screens/fuel_log_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/search_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/business_profile_screen.dart';
import 'models/load.dart';
import 'models/shipment.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Run app immediately — SplashScreen handles all async init
  // so the user sees UI right away instead of a blank screen.
  runApp(const FlowApp());
}

class FlowApp extends StatelessWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FLOW',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Always start at splash; it decides the destination after async init.
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/reset_password': (context) {
          final email =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return ResetPasswordScreen(userEmail: email);
        },
        '/otp_verification': (context) {
          final email =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return OtpVerificationScreen(userEmail: email);
        },
        '/id_upload': (context) {
          final email =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return IdUploadScreen(userEmail: email);
        },
        '/cdl_upload': (context) {
          final email =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return CdlUploadScreen(userEmail: email);
        },
        '/home': (context) => const MainShell(),
        '/profile': (context) => const ProfileScreen(),
        '/load_board': (context) => const LoadBoardScreen(),
        '/customer_support': (context) => const CustomerSupportScreen(),
        '/load_details': (context) {
          final load = ModalRoute.of(context)?.settings.arguments as Load?;
          if (load == null) return const LoadBoardScreen();
          return LoadDetailsScreen(load: load);
        },
        '/shipment_detail': (context) {
          final shipment =
              ModalRoute.of(context)?.settings.arguments as Shipment?;
          return ShipmentDetailScreen(shipment: shipment);
        },
        '/vehicle_registration': (context) {
          final isEditing =
              ModalRoute.of(context)?.settings.arguments as bool? ?? false;
          return VehicleRegistrationScreen(isEditing: isEditing);
        },
        '/fuel_log': (context) => const FuelLogScreen(),
        '/stats': (context) => const StatsScreen(),
        '/search': (context) => const SearchScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/order_history': (context) => const OrderHistoryScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/business_profile': (context) => const BusinessProfileScreen(),
      },
    );
  }
}
