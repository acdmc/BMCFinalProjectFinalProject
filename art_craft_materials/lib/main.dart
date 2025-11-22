// File: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:art_craft_materials/screens/auth_wrapper.dart';

import 'package:provider/provider.dart';
import 'package:art_craft_materials/providers/cart_provider.dart';

import 'package:google_fonts/google_fonts.dart';

const Color kRichBlack = Color (0xFF1D1F24);
const Color kDeepPink = Color(0xFFC2185B);
const Color kMediumPink = Color (0xFFF48FB1);
const Color kLightPink = Color (0xFFFFCDD2);
const Color kOffWhitePink = Color (0xFFFCE4EC);

void main() async {

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp( //
    options: DefaultFirebaseOptions.currentPlatform, //
  );

  runApp(const MyApp());

  FlutterNativeSplash.remove();
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final cartProvider = CartProvider();
            cartProvider.initialize(appId);
            return cartProvider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Art and Craft Materials',

        theme: ThemeData(

          colorScheme: ColorScheme.fromSeed(
            seedColor: kDeepPink,
            brightness: Brightness.light,
            primary: kDeepPink,
            onPrimary: Colors.white,
            secondary: kMediumPink,
            background: kOffWhitePink,
          ),
          useMaterial3: true,

          scaffoldBackgroundColor: kOffWhitePink,

          textTheme: GoogleFonts.latoTextTheme(
            Theme.of(context).textTheme,
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDeepPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            labelStyle: TextStyle(color: kDeepPink.withOpacity(0.8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kDeepPink, width: 2.0),
            ),
          ),

          cardTheme: CardThemeData(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            clipBehavior: Clip.antiAlias,
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: kRichBlack,
            elevation: 0,
            centerTitle: true,
          ),
        ),

        home: const AuthWrapper(),
      ),
    );
  }
}