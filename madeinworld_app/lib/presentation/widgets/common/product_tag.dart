import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/enums/store_type.dart';

/// A reusable tag widget for displaying product information like categories, subcategories, and store locations
class ProductTag extends StatelessWidget {
  final String text;
  final ProductTagType type;
  final StoreType? storeType; // Used for store location tags to determine color

  const ProductTag({
    super.key,
    required this.text,
    required this.type,
    this.storeType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 8),
        vertical: ResponsiveUtils.getResponsiveSpacing(context, 4),
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.responsiveBodySmall(context).copyWith(
          color: _getTextColor(),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case ProductTagType.category:
      case ProductTagType.subcategory:
        // Both category and subcategory use the same neutral color scheme
        return AppColors.lightBackground;
      case ProductTagType.storeLocation:
        return _getStoreLocationBackgroundColor();
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case ProductTagType.category:
      case ProductTagType.subcategory:
        // Both category and subcategory use the same neutral border color
        return Colors.grey.shade300;
      case ProductTagType.storeLocation:
        return _getStoreLocationColor().withValues(alpha: 0.3);
    }
  }

  Color _getTextColor() {
    switch (type) {
      case ProductTagType.category:
      case ProductTagType.subcategory:
        // Both category and subcategory use the same neutral text color
        return AppColors.secondaryText;
      case ProductTagType.storeLocation:
        return _getStoreLocationColor();
    }
  }

  Color _getStoreLocationBackgroundColor() {
    final storeColor = _getStoreLocationColor();
    return storeColor.withValues(alpha: 0.1);
  }

  Color _getStoreLocationColor() {
    if (storeType == null) return AppColors.secondaryText;
    
    switch (storeType!) {
      case StoreType.unmannedStore:
        return const Color(0xFF2196F3); // Blue for 无人门店
      case StoreType.unmannedWarehouse:
        return const Color(0xFF4CAF50); // Green for 无人仓店
      case StoreType.exhibitionStore:
        return const Color(0xFFFFD556); // Yellow for 展销商店
      case StoreType.exhibitionMall:
        return const Color(0xFFF38900); // Orange for 展销商城
    }
  }
}

/// Enum to define different types of product tags
enum ProductTagType {
  category,
  subcategory,
  storeLocation,
}
