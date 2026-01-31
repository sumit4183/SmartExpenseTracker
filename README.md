# Smart Expense Tracker (iOS + Core ML)

An intelligent, privacy-first personal finance application that uses on-device Machine Learning to categorize transactions, forecast spending, and detect anomalies.

## 🌟 Key Features

### 1. Smart Input (Real-time Categorization)
*   **What it does**: Automatically suggests categories (e.g., "Food & Drink", "Transport") as you type a description.
*   **Technology**: Apple **Core ML** (Natural Language Processing).
*   **Model**: `ExpenseCategorizer.mlmodel` (Trained on prototype dataset using Create ML).
*   **Privacy**: Run 100% on-device. No data leaves the phone.

### 2. Personalized Forecasting
*   **What it does**: Predicts your daily spending based on your specific history for the current day of the week.
*   **Logic**: "Weekday Averaging" algorithm.
    *   *Cold Start*: showing "AI Learning..." until 5 transactions are recorded.
    *   *Active*: Aggregates historical data for the specific weekday (e.g., Saturdays) to provide a tailored run-rate.

### 3. Anomaly Detection (The Financial Guardian)
*   **What it does**: Alerts you before you save a transaction that is statistically unusual for that category.
*   **Logic**: **Z-Score Analysis**.
    *   Calculates the Mean and Standard Deviation of the category.
    *   Flags any transaction with a Z-Score > 2.0 (Top 2.5% outlier).
    *   Includes a noise filter (min variance $5.00) to prevent false alarms on small amounts.

### 4. Transaction History
*   **Features**:
    *   Grouped by Date (Today, Yesterday, etc.).
    *   Searchable by Description.
    *   Swipe-to-delete.

---

## 🛠 Technical Architecture

*   **Language**: Swift 5.
*   **UI Framework**: SwiftUI.
*   **Persistence**: Core Data (Local Database).
*   **Pattern**: MVVM (Model-View-ViewModel).
*   **Machine Learning**:
    *   **Training**: Python (`scripts/generate_data.py`) & Create ML.
    *   **Inference**: Core ML Framework.

