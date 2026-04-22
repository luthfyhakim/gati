import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/data/repositories/activity_repository.dart';
import 'app/data/repositories/auth_repository.dart';
import 'app/data/services/activity_service.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/sport_gear_service.dart';
import 'app/data/services/storage_service.dart';
import 'app/data/services/tracking_service.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final storage = await Get.putAsync<StorageService>(
    () => StorageService().init(),
    permanent: true,
  );

  Get.put<AuthService>(AuthService(storage), permanent: true);
  Get.put<ActivityService>(ActivityService(storage), permanent: true);
  Get.put<TrackingService>(TrackingService(), permanent: true);
  Get.put<SportGearService>(SportGearService(), permanent: true);
  Get.put<AuthRepository>(AuthRepository(Get.find()), permanent: true);
  Get.put<ActivityRepository>(ActivityRepository(Get.find()), permanent: true);

  runApp(const GatiApp());
}

class GatiApp extends StatelessWidget {
  const GatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gati',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4DB6AC)),
        useMaterial3: true,
      ),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
