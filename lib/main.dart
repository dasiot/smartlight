import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

// ══════════════════════════════════════════════════════════════
//  THEME NOTIFIER
// ══════════════════════════════════════════════════════════════
class ThemeNotifier extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

final themeNotifier = ThemeNotifier();

// ══════════════════════════════════════════════════════════════
//  APP ROOT
// ══════════════════════════════════════════════════════════════
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    themeNotifier.removeListener(() => setState(() {}));
    super.dispose();
  }

  // ── Dark theme ──
  ThemeData get _dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        cardColor: const Color(0xFF161B22),
        dividerColor: Colors.white12,
      );

  // ── Light theme ──
  ThemeData get _light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        cardColor: Colors.white,
        dividerColor: Colors.black12,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 LED Control',
      debugShowCheckedModeBanner: false,
      theme: _light,
      darkTheme: _dark,
      themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SPLASH / START SCREEN
// ══════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _glowAnim;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _scaleAnim = CurvedAnimation(
        parent: _logoCtrl, curve: Curves.elasticOut);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));
    _fadeAnim = CurvedAnimation(
        parent: _fadeCtrl, curve: Curves.easeIn);

    // sequence: logo bounces in → text+button fade in
    _logoCtrl.forward().then((_) => _fadeCtrl.forward());
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.isDark;
    final bg1 = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F4FF);
    final bg2 = isDark ? const Color(0xFF1A237E) : const Color(0xFFBBCCFF);
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [

              // ── Theme toggle top right ──
              Positioned(
                top: 12, right: 16,
                child: _ThemeToggle(),
              ),

              // ── Main content ──
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ── Animated logo ──
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, __) => Container(
                          width: 130, height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0)
                                    .withOpacity(0.5 * _glowAnim.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lightbulb,
                            size: 65,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── App name ──
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(children: [
                        Text(
                          "ESP32 LED Control",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Control your LED via BLE & WiFi",
                          style: TextStyle(
                            color: textColor.withOpacity(0.55),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Feature pills ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _featurePill(
                                Icons.bluetooth, "Bluetooth", Colors.blue),
                            const SizedBox(width: 10),
                            _featurePill(
                                Icons.wifi, "WiFi", Colors.teal),
                          ],
                        ),

                        const SizedBox(height: 52),

                        // ── Start button ──
                        SizedBox(
                          width: 220,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _goToHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFF1565C0).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  "Get Started",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Quit button ──
                        TextButton.icon(
                          onPressed: () => SystemNavigator.pop(),
                          icon: Icon(Icons.exit_to_app,
                              color: textColor.withOpacity(0.45), size: 18),
                          label: Text(
                            "Exit",
                            style: TextStyle(
                              color: textColor.withOpacity(0.45),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              // ── Version tag bottom ──
              Positioned(
                bottom: 16,
                left: 0, right: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    "v1.0.0",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withOpacity(0.25),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String label, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════
//  THEME TOGGLE WIDGET (reused in both screens)
// ══════════════════════════════════════════════════════════════
class _ThemeToggle extends StatefulWidget {
  @override
  State<_ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<_ThemeToggle> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.isDark;
    return GestureDetector(
      onTap: () => themeNotifier.toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 70, height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: isDark
              ? const Color(0xFF1C2333)
              : const Color(0xFFE3EAFF),
          border: Border.all(
            color: isDark
                ? Colors.white24
                : const Color(0xFF1565C0).withOpacity(0.3),
          ),
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: isDark ? 4 : 36,
            top: 4,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1565C0)
                    : Colors.amber,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.blue : Colors.amber)
                        .withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HOME PAGE
// ══════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  // ── BLE UUIDs ──
  static const String _serviceUUID =
      "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String _charUUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // ── WiFi ──
  static const String _espIP       = "192.168.4.1";
  static const String _hotspotSSID = "ESP32_LED_Control";
  static const String _hotspotPass = "12345678";
  String get _ledOnUrl  => "http://$_espIP/led/on";
  String get _ledOffUrl => "http://$_espIP/led/off";
  String get _statusUrl => "http://$_espIP/";

  // ── BLE state ──
  final Map<String, ScanResult> _scanMap = {};
  List<ScanResult> get _scanList => _scanMap.values.toList()
    ..sort((a, b) => b.rssi.compareTo(a.rssi));
  BluetoothDevice?         _bleDevice;
  BluetoothCharacteristic? _bleCh;
  bool _bleScanning   = false;
  bool _bleConnected  = false;
  bool _bleConnecting = false;
  bool _btPermission  = false;

  // ── WiFi state ──
  bool _wifiConnected  = false;
  bool _wifiConnecting = false;

  // ── LED ──
  bool _ledOn = false;

  // ── UI ──
  String _status = "Choose a connection type below";
  late AnimationController _pulse;
  late Animation<double>   _pulseAnim;
  StreamSubscription<List<ScanResult>>?        _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  Timer? _debounce;

  bool get _anyConnected => _bleConnected || _wifiConnected;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.92, end: 1.08).animate(_pulse);
    themeNotifier.addListener(_rebuild);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkBtPermission());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scanSub?.cancel();
    _connSub?.cancel();
    _debounce?.cancel();
    themeNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  // ══════════════════════════════════════════════════════
  //  PERMISSIONS
  // ══════════════════════════════════════════════════════
  Future<void> _checkBtPermission() async {
    if (Platform.isIOS) {
      final s = await Permission.bluetooth.status;
      setState(() => _btPermission = s.isGranted);
      return;
    }
    final scan    = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    setState(() =>
        _btPermission = scan.isGranted && connect.isGranted);
  }

  Future<void> _requestBtPermission() async {
    if (Platform.isIOS) {
      final s = await Permission.bluetooth.request();
      setState(() => _btPermission = s.isGranted);
      return;
    }
    final r = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    final ok =
        (r[Permission.bluetoothScan]?.isGranted    ?? false) &&
        (r[Permission.bluetoothConnect]?.isGranted ?? false);
    setState(() => _btPermission = ok);
    if (!ok) openAppSettings();
  }

  // ══════════════════════════════════════════════════════
  //  BLE
  // ══════════════════════════════════════════════════════
  void _bleScan() async {
    if (!_btPermission) {
      await _requestBtPermission();
      if (!_btPermission) return;
    }
    if (_bleScanning) {
      await FlutterBluePlus.stopScan();
      return;
    }
    final adapter = await FlutterBluePlus.adapterState.first;
    if (adapter != BluetoothAdapterState.on) {
      setState(() => _status = "Please turn on Bluetooth.");
      return;
    }
    setState(() {
      _scanMap.clear();
      _bleScanning = true;
      _status = "Scanning for ESP32...";
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
      androidScanMode: AndroidScanMode.lowLatency,
      androidUsesFineLocation: false,
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        _scanMap[r.device.remoteId.toString()] = r;
      }
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() {});
      });
      final esp = results.where((r) =>
          r.device.platformName.toLowerCase().contains('esp32'));
      if (esp.isNotEmpty && !_bleConnecting && !_bleConnected) {
        FlutterBluePlus.stopScan();
        _bleConnect(esp.first.device);
      }
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning && mounted) {
        setState(() {
          _bleScanning = false;
          _status = _scanMap.isEmpty
              ? "No BLE devices found. Try again."
              : "Found ${_scanMap.length} device(s).";
        });
      }
    });
  }

  Future<void> _bleConnect(BluetoothDevice device) async {
    if (_bleConnecting) return;
    setState(() {
      _bleConnecting = true;
      _status = "Connecting via BLE...";
    });
    await FlutterBluePlus.stopScan();
    try {
      await device.connect(
          timeout: const Duration(seconds: 8), autoConnect: false);
      _connSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected && mounted) {
          setState(() {
            _bleConnected  = false;
            _bleDevice     = null;
            _bleCh         = null;
            if (!_wifiConnected) _ledOn = false;
            _status = "BLE disconnected.";
          });
        }
      });
      await device.requestMtu(512);
      for (var svc in await device.discoverServices()) {
        if (svc.uuid.toString().toLowerCase() ==
            _serviceUUID.toLowerCase()) {
          for (var ch in svc.characteristics) {
            if (ch.uuid.toString().toLowerCase() ==
                _charUUID.toLowerCase()) {
              if (mounted) {
                setState(() {
                  _bleDevice     = device;
                  _bleCh         = ch;
                  _bleConnected  = true;
                  _bleConnecting = false;
                  _status = "BLE connected: ${device.platformName} ✓";
                });
              }
              return;
            }
          }
        }
      }
      await device.disconnect();
      if (mounted) setState(() {
        _bleConnecting = false;
        _status = "ESP32 service not found.";
      });
    } catch (_) {
      if (mounted) setState(() {
        _bleConnecting = false;
        _status = "BLE connection failed. Try again.";
      });
    }
  }

  Future<void> _bleDisconnect() async {
    await _bleDevice?.disconnect();
    setState(() {
      _bleConnected  = false;
      _bleDevice     = null;
      _bleCh         = null;
      if (!_wifiConnected) _ledOn = false;
      _status = "BLE disconnected.";
    });
  }

  // ══════════════════════════════════════════════════════
  //  WIFI
  // ══════════════════════════════════════════════════════
  Future<void> _wifiConnect() async {
    setState(() {
      _wifiConnecting = true;
      _status = "Connecting to ESP32 hotspot...";
    });
    try {
      final resp = await http
          .get(Uri.parse(_statusUrl))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        setState(() {
          _wifiConnected  = true;
          _wifiConnecting = false;
          _status = "WiFi connected: $_espIP ✓";
        });
      } else {
        setState(() {
          _wifiConnecting = false;
          _status = "ESP32 responded with error.";
        });
      }
    } catch (_) {
      setState(() {
        _wifiConnecting = false;
        _status = "WiFi failed. Connected to '$_hotspotSSID'?";
      });
    }
  }

  void _wifiDisconnect() {
    setState(() {
      _wifiConnected = false;
      if (!_bleConnected) _ledOn = false;
      _status = "WiFi disconnected.";
    });
  }

  // ══════════════════════════════════════════════════════
  //  LED TOGGLE
  // ══════════════════════════════════════════════════════
  Future<void> _toggleLED() async {
    if (!_anyConnected) return;
    final next = !_ledOn;
    bool ok = false;

    if (_bleConnected && _bleCh != null) {
      try {
        await _bleCh!.write(next ? [0x31] : [0x30],
            withoutResponse: false);
        ok = true;
      } catch (_) {
        setState(() => _status = "BLE write failed.");
      }
    }

    if (_wifiConnected) {
      try {
        final r = await http
            .get(Uri.parse(next ? _ledOnUrl : _ledOffUrl))
            .timeout(const Duration(seconds: 3));
        if (r.statusCode == 200) ok = true;
      } catch (_) {
        setState(() => _status = "WiFi write failed.");
      }
    }

    if (ok) {
      setState(() {
        _ledOn  = next;
        _status = "LED is ${next ? 'ON 💡' : 'OFF'}";
      });
      HapticFeedback.lightImpact();
    }
  }

  // ══════════════════════════════════════════════════════
  //  QUIT DIALOG
  // ══════════════════════════════════════════════════════
  Future<void> _confirmQuit() async {
    final isDark = themeNotifier.isDark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1C2333) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text("Quit App",
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to exit?",
          style: TextStyle(
              color: isDark
                  ? Colors.white70
                  : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Quit"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _bleDevice?.disconnect();
      SystemNavigator.pop();
    }
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.isDark;
    final bg = isDark
        ? const Color(0xFF0D1117)
        : const Color(0xFFF0F4FF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          _header(isDark),
          _statusBar(isDark),
          _anyConnected
              ? _ledScreen(isDark)
              : Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _connectionCards(isDark),
                      if (_bleScanning || _scanMap.isNotEmpty)
                        _scanResults(isDark),
                    ]),
                  ),
                ),
        ]),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _header(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1565C0).withOpacity(0.85),
                  const Color(0xFF0D47A1).withOpacity(0.4),
                ]
              : [
                  const Color(0xFF1565C0),
                  const Color(0xFF42A5F5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        // Connection icon
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _bleScanning ? _pulseAnim.value : 1.0,
            child: Stack(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: _bleConnected && _wifiConnected
                        ? Colors.tealAccent
                        : _bleConnected
                            ? Colors.greenAccent
                            : _wifiConnected
                                ? Colors.tealAccent
                                : Colors.white54,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _bleConnected
                      ? Icons.bluetooth_connected
                      : _wifiConnected
                          ? Icons.wifi
                          : Icons.device_hub,
                  color: _bleConnected
                      ? Colors.greenAccent
                      : _wifiConnected
                          ? Colors.tealAccent
                          : Colors.white70,
                  size: 24,
                ),
              ),
              if (_bleConnected && _wifiConnected)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: Colors.tealAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF1565C0), width: 2),
                    ),
                    child: const Icon(Icons.wifi,
                        size: 9, color: Colors.black),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ESP32 LED Control",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(
                _bleConnected && _wifiConnected
                    ? "BLE + WiFi connected"
                    : _bleConnected
                        ? "BLE: ${_bleDevice?.platformName ?? 'ESP32'}"
                        : _wifiConnected
                            ? "WiFi: $_espIP"
                            : "Not connected",
                style: TextStyle(
                  color: _anyConnected
                      ? Colors.greenAccent
                      : Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Theme toggle
        _ThemeToggle(),
        const SizedBox(width: 4),

        // More menu (disconnect + quit)
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70, size: 22),
          color: isDark ? const Color(0xFF1C2333) : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'ble')   _bleDisconnect();
            if (v == 'wifi')  _wifiDisconnect();
            if (v == 'both')  { _bleDisconnect(); _wifiDisconnect(); }
            if (v == 'quit')  _confirmQuit();
          },
          itemBuilder: (_) => [
            if (_bleConnected)
              PopupMenuItem(
                  value: 'ble',
                  child: _menuItem(
                      Icons.bluetooth_disabled, "Disconnect BLE",
                      Colors.redAccent)),
            if (_wifiConnected)
              PopupMenuItem(
                  value: 'wifi',
                  child: _menuItem(
                      Icons.wifi_off, "Disconnect WiFi",
                      Colors.redAccent)),
            if (_bleConnected && _wifiConnected)
              PopupMenuItem(
                  value: 'both',
                  child: _menuItem(
                      Icons.link_off, "Disconnect Both",
                      Colors.redAccent)),
            const PopupMenuDivider(),
            PopupMenuItem(
                value: 'quit',
                child: _menuItem(
                    Icons.exit_to_app, "Quit App",
                    Colors.orange)),
          ],
        ),
      ]),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) =>
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ]);

  // ── Status bar ───────────────────────────────────────────────
  Widget _statusBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(children: [
        Icon(
          _anyConnected ? Icons.check_circle : Icons.info_outline,
          color: _anyConnected ? Colors.greenAccent : Colors.blueGrey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_status,
              style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : Colors.black54,
                  fontSize: 12)),
        ),
        if (_bleScanning || _bleConnecting || _wifiConnecting)
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.orangeAccent),
          ),
      ]),
    );
  }

  // ── Connection cards ─────────────────────────────────────────
  Widget _connectionCards(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _label("CONNECTION TYPE", isDark),
        const SizedBox(height: 10),

        // BLE card
        _ConnCard(
          isDark:         isDark,
          icon:           Icons.bluetooth,
          iconColor:      _bleConnected ? Colors.greenAccent : Colors.blue,
          title:          "Bluetooth (BLE)",
          subtitle:       _bleConnected
              ? "Connected to ${_bleDevice?.platformName ?? 'ESP32'}"
              : "Scan and connect wirelessly over BLE",
          isConnected:    _bleConnected,
          isLoading:      _bleConnecting || _bleScanning,
          accentColor:    Colors.blue,
          connectedColor: Colors.greenAccent,
          actionLabel:    _bleConnected
              ? "Disconnect"
              : _bleScanning ? "Stop" : "Scan",
          onAction: _bleConnected ? _bleDisconnect : _bleScan,
          extra: !_bleConnected && !_btPermission
              ? _smallBtn("Allow", Colors.orange, _requestBtPermission, isDark)
              : null,
        ),

        const SizedBox(height: 10),

        // WiFi card
        _ConnCard(
          isDark:         isDark,
          icon:           Icons.wifi,
          iconColor:      _wifiConnected ? Colors.greenAccent : Colors.teal,
          title:          "WiFi Hotspot",
          subtitle:       _wifiConnected
              ? "Connected to $_hotspotSSID ($_espIP)"
              : "Connect phone to '$_hotspotSSID' then tap Connect",
          isConnected:    _wifiConnected,
          isLoading:      _wifiConnecting,
          accentColor:    Colors.teal,
          connectedColor: Colors.greenAccent,
          actionLabel:    _wifiConnected ? "Disconnect" : "Connect",
          onAction:       _wifiConnected ? _wifiDisconnect : _wifiConnect,
          extra:          null,
        ),

        // WiFi how-to steps
        if (!_wifiConnected) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(isDark ? 0.06 : 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.teal.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline,
                      color: Colors.teal, size: 15),
                  const SizedBox(width: 8),
                  Text("How to connect via WiFi",
                      style: TextStyle(
                          color: Colors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 10),
                _step("1", "Power on your ESP32", isDark),
                _step("2", "Phone Settings → WiFi", isDark),
                _step("3",
                    "Connect to  '$_hotspotSSID'  (password: $_hotspotPass)",
                    isDark),
                _step("4", "Come back and tap  Connect", isDark),
              ],
            ),
          ),
        ],

        // Both connected badge
        if (_bleConnected && _wifiConnected) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.tealAccent.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.link, color: Colors.tealAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "BLE + WiFi both active — commands sent over both.",
                  style: TextStyle(
                      color: Colors.tealAccent.withOpacity(0.85),
                      fontSize: 12),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  // ── BLE scan list ────────────────────────────────────────────
  Widget _scanResults(bool isDark) {
    final list = _scanList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        _label("BLE DEVICES FOUND", isDark),
        const SizedBox(height: 8),
        if (list.isEmpty && _bleScanning)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                  color: Colors.blue, strokeWidth: 2),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r     = list[i];
              final dev   = r.device;
              final name  = dev.platformName.isNotEmpty
                  ? dev.platformName : "Unknown";
              final isEsp = dev.platformName
                  .toLowerCase().contains('esp');
              final rssi  = r.rssi;
              final sigC  = rssi > -60
                  ? Colors.greenAccent
                  : rssi > -80
                      ? Colors.orangeAccent
                      : Colors.redAccent;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isEsp
                      ? const Color(0xFF1A237E).withOpacity(0.3)
                      : isDark
                          ? const Color(0xFF161B22)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isEsp
                        ? Colors.blue.withOpacity(0.4)
                        : isDark
                            ? Colors.white12
                            : Colors.black12,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    isEsp ? Icons.developer_board : Icons.bluetooth,
                    color: isEsp ? Colors.blue : Colors.blueGrey,
                  ),
                  title: Text(name,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: isEsp
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14)),
                  subtitle: Row(children: [
                    Icon(Icons.signal_cellular_alt,
                        size: 11, color: sigC),
                    const SizedBox(width: 4),
                    Text("$rssi dBm",
                        style: TextStyle(color: sigC, fontSize: 11)),
                  ]),
                  trailing: isEsp
                      ? _smallBtn(
                          "Connect", Colors.blue,
                          () => _bleConnect(dev), isDark)
                      : Icon(Icons.chevron_right,
                          color: isDark
                              ? Colors.white24
                              : Colors.black26),
                  onTap: _bleConnecting
                      ? null : () => _bleConnect(dev),
                ),
              );
            },
          ),
      ],
    );
  }

  // ── LED control screen ───────────────────────────────────────
  Widget _ledScreen(bool isDark) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Connection pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_bleConnected)
                _pill(Icons.bluetooth, "BLE", Colors.blue),
              if (_bleConnected && _wifiConnected)
                const SizedBox(width: 8),
              if (_wifiConnected)
                _pill(Icons.wifi, _espIP, Colors.teal),
            ],
          ),

          const SizedBox(height: 30),

          // Glowing bulb
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 155, height: 155,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ledOn
                  ? Colors.yellow.withOpacity(0.15)
                  : (isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.04)),
              boxShadow: _ledOn
                  ? [
                      BoxShadow(
                          color: Colors.yellow.withOpacity(0.55),
                          blurRadius: 60, spreadRadius: 18),
                      BoxShadow(
                          color: Colors.orange.withOpacity(0.25),
                          blurRadius: 100, spreadRadius: 28),
                    ]
                  : [],
              border: Border.all(
                color: _ledOn
                    ? Colors.yellow.withOpacity(0.6)
                    : (isDark
                        ? Colors.white12
                        : Colors.black12),
                width: 2,
              ),
            ),
            child: Icon(Icons.lightbulb,
                size: 78,
                color: _ledOn
                    ? Colors.yellow
                    : (isDark
                        ? Colors.white24
                        : Colors.black26)),
          ),

          const SizedBox(height: 24),
          Text(
            _ledOn ? "LED is ON" : "LED is OFF",
            style: TextStyle(
                color: _ledOn
                    ? Colors.yellow
                    : (isDark
                        ? Colors.white38
                        : Colors.black38),
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _bleConnected && _wifiConnected
                ? "Sending via BLE + WiFi"
                : _bleConnected
                    ? "Sending via BLE"
                    : "Sending via WiFi",
            style: TextStyle(
                color: isDark
                    ? Colors.white30
                    : Colors.black38,
                fontSize: 12),
          ),

          const SizedBox(height: 40),

          // Toggle switch
          GestureDetector(
            onTap: _toggleLED,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 140, height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                color: _ledOn
                    ? const Color(0xFFF9A825)
                    : (isDark
                        ? const Color(0xFF1E2A3A)
                        : const Color(0xFFDDE4F0)),
                boxShadow: [
                  BoxShadow(
                      color: _ledOn
                          ? Colors.orange.withOpacity(0.4)
                          : Colors.black.withOpacity(0.12),
                      blurRadius: 20, spreadRadius: 2)
                ],
                border: Border.all(
                    color: _ledOn
                        ? Colors.orange.withOpacity(0.6)
                        : (isDark
                            ? Colors.white12
                            : Colors.black12),
                    width: 2),
              ),
              child: Stack(children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  left: _ledOn ? 76 : 8,
                  top: 8,
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _ledOn ? Colors.white : Colors.blueGrey,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6)
                      ],
                    ),
                    child: Icon(
                      _ledOn
                          ? Icons.power_settings_new
                          : Icons.power_off,
                      color: _ledOn
                          ? Colors.orange
                          : Colors.white60,
                      size: 26,
                    ),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 14),
          Text(
            _ledOn ? "Tap to turn OFF" : "Tap to turn ON",
            style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black38,
                fontSize: 12),
          ),

          const SizedBox(height: 30),

          // Quit button on LED screen
          TextButton.icon(
            onPressed: _confirmQuit,
            icon: Icon(Icons.exit_to_app,
                color: isDark
                    ? Colors.white30
                    : Colors.black38,
                size: 16),
            label: Text("Quit",
                style: TextStyle(
                    color: isDark
                        ? Colors.white30
                        : Colors.black38,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _label(String t, bool isDark) => Text(t,
      style: TextStyle(
          color: isDark
              ? Colors.white38
              : Colors.black38,
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600));

  Widget _pill(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _smallBtn(
          String label, Color color, VoidCallback fn, bool isDark) =>
      GestureDetector(
        onTap: fn,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      );

  Widget _step(String n, String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20, height: 20,
              margin: const EdgeInsets.only(right: 10, top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withOpacity(0.25),
                border:
                    Border.all(color: Colors.teal.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(n,
                    style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: isDark
                          ? Colors.white60
                          : Colors.black54,
                      fontSize: 12)),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  REUSABLE CONNECTION CARD
// ══════════════════════════════════════════════════════════════
class _ConnCard extends StatelessWidget {
  final bool      isDark;
  final IconData  icon;
  final Color     iconColor;
  final String    title;
  final String    subtitle;
  final bool      isConnected;
  final bool      isLoading;
  final Color     accentColor;
  final Color     connectedColor;
  final String    actionLabel;
  final VoidCallback onAction;
  final Widget?   extra;

  const _ConnCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isConnected,
    required this.isLoading,
    required this.accentColor,
    required this.connectedColor,
    required this.actionLabel,
    required this.onAction,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(isDark ? 0.07 : 0.05)
            : (isDark ? const Color(0xFF161B22) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected
              ? connectedColor.withOpacity(0.4)
              : accentColor.withOpacity(isDark ? 0.2 : 0.3),
          width: 1.3,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected
                ? connectedColor.withOpacity(0.12)
                : accentColor.withOpacity(0.1),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: isConnected
                          ? connectedColor
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      color: isConnected
                          ? connectedColor.withOpacity(0.6)
                          : (isDark
                              ? Colors.white38
                              : Colors.black45),
                      fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        extra ??
            (isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.orangeAccent))
                : isConnected
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_rounded,
                            color: connectedColor, size: 20),
                        const SizedBox(width: 8),
                        _actionBtn("Disconnect",
                            Colors.redAccent, onAction),
                      ])
                    : _actionBtn(actionLabel, accentColor, onAction)),
      ]),
    );
  }

  static Widget _actionBtn(
          String label, Color color, VoidCallback fn) =>
      GestureDetector(
        onTap: fn,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      );
}