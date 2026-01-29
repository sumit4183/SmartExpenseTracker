# 🍎 Smart Expense Tracker
> **A Privacy-First, On-Device Financial Intelligence App**

Smart Expense Tracker is a native SwiftUI iOS app that helps users understand, forecast, and optimize their spending using **on-device machine learning**. Unlike traditional finance apps, all analysis runs locally on the device, prioritizing privacy, performance, and offline functionality.

***

## 1️⃣ High-Level Overview
The goal is not just tracking expenses — it’s **understanding behavior**. The app transforms raw transactions into actionable insights, not just charts.

- **Privacy-first**: No sensitive financial data leaves the device.
- **Performance-aware**: Fast inference with lightweight models.
- **Offline-first**: Full functionality without internet.

***

## 2️⃣ Key Features

### 🧠 On-Device Intelligence (Core ML)
- **Automatic Categorization**: Predicts category (food, rent, travel) from transaction text.
- **Anomaly Detection**: Flags unusual or unexpected spending in real-time.
- **Spending Forecasting**: Predicts end-of-month spend based on historical trends.

### 📊 Insight-Driven Analytics
- "You spend 23% more on dining out on weekends."
- "This transaction is 2.4× higher than your typical spend."
- "You’re on track to exceed your monthly budget by $180."

### 📥 Expense Ingestion
- Manual entry with smart suggestions.
- CSV import for bulk bank statements.

***

## 3️⃣ Technical Architecture

### Frontend (Native iOS)
- **SwiftUI**: Declarative UI with smooth animations.
- **MVVM**: Clean architecture with Combine/async-await.
- **Charts**: Swift Charts for visualization.

### Data Layer
- **Core Data**: efficient local persistence and indexing.
- **Background Contexts**: optimizations for heavy ML tasks.

### Machine Learning Pipeline
- **Training**: Models trained in Python (Scikit-Learn/TensorFlow).
- **Conversion**: Converted to Core ML (`.mlmodel`) for iOS.
- **Inference**: High-performance local prediction.

***

## 4️⃣ Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+

### Installation
1. Clone the repository.
2. Open `SmartExpenseTracker.xcodeproj`.
3. Build and Run on Simulator or Device.

***
