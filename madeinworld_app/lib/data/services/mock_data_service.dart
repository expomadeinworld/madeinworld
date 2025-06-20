import '../models/product.dart';
import '../models/category.dart';
import '../models/store.dart';
import '../models/user.dart';
import '../../core/enums/store_type.dart';

class MockDataService {
  static List<Category> getCategories() {
    return [
      Category(
        id: '1',
        name: '饮料',
        storeTypeAssociation: StoreTypeAssociation.all,
      ),
      Category(
        id: '2',
        name: '零食',
        storeTypeAssociation: StoreTypeAssociation.all,
      ),
      Category(
        id: '3',
        name: '意面',
        storeTypeAssociation: StoreTypeAssociation.retail,
      ),
      Category(
        id: '4',
        name: '巧克力',
        storeTypeAssociation: StoreTypeAssociation.unmanned,
      ),
      Category(
        id: '5',
        name: '水果',
        storeTypeAssociation: StoreTypeAssociation.all,
      ),
      Category(
        id: '6',
        name: '乳制品',
        storeTypeAssociation: StoreTypeAssociation.unmanned,
      ),
    ];
  }

  static List<Product> getProducts() {
    return [
      // Featured products for home screen
      Product(
        id: '1',
        sku: 'COCA-001',
        title: '可口可乐 12瓶装',
        descriptionShort: '经典口味',
        descriptionLong: '经典可口可乐，12瓶装，清爽怡人，是聚会和日常饮用的完美选择。',
        manufacturerId: 'mfg-001',
        storeType: StoreType.unmanned,
        mainPrice: 9.99,
        strikethroughPrice: 12.50,
        isFeatured: true,
        imageUrls: ['https://placehold.co/300x300/FFF5F5/D92525?text=可口可乐'],
        categoryIds: ['1'],
        stockQuantity: 25, // Display: 20
      ),
      Product(
        id: '2',
        sku: 'BARILLA-001',
        title: '百味来 5号意面',
        descriptionShort: '意大利进口',
        descriptionLong: '正宗意大利百味来5号意面，优质小麦制作，口感Q弹，是制作各种意面料理的理想选择。',
        manufacturerId: 'mfg-002',
        storeType: StoreType.retail,
        mainPrice: 1.49,
        strikethroughPrice: 1.99,
        isFeatured: true,
        imageUrls: ['https://placehold.co/300x300/FFF5F5/D92525?text=百味来'],
        categoryIds: ['3'],
      ),
      Product(
        id: '3',
        sku: 'WATER-001',
        title: '天然矿泉水 6瓶装',
        descriptionShort: '源自阿尔卑斯',
        descriptionLong: '来自阿尔卑斯山的天然矿泉水，富含矿物质，口感清甜，6瓶装经济实惠。',
        manufacturerId: 'mfg-003',
        storeType: StoreType.unmanned,
        mainPrice: 2.99,
        strikethroughPrice: 3.80,
        isFeatured: true,
        imageUrls: ['https://placehold.co/300x300/FFF5F5/D92525?text=矿泉水'],
        categoryIds: ['1'],
        stockQuantity: 15, // Display: 10
      ),
      Product(
        id: '4',
        sku: 'LINDT-001',
        title: '瑞士莲 巧克力',
        descriptionShort: '丝滑享受',
        descriptionLong: '瑞士莲经典牛奶巧克力，丝滑细腻的口感，甜而不腻，是巧克力爱好者的首选。',
        manufacturerId: 'mfg-004',
        storeType: StoreType.unmanned,
        mainPrice: 4.50,
        strikethroughPrice: 5.25,
        isFeatured: true,
        imageUrls: ['https://placehold.co/300x300/FFF5F5/D92525?text=巧克力'],
        categoryIds: ['4'],
        stockQuantity: 12, // Display: 7
      ),
    ];
  }

  static List<Store> getStores() {
    return [
      // Unmanned stores only (retail stores excluded from main app)
      Store(
        id: '1',
        name: 'Via Nassa 店',
        city: '卢加诺',
        address: 'Via Nassa 5, 6900 Lugano',
        latitude: 46.0037,
        longitude: 8.9511,
        type: StoreType.unmanned,
      ),
      Store(
        id: '3',
        name: 'Piazza Riforma 店',
        city: '卢加诺',
        address: 'Piazza Riforma 1, 6900 Lugano',
        latitude: 46.0049,
        longitude: 8.9517,
        type: StoreType.unmanned,
      ),
      Store(
        id: '4',
        name: 'Via Pretorio 店',
        city: '卢加诺',
        address: 'Via Pretorio 15, 6900 Lugano',
        latitude: 46.0058,
        longitude: 8.9489,
        type: StoreType.unmanned,
      ),
      Store(
        id: '5',
        name: 'Corso Pestalozzi 店',
        city: '卢加诺',
        address: 'Corso Pestalozzi 8, 6900 Lugano',
        latitude: 46.0071,
        longitude: 8.9523,
        type: StoreType.unmanned,
      ),
      Store(
        id: '6',
        name: 'Via Cattedrale 店',
        city: '卢加诺',
        address: 'Via Cattedrale 3, 6900 Lugano',
        latitude: 46.0043,
        longitude: 8.9503,
        type: StoreType.unmanned,
      ),
      // Retail stores (only accessible through mini-app)
      Store(
        id: '2',
        name: 'Centro 店',
        city: '卢加诺',
        address: 'Via Centro 12, 6900 Lugano',
        latitude: 46.0067,
        longitude: 8.9541,
        type: StoreType.retail,
      ),
    ];
  }

  static User getMockUser() {
    return User(
      id: 'user-001',
      phoneNumber: '+41791234567',
      fullName: '尊贵的用户',
      email: 'user.name@email.com',
      avatarUrl: 'https://placehold.co/96x96/D92525/FFFFFF?text=M',
      role: UserRole.customer,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  // Get products by store type
  static List<Product> getProductsByStoreType(StoreType storeType) {
    return getProducts().where((product) => product.storeType == storeType).toList();
  }

  // Get categories by store type
  static List<Category> getCategoriesByStoreType(StoreType storeType) {
    return getCategories().where((category) => 
      category.storeTypeAssociation == StoreTypeAssociation.all ||
      (storeType == StoreType.retail && category.storeTypeAssociation == StoreTypeAssociation.retail) ||
      (storeType == StoreType.unmanned && category.storeTypeAssociation == StoreTypeAssociation.unmanned)
    ).toList();
  }

  // Get featured products for home screen
  static List<Product> getFeaturedProducts() {
    return getProducts().where((product) => product.isFeatured).toList();
  }

  // Get only unmanned stores (for main app location features)
  static List<Store> getUnmannedStores() {
    return getStores().where((store) => store.type == StoreType.unmanned).toList();
  }

  // Get only retail stores (for mini-app only)
  static List<Store> getRetailStores() {
    return getStores().where((store) => store.type == StoreType.retail).toList();
  }
}
