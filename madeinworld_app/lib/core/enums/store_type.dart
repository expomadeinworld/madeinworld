enum StoreType {
  unmannedStore,      // 无人门店
  unmannedWarehouse,  // 无人仓店
  exhibitionStore,    // 展销商店
  exhibitionMall,     // 展销商城
}

extension StoreTypeExtension on StoreType {
  String get displayName {
    switch (this) {
      case StoreType.unmannedStore:
        return '无人门店';
      case StoreType.unmannedWarehouse:
        return '无人仓店';
      case StoreType.exhibitionStore:
        return '展销商店';
      case StoreType.exhibitionMall:
        return '展销商城';
    }
  }

  String get apiValue {
    switch (this) {
      case StoreType.unmannedStore:
        return 'UnmannedStore';
      case StoreType.unmannedWarehouse:
        return 'UnmannedWarehouse';
      case StoreType.exhibitionStore:
        return 'ExhibitionStore';
      case StoreType.exhibitionMall:
        return 'ExhibitionMall';
    }
  }

  String get chineseValue {
    switch (this) {
      case StoreType.unmannedStore:
        return '无人门店';
      case StoreType.unmannedWarehouse:
        return '无人仓店';
      case StoreType.exhibitionStore:
        return '展销商店';
      case StoreType.exhibitionMall:
        return '展销商城';
    }
  }

  static StoreType fromApiValue(String apiValue) {
    switch (apiValue) {
      case 'UnmannedStore':
        return StoreType.unmannedStore;
      case 'UnmannedWarehouse':
        return StoreType.unmannedWarehouse;
      case 'ExhibitionStore':
        return StoreType.exhibitionStore;
      case 'ExhibitionMall':
        return StoreType.exhibitionMall;
      default:
        throw ArgumentError('Unknown StoreType: $apiValue');
    }
  }

  static StoreType fromChineseValue(String chineseValue) {
    switch (chineseValue) {
      case '无人门店':
      case '无人商店': // Keep backward compatibility
        return StoreType.unmannedStore;
      case '无人仓店':
        return StoreType.unmannedWarehouse;
      case '展销商店':
        return StoreType.exhibitionStore;
      case '展销商城':
        return StoreType.exhibitionMall;
      default:
        throw ArgumentError('Unknown StoreType: $chineseValue');
    }
  }
}

enum StoreTypeAssociation {
  retail,
  unmanned,
  all,
}
