import Flutter
import UIKit
// AQUÍ VA EL CAMBIO 1: Importamos la librería nativa de Google Maps
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // AQUÍ VA EL CAMBIO 2: Inicializamos el motor con tu llave antes de que Flutter construya la UI
    GMSServices.provideAPIKey("AIzaSyAMvqpQ8QedNNSVrw4HQ9S0ss3EFU7rKkA")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}