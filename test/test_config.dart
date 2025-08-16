import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up common test configuration for all tests
void setupTestConfiguration() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Mock the path provider channel for Hive
  const MethodChannel pathProviderChannel = 
      MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (MethodCall methodCall) async {
    return '.';
  });
  
  // Mock the path provider for iOS
  const MethodChannel pathProviderIOS = 
      MethodChannel('plugins.flutter.io/path_provider_ios');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderIOS, (MethodCall methodCall) async {
    return '.';
  });
  
  // Mock device info plugin
  const MethodChannel deviceInfoChannel = 
      MethodChannel('dev.fluttercommunity.plus/device_info');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(deviceInfoChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'getDeviceInfo') {
      return <String, dynamic>{
        'name': 'Test Device',
        'model': 'Test Model',
        'systemName': 'iOS',
        'systemVersion': '16.0',
        'identifierForVendor': 'test-device-id',
        'isPhysicalDevice': false,
      };
    }
    return null;
  });
}