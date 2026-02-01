# Smart Expense Tracker

**Financial Intelligence. Privacy First.**

Smart Expense Tracker is a native iOS experience designed to understand your spending habits without your data ever leaving your device. It combines fluid SwiftUI interactions with On-Device Machine Learning to provide a financial assistant that is silent, smart, and secure.

<p align="center">
  <img src="https://user-images.githubusercontent.com/placeholder-dashboard.png" alt="App Dashboard" width="300">
</p>

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
    *   **Inference**: Core ML Framework.
    
---

## Technical Highlights

This project demonstrates a production-grade iOS architecture suitable for 2026.

*   **SwiftUI**: 100% declarative UI with fluid transitions and haptic feedback.
*   **Core Data**: Robust local persistence layer.
*   **Combine**: Reactive data bindings for real-time model updates.
*   **MVVM**: Clean separation of Logic (ViewModels) and Presentation (Views).

