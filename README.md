# Smart Expense Tracker

**Financial Intelligence. Privacy First.**

Smart Expense Tracker is a native iOS experience designed to understand your spending habits without your data ever leaving your device. It combines fluid SwiftUI interactions with On-Device Machine Learning to provide a financial assistant that is silent, smart, and secure.

## The Philosophy

Most finance apps are calculators. We built a companion.
By leveraging the Apple Neural Engine, the app moves beyond simple logging to offer proactive insights, all while maintaining absolute user privacy.

### 1. Zero-Touch Categorization
Typing "Starbucks" shouldn't require you to scroll through a list to find "Food & Drink".
*   **The Technology**: A custom Core ML Text Classifier trained on 2,000 synthetic transaction patterns.
*   **The Experience**: As you type, the interface anticipates your intent, selecting the correct category instantly.

### 2. Personalized Forecasting
The app learns your weekly rhythm. It doesn't just show what you spent; it helps you understand what you *might* spend.
*   **On-Device Learning**: The app statistically analyzes your spending geometry—grouping behavior by day-of-week (e.g., "Saturday Habits")—to project a daily run-rate that evolves as you use it.
*   **Privacy Model**: Your financial history is yours. No cloud analysis. No data mining.

### 3. Anomaly Detection (Guardian)
We believe software should look out for you.
*   **Statistical Protection**: The app constructs a rolling volatility profile (Standard Deviation) for each of your spending categories.
*   **The Nudge**: If a transaction falls outside your normal range (Z-Score > 2.0), the app gently prompts you to verify it. It’s not an error message; it’s a tap on the shoulder.

### 4. Narrative Insights
Numbers tell only half the story. The Insight Layer translates data into natural language.
*   **Contextual Awareness**: "Dining accounts for 42% of your spending in the last 2 weeks."
*   **Frequency Analysis**: "You’ve visited 'Whole Foods' 3 times recently."

---

## 🛠 Technical Architecture

*   **Language**: Swift 5.
*   **UI Framework**: SwiftUI.
*   **Persistence**: Core Data (Local Database).
*   **Pattern**: MVVM (Model-View-ViewModel).
*   **Machine Learning**:
    *   **Training**: Python (`scripts/generate_data.py`) & Create ML.
    *   **Inference**: Core ML Framework (Custom Text Classifier & Regressor).

---

## 🌟 V1.0 Feature Set

*   **Smart Entry**: Auto-categorization as you type.
*   **Deep Insights**: "Calm Computing" narratives about your spending.
*   **Safety Net**: Anomaly detection for unusual spending.
*   **Full Control**: Swipe-to-Edit and Swipe-to-Delete transactions.
*   **Privacy**: 100% On-Device. No account required.

---

## Technical Highlights

This project demonstrates a production-grade iOS architecture suitable for 2026.

*   **SwiftUI**: 100% declarative UI with fluid transitions and haptic feedback.
*   **Core Data**: Robust local persistence layer (Batched Fetching, Background Context).
*   **Combine**: Reactive data bindings for real-time model updates.
*   **MVVM**: Clean separation of Logic (ViewModels) and Presentation (Views).
*   **Modular Codebase**: Organized into `Core`, `Features`, and `App` layers.
---

## 🚀 Getting Started

### Prerequisites
*   Xcode 15.0+
*   iOS 17.0+
*   Swift 5.9+

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/SmartExpenseTracker.git
    ```
2.  Open `SmartExpenseTracker.xcodeproj` in Xcode.
3.  Select your target simulator (e.g., iPhone 15 Pro).
4.  Press **Cmd + R** to build and run.

*Note: The Core ML models are pre-compiled and included in the repository, so no additional setup is required.*

---

## 👤 Author

**Sumit Patel**
*   [LinkedIn](https://linkedin.com/in/sumit4183)
*   [GitHub](https://github.com/sumit4183)
*   [Portfolio](https://sumitp.netlify.app)

