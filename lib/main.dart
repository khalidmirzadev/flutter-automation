import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:process_run/shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Package Integration',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PackageIntegrationTool(),
    );
  }
}

class PackageIntegrationTool extends StatefulWidget {
  const PackageIntegrationTool({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PackageIntegrationToolState createState() => _PackageIntegrationToolState();
}

class _PackageIntegrationToolState extends State<PackageIntegrationTool> {
  String? selectedPath;
  String? apiKey;
  String log = '';

  Future<void> selectProject() async {
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      setState(() {
        selectedPath = path;
      });
    }
  }

  Future<void> addGoogleMapsPackage() async {
    if (selectedPath == null) {
      setState(() {
        log = 'Please select a Flutter project first.';
      });
      return;
    }

    final pubspecFile = File('$selectedPath/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      final lines = content.split('\n');

      // Check if the package already exists
      if (content.contains('google_maps_flutter')) {
        setState(() {
          log = 'google_maps_flutter is already added in pubspec.yaml.';
        });
        return;
      }

      // Locate the dependencies section
      int dependenciesIndex = lines.indexWhere((line) => line.trim() == 'dependencies:');
      if (dependenciesIndex == -1) {
        setState(() {
          log = 'Failed to locate dependencies section in pubspec.yaml.';
        });
        return;
      }

      // Add the package under dependencies
      lines.insert(dependenciesIndex + 1, '  google_maps_flutter: ^2.10.0');

      // Write the updated content back to the file
      await pubspecFile.writeAsString(lines.join('\n'));

      setState(() {
        log = 'Added google_maps_flutter to pubspec.yaml under dependencies.';
      });

      // Run flutter pub get
      final shell = Shell(workingDirectory: selectedPath);
      try {
        await shell.run('flutter pub get');
        setState(() {
          log += '\nSuccessfully ran flutter pub get.';
        });
      } catch (e) {
        setState(() {
          log += '\nFailed to run flutter pub get: $e';
        });
      }
    } else {
      setState(() {
        log = 'pubspec.yaml not found in the selected project.';
      });
    }
  }

  Future<void> configurePlatform(String? apiKey) async {
    if (selectedPath == null || apiKey == null) {
      setState(() {
        log = 'Please select a Flutter project and provide an API key first.';
      });
      return;
    }

    // Android Configuration
    final manifestPath = '$selectedPath/android/app/src/main/AndroidManifest.xml';
    final manifestFile = File(manifestPath);
    if (await manifestFile.exists()) {
      final content = await manifestFile.readAsString();
      if (!content.contains('<meta-data android:name="com.google.android.geo.API_KEY"')) {
        final updatedContent = content.replaceFirst(
          '</application>',
          '''
          <meta-data android:name="com.google.android.geo.API_KEY" android:value="$apiKey" />
          </application>
          ''',
        );
        await manifestFile.writeAsString(updatedContent);
        setState(() {
          log += '\nConfigured AndroidManifest.xml for Google Maps.';
        });
      } else {
        setState(() {
          log += '\nAndroidManifest.xml already configured for Google Maps.';
        });
      }
    }

    // iOS Configuration
    final plistPath = '$selectedPath/ios/Runner/Info.plist';
    final plistFile = File(plistPath);
    if (await plistFile.exists()) {
      final content = await plistFile.readAsString();
      if (!content.contains('<key>GMSApiKey</key>')) {
        final updatedContent = content.replaceFirst(
          '</dict>',
          '''
          <key>GMSApiKey</key>
          <string>$apiKey</string>
          </dict>
          ''',
        );
        await plistFile.writeAsString(updatedContent);
        setState(() {
          log += '\nConfigured Info.plist for Google Maps.';
        });
      }
    }
  }

  Future<void> injectGoogleMapsCode() async {
    if (selectedPath == null) {
      setState(() {
        log = 'Please select a Flutter project first.';
      });
      return;
    }

    final mainFile = File('$selectedPath/lib/main.dart');
    final mainDir = Directory('$selectedPath/lib');

    // Ensure the lib directory exists
    if (!await mainDir.exists()) {
      setState(() {
        log = 'The lib directory does not exist in the selected project.';
      });
      return;
    }

    // Create the main.dart file if it doesn't exist
    if (!await mainFile.exists()) {
      await mainFile.create(recursive: true);
    }

    // Google Maps Example Code
    const mainDartContent = '''
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GoogleMapScreen(),
    );
  }
}

class GoogleMapScreen extends StatefulWidget {
  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  late GoogleMapController mapController;

  final LatLng _initialPosition = const LatLng(37.7749, -122.4194); // San Francisco

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _centerMap() {
    mapController.animateCamera(
      CameraUpdate.newLatLng(_initialPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps Demo'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12.0,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerMap,
        child: Icon(Icons.center_focus_strong),
      ),
    );
  }
}
  ''';

    // Write the Google Maps code to main.dart
    try {
      await mainFile.writeAsString(mainDartContent);
      setState(() {
        log += '\nSuccessfully injected Google Maps code into main.dart.';
      });
    } catch (e) {
      setState(() {
        log += '\nFailed to write to main.dart: $e';
      });
    }
  }

  Future<void> runAppOnAndroid() async {
    if (selectedPath == null) {
      setState(() {
        log = 'Please select a Flutter project first.';
      });
      return;
    }

    final shell = Shell(workingDirectory: selectedPath);

    try {
      // Run the Flutter app on an Android device
      await shell.run(
        'flutter run -d emulator-5554',
      );

      setState(() {
        log += '\nRunning the app on an Android device or emulator.';
      });
    } catch (e) {
      setState(() {
        log += '\nFailed to run the app on Android: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Package Integration Tool')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: selectProject,
              child: const Text('Select Flutter Project'),
            ),
            if (selectedPath != null) Text('Selected Path: $selectedPath'),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => apiKey = value,
              decoration: const InputDecoration(labelText: 'Google Maps API Key'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: addGoogleMapsPackage,
              child: const Text('Add google_maps_flutter Package'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => configurePlatform(apiKey),
              child: const Text('Configure Platform Settings'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: injectGoogleMapsCode,
              child: const Text('Inject Google Maps Code'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: runAppOnAndroid,
              child: const Text('Run App on Android'),
            ),
            const Text(
              'Logs:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Text(log),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
