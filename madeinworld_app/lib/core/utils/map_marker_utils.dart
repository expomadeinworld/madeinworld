import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../enums/store_type.dart';

class MapMarkerUtils {
  // Hex color codes as specified
  static const Color unmannedStoreColor = Color(0xFF2196F3);
  static const Color unmannedWarehouseColor = Color(0xFF4CAF50);
  static const Color exhibitionStoreColor = Color(0xFFFFD556);
  static const Color exhibitionMallColor = Color(0xFFF38900);
  static const Color userLocationColor = Color(0xFF4285F4);

  /// Chooses the correct icon for a given store type
  static IconData _getIconForStoreType(StoreType storeType) {
    switch (storeType) {
      case StoreType.unmannedStore:
        return Icons.store; // Shop/Store Icon
      case StoreType.unmannedWarehouse:
        return Icons.warehouse; // Warehouse Icon
      case StoreType.exhibitionStore:
        return Icons.shopping_bag; // Store/Shopping Bag Icon
      case StoreType.exhibitionMall:
        return Icons.domain; // Mall/Big Building Icon
    }
  }

  /// Gets the color for a specific store type
  static Color getStoreTypeColor(StoreType storeType) {
    switch (storeType) {
      case StoreType.unmannedStore:
        return unmannedStoreColor;
      case StoreType.unmannedWarehouse:
        return unmannedWarehouseColor;
      case StoreType.exhibitionStore:
        return exhibitionStoreColor;
      case StoreType.exhibitionMall:
        return exhibitionMallColor;
    }
  }

  /// Creates a custom marker by drawing a background shape and an icon on a canvas.
  static Future<BitmapDescriptor> _createMarkerWithIcon({
    required Color backgroundColor,
    required IconData iconData,
    double size = 100.0,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final rect = Rect.fromLTWH(0.0, 0.0, size, size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20.0)); // Rounded square shape

    // Draw the background shape
    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(rrect, backgroundPaint);

    // Prepare to draw the icon
    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );

    // Layout and paint the icon in the center of the shape
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size - iconPainter.width) / 2,
        (size - iconPainter.height) / 2,
      ),
    );

    // Convert canvas to image
    final image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// **Main function to get a marker for a store type**
  static Future<BitmapDescriptor> getStoreMarkerIcon(StoreType storeType) async {
    final color = getStoreTypeColor(storeType);
    final icon = _getIconForStoreType(storeType);

    return await _createMarkerWithIcon(
      backgroundColor: color,
      iconData: icon,
      size: 40.0, // <-- This is a more reasonable size
    );
  }

  /// Creates a user location marker (Google Maps style current location icon)
  static Future<BitmapDescriptor> createUserLocationMarker({double size = 80}) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final center = Offset(size / 2, size / 2);

    // Outer transparent blue circle
    canvas.drawCircle(center, size / 2, Paint()..color = userLocationColor.withAlpha(51)); // 0.2 opacity is ~51 alpha
    // White border
    canvas.drawCircle(center, size / 3.5 + 2, Paint()..color = Colors.white);
    // Inner solid blue circle
    canvas.drawCircle(center, size / 3.5, Paint()..color = userLocationColor);
    
    final image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }
}