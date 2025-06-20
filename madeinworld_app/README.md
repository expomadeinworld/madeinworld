# Made in World Flutter App

A comprehensive Flutter mobile application frontend that replicates the UI design from the Made in World project documentation. This app serves as a super-app platform with multiple mini-apps for different store types.

## 🎯 Project Overview

This Flutter app implements the exact UI design specified in the project documentation, including:
- **Super-App Architecture**: Main container with bottom navigation
- **Mini-Apps**: Retail Store (零售门店) and Unmanned Store (无人门店) with distinct features
- **Shopping Cart**: Full cart functionality with state management
- **Responsive Design**: Mobile-first design that matches the HTML mockup exactly

## 🏗️ Architecture

### Core Structure
```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── theme/                   # Design system (colors, typography, theme)
│   └── enums/                   # Shared enumerations
├── data/
│   ├── models/                  # Data models (Product, Store, Category, etc.)
│   └── services/                # Mock data services
└── presentation/
    ├── providers/               # State management (Cart, Navigation)
    ├── widgets/                 # Reusable UI components
    └── screens/                 # App screens and mini-apps
```

### Design System
- **Typography**: Manrope font family with specific weights
- **Colors**: Theme red (#D92525), light backgrounds, proper contrast
- **Components**: Consistent styling across all UI elements

## 🚀 Features Implemented

### ✅ Main App Features
- **Home Screen**: Decorative backdrop, location header, search bar, service modules grid, hot recommendations
- **Locations Screen**: Map view placeholder with store list
- **Messages Screen**: Notification/chat interface
- **Profile Screen**: User profile with menu sections

### ✅ Mini-Apps
#### Retail Store (零售门店)
- Product grid without stock display
- Category filtering
- Bottom navigation: 商品, 消息, 购物车, 我的
- Shopping cart integration

#### Unmanned Store (无人门店)
- Product grid WITH stock display (database stock - 5)
- Category filtering
- Notched bottom navigation with FAB cart button
- Location selector in header
- QR scanner integration

### ✅ Shopping Cart
- Add/remove products with quantity controls
- Real-time cart badge updates
- Cart summary with total calculation
- Checkout flow (mock implementation)

### ✅ Navigation & UX
- Slide-in transitions for mini-apps
- Proper state management across screens
- Touch feedback and animations
- Responsive product cards with flexible heights

### ✅ Location Services
- **GPS Location**: Real-time user location detection
- **Permission Handling**: Proper location permission requests
- **Reverse Geocoding**: Convert coordinates to city names
- **Distance Calculation**: Calculate distances to unmanned stores
- **Nearest Store Detection**: Find and display closest unmanned store
- **Interactive Maps**: Google Maps integration (mobile) with fallback (web)
- **Store Filtering**: Search and filter unmanned stores by name/address

## 🎨 UI Components

### Key Widgets
- **ProductCard**: Displays product info, pricing, stock (for unmanned), add-to-cart controls
- **CategoryChip**: Horizontal scrolling category filters
- **AddToCartButton**: Circular add button that transforms to quantity controls
- **DecorativeBackdrop**: Radial gradient background for home screen

### Design Specifications
- **Service Modules**: 3x2 grid layout with colored icons and backgrounds
- **Product Grid**: 2-column masonry layout with flexible card heights
- **Navigation**: Custom bottom navigation with proper active/inactive states

## 📱 Store Types & Features

| Feature | Retail Store | Unmanned Store |
|---------|-------------|----------------|
| Stock Display | ❌ Hidden | ✅ Visible (stock - 5) |
| Navigation Style | Standard Bottom Nav | Notched with FAB |
| Header Actions | Search + Notifications | Location + QR Scanner |
| Product Categories | Retail-specific | Unmanned-specific |

## 🛠️ Technical Implementation

### State Management
- **Provider**: Used for cart state and navigation
- **Mock Data**: Comprehensive sample data for products, stores, categories

### Dependencies
```yaml
dependencies:
  google_fonts: ^6.1.0           # Manrope typography
  flutter_svg: ^2.0.9            # SVG icon support
  cached_network_image: ^3.3.0   # Image caching
  flutter_staggered_grid_view: ^0.7.0  # Flexible grids
  provider: ^6.1.1               # State management
  animations: ^2.0.11            # Custom transitions

  # Location Services
  geolocator: ^12.0.0            # GPS location services
  permission_handler: ^11.3.1    # Permission management
  geocoding: ^3.0.0              # Reverse geocoding
  google_maps_flutter: ^2.6.1    # Interactive maps
```

## 🗺️ **Google Maps Setup**

To enable the interactive map functionality, you need to configure Google Maps API keys:

### **1. Get Google Maps API Key**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable **Maps SDK for iOS** and **Maps SDK for Android**
4. Create API credentials (API Key)
5. Restrict the key to your app's bundle ID/package name

### **2. Configure iOS**
Edit `ios/Runner/AppDelegate.swift`:
```swift
// Replace the placeholder with your actual API key
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
```

### **3. Configure Android**
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Replace the placeholder with your actual API key -->
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

### **4. Current Status**
- ✅ **Map Integration**: Fully implemented with Google Maps Flutter
- ✅ **Store Markers**: All unmanned stores displayed as markers
- ✅ **User Location**: Shows user's current position on map
- ✅ **Interactive Features**: Tap markers for detailed store information
- ✅ **Search Functionality**: Search stores by name or address with map focus
- ✅ **Store Details**: Rich bottom sheet with distance, walking time, and actions
- ✅ **Map Controls**: Custom floating controls for search, location, and navigation
- ✅ **Auto-fit Bounds**: Map automatically adjusts to show all stores optimally
- ✅ **API Keys Configured**: Real Google Maps API keys properly integrated

**Status**: ✅ **FULLY FUNCTIONAL** - Complete interactive map experience implemented!

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation
```bash
# Clone the repository
cd madeinworld_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Available Platforms
- ✅ **Web**: Fully functional for development and testing
- ✅ **iOS**: Ready for iOS deployment
- ✅ **Android**: Ready for Android deployment
- ✅ **macOS**: Desktop support available

## 📋 Mock Data

The app includes comprehensive mock data:
- **Products**: 可口可乐, 百味来意面, 天然矿泉水, 瑞士莲巧克力
- **Categories**: 饮料, 零食, 意面, 巧克力, 水果, 乳制品
- **Stores**: Via Nassa 店 (卢加诺), Centro 店
- **User**: Mock user profile with avatar and contact info

## 🎯 Next Steps

### Backend Integration
- Replace mock data services with real API calls
- Implement authentication and user management
- Add real-time inventory updates
- Integrate payment processing

### Enhanced Features
- Real QR code scanning functionality
- Push notifications
- Offline support with local storage
- Advanced search and filtering
- User reviews and ratings

### Additional Mini-Apps
- 无人仓店 (Unmanned Warehouse)
- 展销商店 (Exhibition Store)
- 展销商城 (Exhibition Mall)
- 团购团批 (Group Buying)

## 📄 Documentation Reference

This implementation is based on:
- `madeinworld_docs/mockup_code.html` - Exact UI reference
- `madeinworld_docs/example.png` - Visual design reference
- `madeinworld_docs/APP Interface Description.md` - Functionality specifications
- `madeinworld_docs/Database Sample Description.md` - Data structure
- `madeinworld_docs/System Architecture & Technology Stack.md` - Technical requirements

## 🏆 Implementation Status

- ✅ **Core Architecture**: Complete
- ✅ **UI Design**: Matches mockup exactly
- ✅ **Navigation**: Fully functional
- ✅ **Shopping Cart**: Complete with state management
- ✅ **Mini-Apps**: Both retail and unmanned stores implemented
- ✅ **Responsive Design**: Mobile-optimized
- ✅ **Mock Data**: Comprehensive sample data
- ✅ **Code Quality**: Clean, well-organized, follows Flutter best practices

The Flutter frontend is now ready for backend integration and deployment!
