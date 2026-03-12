# Don Shop - Système de Facturation Intelligent 🚀

**Don Shop** est une application Flutter moderne et robuste conçue pour simplifier la gestion des ventes, du stock et de la facturation pour les petites et moyennes entreprises. Alliant élégance (Mode Sombre, Design Premium) et performance, elle offre une expérience utilisateur fluide pour la gestion quotidienne d'une boutique.

## 🌟 Fonctionnalités Clés

### 🛒 Ventes et Facturation
- **Scanner de Code-barres** : Intégration de `mobile_scanner` pour une saisie ultra-rapide des articles.
- **Vente Manuelle** : Possibilité d'ajouter des ventes sans code-barres.
- **Panier Dynamique** : Gestion facile des quantités et calcul automatique du total.
- **Checkout Complet** : Revue de commande détaillée avec génération de QR Code pour les paiements.

### 📦 Gestion des Stocks
- **Catalogue Produits** : Ajout, modification et suppression de produits avec gestion des prix et des stocks.
- **Mouvement de Stock** : Suivi précis des entrées et sorties, avec possibilité de réapprovisionnement rapide.
- **Alertes Stock Bas** : Indicateurs visuels et notifications pour ne jamais être en rupture de stock.
- **Importation de Données** : Support des fichiers Excel et CSV pour importer massivement vos produits.

### 📊 Rapports et Statistiques
- **Tableau de Bord** : Vue d'ensemble des ventes du jour, du chiffre d'affaires et des articles populaires.
- **Graphiques Interactifs** : Visualisation des performances via `fl_chart`.
- **Historique des Ventes** : Journal détaillé de toutes les transactions passées.

### ⚙️ Configuration et Matériel
- **Personnalisation de la Boutique** : Configuration du nom, de l'adresse, du logo et des informations de contact.
- **Impression Bluetooth** : Support des imprimantes thermiques pour l'impression instantanée des reçus.
- **Partage WhatsApp** : Envoi direct des reçus au format PDF par message.
- **Mode Sombre (Dark Mode)** : Interface totalement adaptée pour un confort visuel optimal de jour comme de nuit.
- **Localisation** : Interface 100% en Français, adaptée spécifiquement au marché local (FCFA).

## 🛠 Pile Technique

- **Framework** : [Flutter](https://flutter.dev)
- **Gestion d'État** : [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Architecture BLoC)
- **Base de Données Locale** : [Hive](https://pub.dev/packages/hive) (Rapide et persistant)
- **Navigation** : [go_router](https://pub.dev/packages/go_router)
- **Design** : [Google Fonts (Outfit, IBM Plex Sans)](https://fonts.google.com/)
- **PDF & Impression** : `pdf`, `printing`, `print_bluetooth_thermal`
- **Scanner** : `mobile_scanner`

## 🏗 Architecture

L'application suit une structure de **Clean Architecture** modulaire :
- `lib/core` : Utilitaires, thèmes, widgets globaux et helpers.
- `lib/features` : Découpage par fonctionnalités (Billing, Product, Shop, Settings).
    - `data` : DTO, Data sources et implémentations des repositories.
    - `domain` : Entités et cas d'utilisation (use cases).
    - `presentation` : UI (Pages, Widgets) et logique d'état (BLoC).
- `lib/config` : Routes et configurations globales.

## 🚀 Installation

1. **Cloner le projet** :
   ```bash
   git clone https://github.com/Donchaminade/billingapp.git
   ```

2. **Installer les dépendances** :
   ```bash
   flutter pub get
   ```

3. **Lancer la génération de code** (pour Hive et JSON) :
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Exécuter l'application** :
   ```bash
   flutter run
   ```

## 📸 Aperçu de l'Application

<div align="center">
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.35.jpeg" width="30%" />
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.35 (1).jpeg" width="30%" />
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.35 (2).jpeg" width="30%" />
  <br/><br/>
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.36.jpeg" width="30%" />
  <img src="assets/screenshots/WhatsApp Image 2026-03-12 at 13.37.36 (1).jpeg" width="30%" />
</div>

---
Développé avec ❤️ pour simplifier le commerce.
