import 'package:flutter/material.dart';
import 'package:map_app/Screens/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

void requestLocationPermission() async {
  PermissionStatus permission = await Permission.location.request();
  if (permission != PermissionStatus.granted) {
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    requestLocationPermission();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialRoute: '/',
      routes: {
        '/' : (context) => Home_Screen(),
        // '/result' : (context) => MapScreen(),
      },
    );
  }
}
