import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/posture_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PostureProvider _postureProvider;
  bool _isScanning = false;
  List<BluetoothDevice> _availableDevices = [];

  // إعدادات التنبيهات (صوت واهتزاز)
  bool _enableSound = false;
  bool _enableVibration = true;

  @override
  void initState() {
    super.initState();
    _postureProvider = context.read<PostureProvider>();
  }

  Future<void> _scanAndConnect() async {
    setState(() {
      _isScanning = true;
      _availableDevices = [];
    });

    try {
      final devices = await _postureProvider.bleService.scanForDevices();
      setState(() {
        _availableDevices = devices;
        _isScanning = false;
      });

      if (_availableDevices.isEmpty) {
        _showSnackBar('لم يتم العثور على أجهزة بلوتوث');
        return;
      }

      _showDeviceSelectionDialog();
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showSnackBar('خطأ في البحث: $e');
    }
  }

  void _showDeviceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('اختر الحزام الذكي', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true, // مهم جداً لمنع انهيار الشاشة
            itemCount: _availableDevices.length,
            itemBuilder: (context, index) {
              final device = _availableDevices[index];
              // استخدام اسم الجهاز أو المعرف الخاص به
              final deviceName = device.remoteId.str; 
              
              return ListTile(
                title: const Text('جهاز حزام الوضعية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(deviceName, style: const TextStyle(color: Colors.grey)),
                onTap: () async {
                  Navigator.pop(context);
                  await _connectToDevice(device);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _showSnackBar('جاري الاتصال بالحزام...');
    final success = await _postureProvider.bleService.connectToDevice(device);

    if (success) {
      _showSnackBar('تم الاتصال بنجاح!');
      setState(() {});
    } else {
      _showSnackBar('فشل الاتصال بالحزام');
    }
  }

  void _disconnect() async {
    await _postureProvider.bleService.disconnect();
    _showSnackBar('تم قطع الاتصال');
    setState(() {});
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF29293F),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // خلفية داكنة صناعية
      appBar: AppBar(
        title: const Text('لوحة تحكم حزام الوضعية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2C),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<PostureProvider>(
        builder: (context, postureProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بطاقة حالة الاتصال بالبلوتوث
                Card(
                  color: const Color(0xFF1E1E2C),
                  elevation: 8,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: postureProvider.bleService.isConnected,
                          builder: (context, isConnected, _) {
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: isConnected ? Colors.greenAccent : Colors.redAccent,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: isConnected ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      isConnected ? 'متصل بالحزام' : 'غير متصل',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isConnected ? Colors.greenAccent : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                isConnected
                                    ? ElevatedButton.icon(
                                        onPressed: _disconnect,
                                        icon: const Icon(Icons.bluetooth_disabled, color: Colors.white),
                                        label: const Text('قطع الاتصال', style: TextStyle(color: Colors.white, fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent.withOpacity(0.8),
                                          minimumSize: const Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: _isScanning ? null : _scanAndConnect,
                                        icon: _isScanning 
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.bluetooth_searching, color: Colors.white),
                                        label: Text(_isScanning ? 'جاري البحث...' : 'البحث عن الحزام', style: const TextStyle(color: Colors.white, fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          minimumSize: const Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // بطاقة الإعدادات (تفضيلات الهاتف)
                Card(
                  color: const Color(0xFF1E1E2C),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إعدادات التنبيهات (في الهاتف)', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                        const Divider(color: Colors.white24),
                        SwitchListTile(
                          title: const Text('تفعيل الرنين عند الانحناء', style: TextStyle(color: Colors.white)),
                          activeColor: Colors.blueAccent,
                          value: _enableSound,
                          onChanged: (bool value) {
                            setState(() {
                              _enableSound = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('تفعيل الاهتزاز / الإشعارات', style: TextStyle(color: Colors.white)),
                          activeColor: Colors.blueAccent,
                          value: _enableVibration,
                          onChanged: (bool value) {
                            setState(() {
                              _enableVibration = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // بطاقة الإحصائيات الواردة من قاعدة البيانات
                Card(
                  color: const Color(0xFF1E1E2C),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('إحصائيات انحناء الظهر اليوم', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('عدد التنبيهات', postureProvider.getTodayAlertCount().toString(), Colors.orangeAccent),
                            _buildStatColumn('ساعة الذروة', postureProvider.getPeakHour(), Colors.cyanAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // تصميم مصغر لعرض الأرقام والإحصائيات
  Widget _buildStatColumn(String title, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
