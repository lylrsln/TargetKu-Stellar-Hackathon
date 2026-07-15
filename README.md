# TargetKu: Smart Financial Guard 🛡️

TargetKu is a smart financial assistant designed to protect university students from impulsive spending and predatory loans. By utilizing a Rule-Based System and Soroban Smart Contracts, we autonomously manage and safeguard your financial goals.

# IMPORTANT: Soroban Contract Address
Contract Address (Testnet/Mainnet): `[TBA - To Be Announced during Development Sprint]`

# The Problem
University students face a severe cost-of-living crisis. The failure to separate essential priority expenses from flexible lifestyle spending often leads to mid-month liquidity crises, forcing them into predatory online loans (pinjol) just to survive or pay tuition.

# Our Solution
TargetKu proactively analyzes cash flow in real-time using a Forward Chaining Rule-Based System. It curbs impulsive spending and securely locks targeted savings into a Soroban Smart Contract Vault via a daily micro-consent mechanism. 

# Tech Stack
* Frontend/Mobile: Flutter (Dart)
* Backend & Local Storage: Firebase, Shared Preferences
* Core Logic Engine: Custom Rule-Based System (Forward Chaining)
* Web3 Integration (Expected): Stellar Horizon API & Soroban Smart Contracts (Rust)

# Key Dependencies (pubspec.yaml)
To build this project, we rely on several core packages:
* `firebase_core`, `firebase_auth`, `cloud_firestore` (Backend & Authentication)
* `provider` (State Management)
* `shared_preferences` (Local Data Caching)
* `fl_chart` (Data Visualization & Graphics)
* `pdf` & `path_provider` (Automated PDF Report Generation)
* `image_picker` (Camera & Gallery Access)
* `intl` (Date & Currency Formatting)
* `google_fonts` (Typography)
* `tutorial_coach_mark` (Interactive Onboarding UI)

# How to Run the Project
1. Clone the repository: `git clone https://github.com/lylrsln/TargetKu-Stellar-Hackathon.git`
2. Install all dependencies listed above automatically: `flutter pub get`
3. Run the app: `flutter run`
