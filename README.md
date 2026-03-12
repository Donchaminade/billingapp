# 🛒 Mobile POS & Billing App 

A feature-rich, high-performance offline-first billing and Point of Sale (POS) application built with Flutter. Designed for seamless retail checkout operations featuring barcode scanning, thermal Bluetooth printing, and robust local data persistence.

## 📸 Screenshots & Demo

<div align="center">
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.35.jpeg" width="30%" />
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.35 (1).jpeg" width="30%" />
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.35 (2).jpeg" width="30%" />
  <br/><br/>
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.36.jpeg" width="30%" />
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.36 (1).jpeg" width="30%" />
</div>

### Video Demo
https://github.com/user-attachments/assets/f2d16454-5408-43b3-b207-cd843bbc2c9e

## 🎯 Project Scope

This application serves as a complete offline POS system for small to medium-sized retail shops. It streamlines the checkout process, catalog management, and receipt generation securely entirely on-device.

### Core Features:
- **Product Management System**: Complete CRUD operations for inventory items with barcode/QR code support.
- **Smart Checkout System**: Rapid cart building via camera-based barcode scanning or manual entry, and robust order calculation functionality.
- **Bluetooth Thermal Printing**: Direct integration with thermal printers (`print_bluetooth_thermal`) to instantly output physical receipts.
- **Shop Settings & Customization**: Centrally managed shop details printed dynamically on receipts.
- **Offline-First Architecture**: Powered by `Hive` for lightning-fast localized NoSQL data storage. No active internet connectivity required.
- **Premium UI & Dark Mode**: Fully themed interface with smooth animations and professional aesthetics.

## 🛠 Tech Stack & Architecture

Built leveraging industry-standard architectural principles (Clean Architecture & Feature-Driven Design) ensuring scalability, separation of concerns, and robust testability. 

- **Framework**: [Flutter](https://flutter.dev/) (SDK >=3.1.0)
- **State Management**: `flutter_bloc`
- **Dependency Injection**: `get_it`
- **Routing**: `go_router`
- **Local Database**: `hive` & `hive_flutter`
- **Data Modeling**: `json_serializable`, `equatable`
- **Hardware Integrations**: `mobile_scanner` (barcodes), `print_bluetooth_thermal`

## 📁 File Structure

The codebase is organized using a **Feature-First Clean Architecture** utilizing domain-driven concepts.

```text
lib/
├── core/                       # Core application utilities and shared components
│   ├── data/                   # Global data sources (e.g., Hive initialization)
│   ├── theme/                  # UI aesthetics, typography, styling (Dark/Light mode)
│   ├── utils/                  # Helpers (e.g., PrinterHelper, formatters)
│   ├── widgets/                # Reusable global UI widgets
│   └── service_locator.dart    # get_it dependency injection setup
│
└── features/                   # Independent feature modules
    ├── billing/                # Core POS operations: Cart, Checkout
    ├── product/                # Inventory management & Reports
    ├── settings/               # App configuration & Printer
    └── shop/                   # Shop details
```

## 🚀 Getting Started

1. Clone the repository and fetch dependencies:
   ```bash
   git clone <repository_url>
   flutter pub get
   ```

2. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the project:
   ```bash
   flutter run
   ```

## 🤝 Contributing Guidelines
1. **Clean Architecture Rules**: Maintain strict boundaries between layers.
2. **Immutable States**: Emit only immutable states from BLoCs utilizing `equatable`.
3. **No Direct Exceptions**: Utilize `fpdart`'s `Either<Failure, Type>` pattern.

---
Developed with ❤️ by the Don Shop Team.
