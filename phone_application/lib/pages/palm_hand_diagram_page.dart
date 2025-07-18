import 'dart:async';
import 'dart:ui';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';
import 'package:phone_application/models/palm_hand_zone.dart';
import 'package:phone_application/services/zone_service.dart';
import 'package:phone_application/mixins/camera_functionality_mixin.dart';
import 'package:phone_application/config/app_config.dart';

class PalmHandDiagramPage extends StatefulWidget {
  final List<String>? palmZones;
  const PalmHandDiagramPage({super.key, this.palmZones});

  @override
  State<PalmHandDiagramPage> createState() => _PalmHandDiagramPageState();
}

class _PalmHandDiagramPageState extends State<PalmHandDiagramPage> 
    with CameraFunctionality {
  Set<String> activeZones = {};
  Map<String, String> zoneDescriptions = {};
  Map<String, Color> zoneColors = {};
  StreamSubscription<Map<String, String>?>? _zoneSubscription;

  @override
  String get handType => 'palm';
  
  @override
  String get defaultAssetPath => 'assets/hand.png';
  
  @override
  String get scannerAssetPath => 'assets/hand_removebg.png';
  
  @override
  void initState() {
    super.initState();
    if (widget.palmZones != null) {
      for (String zone in widget.palmZones!) {
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
        Map<String, dynamic>? zoneData = PalmHandZones.getZones()[zone];
        if (zoneData != null) {
          zoneColors[zone] = zoneData['color'];
          zoneDescriptions[zone] = zoneData['description'] ?? 'No description available';
        } else{
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
  void showPopupInfo(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
            maxHeight: 600,
          ),
          child: AlertDialog(
            title: SelectableText(title),
            content: SizedBox(
              width: double.maxFinite,
              child: PhotoView(
                imageProvider: title == 'Detailed Palm Information'
                    ? const AssetImage('assets/palm/palm_detailed_info.png')
                    : title == 'Detailed Finger Information'
                        ? const AssetImage('assets/palm/finger_detailed_info.png')
                        : const AssetImage('assets/palm/palm_detailed_info.png'),
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                showPopupInfo(context, 'Detailed Palm Information');
                              },
                              icon: const Icon(Icons.info_outline, color: Colors.white),
                              label: const Text(
                                'View detailed palm information',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                backgroundColor: Colors.blue.shade400,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                showPopupInfo(context, 'Detailed Finger Information');
                              },
                              icon: const Icon(Icons.info_outline, color: Colors.white),
                              label: const Text(
                                'View detailed finger information',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                backgroundColor: Colors.blue.shade400,
                              ),
                            ),
                          ],
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
                            painter: ZoneHighlightPainter(zone, zoneColors[zone] ?? Colors.red),
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
                                          "${PalmHandZones.getZones()[zone]?['name'] ?? zone}: ${zoneDescriptions[zone] ?? 'No description'}",
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
                children: PalmHandZones.getZones().entries.map((entry) {
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

class ZoneHighlightPainter extends CustomPainter {
  final String zone;
  final Color color;
  final void Function(String zone)? onZoneTap;
  Path? _zonePath;
  
  ZoneHighlightPainter(this.zone, this.color, {this.onZoneTap});
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    switch (zone) {
      case 'central_palm':
      final centralPalmPath = Path()
        ..moveTo(centerX - 30, centerY - 14)
        ..quadraticBezierTo(
          centerX + 20, centerY - 20,
          centerX + 54, centerY + 40,
        )
        ..lineTo(centerX + 54, centerY + 40)
        ..lineTo(centerX + 35, centerY + 100)
        ..quadraticBezierTo(
          centerX + 10, centerY + 128,
          centerX - 28, centerY + 115,
        )
        ..quadraticBezierTo(
          centerX + 20, centerY + 50,
          centerX - 50, centerY + 35,
        )
        ..close();
      _zonePath = centralPalmPath;
      canvas.drawPath(centralPalmPath, paint);
      break;

    case 'thenar_eminence':
      final thenarPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(centerX - 39, centerY + 75),
          width: 66,
          height: 76,
        ));
      _zonePath = thenarPath;
      canvas.drawPath(thenarPath, paint);
      break;
        
      case 'base_thumb':
        final baseThumbPath = Path()
          ..moveTo(centerX - 90, centerY + 30)
          ..lineTo(centerX - 70, centerY + 12)
          ..lineTo(centerX - 48, centerY + 38)
          ..lineTo(centerX - 72, centerY + 60)
          ..close();
        _zonePath = baseThumbPath;
        canvas.drawPath(baseThumbPath, paint);
        break;
        
      case 'distal_thumb':
        final distalThumbPath = Path()
          ..moveTo(centerX - 108, centerY)
          ..quadraticBezierTo(
            centerX - 115, centerY - 25,
            centerX - 85, centerY - 10,
          )
          ..lineTo(centerX - 70, centerY + 10)
          ..quadraticBezierTo(
            centerX - 95, centerY + 35,
            centerX - 91, centerY + 25,
          )
          ..close();
        _zonePath = distalThumbPath;
        canvas.drawPath(distalThumbPath, paint);
        break;
        
      case 'base_index_finger':
        final baseIndexPath = Path()
          ..moveTo(centerX - 32, centerY - 39)
          ..lineTo(centerX - 12, centerY - 39)
          ..lineTo(centerX - 12, centerY - 13)
          ..lineTo(centerX - 32, centerY - 13)
          ..close();
        _zonePath = baseIndexPath;
        canvas.drawPath(baseIndexPath, paint);
        break;
        
      case 'middle_index_finger':
        final middleIndexPath = Path()
          ..moveTo(centerX - 32, centerY - 72)
          ..lineTo(centerX - 12, centerY - 72)
          ..lineTo(centerX - 12, centerY - 41)
          ..lineTo(centerX - 32, centerY - 41)
          ..close();
        _zonePath = middleIndexPath;
        canvas.drawPath(middleIndexPath, paint);
        break;
        
      case 'tip_index_finger':
        final tipIndexPath = Path()
          ..moveTo(centerX - 30, centerY - 100)
          ..quadraticBezierTo(
            centerX - 25, centerY - 120,
            centerX - 12, centerY - 100,
          )
          ..lineTo(centerX - 12, centerY - 74)
          ..lineTo(centerX - 32, centerY - 74)
          ..close();
        _zonePath = tipIndexPath;
        canvas.drawPath(tipIndexPath, paint);
        break;
        
      case 'base_middle_finger':
        final baseMiddlePath = Path()
          ..moveTo(centerX + 3, centerY - 42)
          ..lineTo(centerX + 20, centerY - 39)
          ..lineTo(centerX + 15, centerY - 10)
          ..lineTo(centerX - 2, centerY - 13)
          ..close();
        _zonePath = baseMiddlePath;
        canvas.drawPath(baseMiddlePath, paint);
        break;
        
      case 'middle_middle_finger':
        final middleMiddlePath = Path()
          ..moveTo(centerX + 10, centerY - 77)
          ..lineTo(centerX + 30, centerY - 74)
          ..lineTo(centerX + 22, centerY - 41)
          ..lineTo(centerX + 5, centerY - 44)
          ..close();
        _zonePath = middleMiddlePath;
        canvas.drawPath(middleMiddlePath, paint);
        break;
        
      case 'tip_middle_finger':
        final tipMiddlePath = Path()
          ..moveTo(centerX + 20, centerY - 105)
          ..quadraticBezierTo(
            centerX + 35, centerY - 120,
            centerX + 35, centerY - 100,
          )
          ..lineTo(centerX + 35, centerY - 100)
          ..lineTo(centerX + 30, centerY - 76)
          ..lineTo(centerX + 12, centerY - 79)
          ..close();
        _zonePath = tipMiddlePath;
        canvas.drawPath(tipMiddlePath, paint);
        break;
        
      case 'base_ring_finger':
        final baseRingPath = Path()
          ..moveTo(centerX + 32, centerY - 28)
          ..lineTo(centerX + 48, centerY - 17)
          ..lineTo(centerX + 37, centerY + 10)
          ..lineTo(centerX + 20, centerY)
          ..close();
        _zonePath = baseRingPath;
        canvas.drawPath(baseRingPath, paint);
        break;
        
      case 'middle_ring_finger':
        final middleRingPath = Path()
          ..moveTo(centerX + 45, centerY - 53)
          ..lineTo(centerX + 60, centerY - 44)
          ..lineTo(centerX + 49, centerY - 20)
          ..lineTo(centerX + 33, centerY - 30)
          ..close();
        _zonePath = middleRingPath;
        canvas.drawPath(middleRingPath, paint);
        break;
        
      case 'tip_ring_finger':
        final tipRingPath = Path()
          ..moveTo(centerX + 52, centerY - 80)
          ..quadraticBezierTo(
            centerX + 65, centerY - 95,
            centerX + 72, centerY - 75,
          )
          ..lineTo(centerX + 62, centerY - 46)
          ..lineTo(centerX + 45, centerY - 55)
          ..close();
        _zonePath = tipRingPath;
        canvas.drawPath(tipRingPath, paint);
        break;
      
        
      case 'base_little_finger':
        final baseLittlePath = Path()
          ..moveTo(centerX + 58, centerY + 16)
          ..lineTo(centerX + 67, centerY + 27)
          ..lineTo(centerX + 55, centerY + 43)
          ..lineTo(centerX + 45, centerY + 25)
          ..close();
        _zonePath = baseLittlePath;
        canvas.drawPath(baseLittlePath, paint);
        break;
        
      case 'middle_little_finger':
        final middleLittlePath = Path()
          ..moveTo(centerX + 73, centerY)
          ..lineTo(centerX + 85, centerY + 12)
          ..lineTo(centerX + 68, centerY + 27)
          ..lineTo(centerX + 58, centerY + 13)
          ..close();
        _zonePath = middleLittlePath;
        canvas.drawPath(middleLittlePath, paint);
        break;
        
      case 'tip_little_finger':
        final tipLittlePath = Path()
          ..moveTo(centerX + 90, centerY - 16)
          ..quadraticBezierTo(
            centerX + 100, centerY - 25,
            centerX + 105, centerY - 10,
          )
          ..lineTo(centerX + 87, centerY + 10)
          ..lineTo(centerX + 75, centerY - 2)
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
  bool shouldRepaint(ZoneHighlightPainter oldDelegate) {
    return zone != oldDelegate.zone || color != oldDelegate.color;
  }
}