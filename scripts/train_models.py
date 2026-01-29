import pandas as pd
import coremltools as ct
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
import os

def train_forecaster():
    print("Loading data...")
    df = pd.read_csv("scripts/synthetic_transactions.csv")
    
    # Preprocess for Forecasting
    # Goal: Predict 'amount' (spend) based on 'day_of_week'
    # Simplified for demo: Predict spending for a given day-of-week
    # In a real app, we'd aggregate by day.
    
    print("Training Forecaster (Random Forest)...")
    df['date'] = pd.to_datetime(df['date'])
    df['day_of_week'] = df['date'].dt.dayofweek
    
    # Input: Day of Week (0-6)
    # Output: Amount
    X = df[['day_of_week']]
    y = df['amount']
    
    # RandomForestRegressor handles non-linearities (weekends vs weekdays)
    from sklearn.ensemble import RandomForestRegressor
    model = RandomForestRegressor(n_estimators=50, max_depth=5, random_state=42)
    model.fit(X, y)
    
    print("Converting Forecaster to Core ML...")
    coreml_model = ct.converters.sklearn.convert(
        model,
        input_features=["day_of_week"],
        output_feature_names="predicted_amount"
    )
    
    coreml_model.short_description = "Predicts spending based on day of week."
    coreml_model.author = "Smart Expense Team"
    coreml_model.license = "MIT"
    
    save_path = "models/ExpenseForecaster.mlmodel"
    coreml_model.save(save_path)
    print(f"Saved Core ML model to {save_path}")

if __name__ == "__main__":
    if not os.path.exists("scripts/synthetic_transactions.csv"):
        print("Error: Run generate_data.py first.")
    else:
        train_forecaster()
