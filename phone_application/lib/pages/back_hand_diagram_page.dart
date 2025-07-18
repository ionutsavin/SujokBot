import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phone_application/config/app_config.dart';
import 'package:photo_view/photo_view.dart';
import 'package:phone_application/models/back_hand_zone.dart';
import 'package:phone_application/services/zone_service.dart';
import 'package:phone_application/mixins/camera_functionality_mixin.dart';

class BackHandDiagramPage extends StatefulWidget {
  final List<String>? backZones;
  const BackHandDiagramPage({super.key, this.backZones});

  @override
  State<BackHandDiagramPage> createState() => _BackHandDiagramPageState();
}

class _BackHandDiagramPageState extends State<BackHandDiagramPage>
    with CameraFunctionality {
  Set<String> activeZones = {};
  Map<String, String> zoneDescriptions = {};
  Map<String, Color> zoneColors = {};
  StreamSubscription<Map<String, String>?>? _zoneSubscription;

  @override
  String get handType => 'back_hand';
  
  @override
  String get defaultAssetPath => 'assets/back_hand.png';
  
  @override
  String get scannerAssetPath => 'assets/back_hand_removebg.png';
  
  @override
  void initState() {
    super.initState();
    if (widget.backZones != null) {
      for (String zone in widget.backZones!) {
        _toggleZone(zone);
      }
    }
    _zoneSubscription = ZoneService().zoneStream.listen((zoneInfo) {
      if (zoneInfo != null) {
        _toggleZone(zoneInfo['zone']);
      }
    });
  }

  @override
  void dispose() {
    _zoneSubscription?.cancel();
    super.dispose();
  }

  void _toggleZone(String? zone) {
    if (zone == null) return;
    
    setState(() {
      if (activeZones.contains(zone)) {
        activeZones.remove(zone);
        zoneDescriptions.remove(zone);
        zoneColors.remove(zone);
      } else {
        activeZones.add(zone);
        Map<String, dynamic>? zoneData = BackHandZones.getZones()[zone];
        if (zoneData != null) {
          zoneColors[zone] = zoneData['color'];
          zoneDescriptions[zone] = zoneData['description'] ?? 'No description available';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: SelectableText('Zone $zone not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }
  void showPopupInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          child: AlertDialog(
            title: SelectableText('Detailed Finger Information'),
            content: SizedBox(
              width: double.maxFinite,
              child: PhotoView(
                imageProvider: const AssetImage('assets/back_hand/finger_detailed_info.png'),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showPopupInfo(context);
                        },
                        icon: const Icon(Icons.info_outline, color: Colors.white),
                        label: const Text('View detailed finger information', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          backgroundColor: Colors.blue.shade400,
                        ),
                      ),
                      FutureBuilder<bool>(
                        future: AppConfig.isAndroidPhysicalDevice(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasData && snapshot.data!) {
                            return buildCameraControls();
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),
                      buildImageView(
                        overlayWidgets: activeZones.map((zone) => GestureDetector(
                          onTap: () => _toggleZone(zone),
                          child: CustomPaint(
                            size: const Size(300, 350),
                            painter: BackHandZoneHighlightPainter(zone, zoneColors[zone] ?? Colors.red),
                          ),
                        )).toList(),
                      ),

                      if (activeZones.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...activeZones.map((zone) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        margin: const EdgeInsets.only(top: 3),
                                        decoration: BoxDecoration(
                                          color: zoneColors[zone],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SelectableText(
                                          "${BackHandZones.getZones()[zone]?['name'] ?? zone}: ${zoneDescriptions[zone] ?? 'No description'}",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.grey.shade100,
          child: SizedBox(
            height: 100,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: BackHandZones.getZones().entries.map((entry) {
                  bool isActive = activeZones.contains(entry.key);
                  return GestureDetector(
                    onTap: () {
                      _toggleZone(entry.key);
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: entry.value['color'],
                        borderRadius: BorderRadius.circular(8),
                        border: isActive 
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        entry.value['name'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: isActive
                            ? FontWeight.bold 
                            : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),  
          ),
        ),
      ],
    );
  }
}

class BackHandZoneHighlightPainter extends CustomPainter {
  final String zone;
  final Color color;
  final void Function(String zone)? onZoneTap;
  Path? _zonePath;
  
  BackHandZoneHighlightPainter(this.zone, this.color, {this.onZoneTap});
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    switch (zone) {
      case 'base_index_finger':
        final baseIndexPath = Path()
          ..moveTo(centerX + 17, centerY - 52)
          ..lineTo(centerX + 35, centerY - 48)
          ..lineTo(centerX + 30, centerY - 19)
          ..lineTo(centerX + 12, centerY - 25)
          ..close();
        _zonePath = baseIndexPath;
        canvas.drawPath(baseIndexPath, paint);
        break;

      case 'middle_index_finger':
        final middleIndexPath = Path()
          ..moveTo(centerX + 22, centerY - 78)
          ..lineTo(centerX + 35, centerY - 76)
          ..lineTo(centerX + 35, centerY - 50)
          ..lineTo(centerX + 17, centerY - 53)
          ..close();
        _zonePath = middleIndexPath;
        canvas.drawPath(middleIndexPath, paint);
        break;

      case 'tip_index_finger':
        final tipIndexPath = Path()
          ..moveTo(centerX + 23, centerY - 95)
          ..lineTo(centerX + 37, centerY - 95)
          ..lineTo(centerX + 36, centerY - 77)
          ..lineTo(centerX + 22, centerY - 79)
          ..close();
        _zonePath = tipIndexPath;
        canvas.drawPath(tipIndexPath, paint);
        break;

      case 'base_middle_finger':
        final baseMiddlePath = Path()
          ..moveTo(centerX - 10, centerY - 52)
          ..lineTo(centerX + 5, centerY - 53)
          ..lineTo(centerX + 8, centerY - 26)
          ..lineTo(centerX - 15, centerY - 25)
          ..close();
        _zonePath = baseMiddlePath;
        canvas.drawPath(baseMiddlePath, paint);
        break;
      
      case 'middle_middle_finger':
        final middleMiddlePath = Path()
          ..moveTo(centerX - 12, centerY - 88)
          ..lineTo(centerX + 3, centerY - 89)
          ..lineTo(centerX + 5, centerY - 54)
          ..lineTo(centerX - 10, centerY - 55)
          ..close();
        _zonePath = middleMiddlePath;
        canvas.drawPath(middleMiddlePath, paint);
        break;

      case 'tip_middle_finger':
        final tipMiddlePath = Path()
          ..moveTo(centerX - 12, centerY - 107)
          ..lineTo(centerX + 3, centerY - 107)
          ..lineTo(centerX + 3, centerY - 90)
          ..lineTo(centerX - 12, centerY - 90)
          ..close();
        _zonePath = tipMiddlePath;
        canvas.drawPath(tipMiddlePath, paint);
        break;

      case 'base_ring_finger':
        final baseRingPath = Path()
          ..moveTo(centerX - 42, centerY - 45)
          ..lineTo(centerX - 23, centerY - 49)
          ..lineTo(centerX - 16, centerY - 25)
          ..lineTo(centerX - 35, centerY - 20)
          ..close();
        _zonePath = baseRingPath;
        canvas.drawPath(baseRingPath, paint);
        break;

      case 'middle_ring_finger':
        final middleRingPath = Path()
          ..moveTo(centerX - 44, centerY - 76)
          ..lineTo(centerX - 30, centerY - 79)
          ..lineTo(centerX - 23, centerY - 50)
          ..lineTo(centerX - 42, centerY - 46)
          ..close();
        _zonePath = middleRingPath;
        canvas.drawPath(middleRingPath, paint);
        break;

      case 'tip_ring_finger':
        final tipRingPath = Path()
          ..moveTo(centerX - 50, centerY - 96)
          ..lineTo(centerX - 34, centerY - 99)
          ..lineTo(centerX - 30, centerY - 80)
          ..lineTo(centerX - 46, centerY - 77)
          ..close();
        _zonePath = tipRingPath;
        canvas.drawPath(tipRingPath, paint);
        break;
      
      case 'base_little_finger':
        final baseLittlePath = Path()
          ..moveTo(centerX - 62, centerY - 13)
          ..lineTo(centerX - 47, centerY - 23)
          ..lineTo(centerX - 40, centerY - 5)
          ..lineTo(centerX - 55, centerY + 10)
          ..close();
        _zonePath = baseLittlePath;
        canvas.drawPath(baseLittlePath, paint);
        break;

      case 'middle_little_finger':
        final middleLittlePath = Path()
          ..moveTo(centerX - 68, centerY - 30)
          ..lineTo(centerX - 57, centerY - 40)
          ..lineTo(centerX - 47, centerY - 25)
          ..lineTo(centerX - 62, centerY - 15)
          ..close();
        _zonePath = middleLittlePath;
        canvas.drawPath(middleLittlePath, paint);
        break;

      case 'tip_little_finger':
        final tipLittlePath = Path()
          ..moveTo(centerX - 76, centerY - 50)
          ..lineTo(centerX - 64, centerY - 57)
          ..lineTo(centerX - 57, centerY - 40)
          ..lineTo(centerX - 68, centerY - 32)
          ..close();
        _zonePath = tipLittlePath;
        canvas.drawPath(tipLittlePath, paint);
        break;
    }
  }

  @override
  bool hitTest(Offset position) {
    if (_zonePath != null && _zonePath!.contains(position)) {
      onZoneTap?.call(zone);
      return true;
    }
    return false;
  }
  
  @override
  bool shouldRepaint(BackHandZoneHighlightPainter oldDelegate) {
    return zone != oldDelegate.zone || color != oldDelegate.color;
  }
}