import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# Categories corresponding to Apple's typical finance categories
CATEGORIES = [
    "Food & Drink", "Shopping", "Transport", "Groceries", 
    "Utilities", "Entertainment", "Health", "Travel", "Rent", "Salary"
]

# Common transaction descriptions for realistic training
DESCRIPTIONS = {
    "Food & Drink": ["Starbucks", "McDonalds", "Chipotle", "Dunkin", "Local Cafe", "Burger King", "Sushi Place", "Bar XYZ", "Pizza Hut", "Vending Machine"],
    "Shopping": ["Amazon", "Target", "Walmart", "Nike", "Apple Store", "Zara", "H&M", "Best Buy", "Pharmacy", "Bookstore"],
    "Transport": ["Uber", "Lyft", "MTA Subway", "Gas Station", "Shell", "Exxon", "Parking", "Train Ticket", "Bus Fare", "Lime Scooter"],
    "Groceries": ["Whole Foods", "Trader Joes", "Kroger", "Safeway", "Costco", "Local Market", "Bakery", "Butcher", "Fruit Stand", "Aldi"],
    "Utilities": ["ConEd", "Water Bill", "Internet Bill", "Verizon", "AT&T", "Spotify", "Netflix", "Hulu", "Electric Co", "Trash Pickup"],
    "Entertainment": ["AMC Theaters", "Ticketmaster", "Bowling", "Museum", "Concert", "Video Game", "Steam", "PlayStation", "Spotify Premium", "Netflix Sub"],
    "Health": ["CVS", "Walgreens", "Doctor Visit", "Dentist", "Gym Membership", "Planet Fitness", "Yoga Class", "Pharmacy Co-pay", "Vitamin Shop", "Hospital"],
    "Travel": ["Delta", "United", "Airbnb", "Hotel", "Expedia", "Booking.com", "Amtrak", "Car Rental", "Resort", "Duty Free"],
    "Rent": ["Landlord", "Property Mgmt", "Rent Payment", "Mortgage", "HOA Fees"],
    "Salary": ["Payroll", "Direct Deposit", "Employer Inc", "Stripe Payout", "Upwork"]
}

def generate_transactions(num_rows=1000):
    data = []
    start_date = datetime.now() - timedelta(days=365)
    
    for _ in range(num_rows):
        cat = random.choice(CATEGORIES)
        
        # Weighted choice for realistic spending
        if cat == "Rent":
            amt = random.uniform(1000, 3000)
        elif cat == "Salary":
            amt = random.uniform(2000, 5000)
        elif cat == "Food & Drink":
            amt = random.uniform(5, 50)
        else:
            amt = random.uniform(10, 200)
            
        desc = random.choice(DESCRIPTIONS[cat])
        
        # Add some noise to descriptions (e.g., "Starbucks #1234")
        if random.random() > 0.5:
            desc += f" #{random.randint(100, 9999)}"
            
        date = start_date + timedelta(days=random.randint(0, 365))
        
        data.append({
            "description": desc,
            "amount": round(amt, 2),
            "date": date,
            "category": cat
        })
        
    df = pd.DataFrame(data)
    
    # RENAME COLUMNS FOR CREATE ML AUTO-DETECTION
    # CreateML automatically looks for "text" and "label" columns.
    df = df.rename(columns={"description": "text", "category": "label"})
    
    print(f"Generated {len(df)} transactions.")
    return df

if __name__ == "__main__":
    df = generate_transactions(2000)
    df.to_csv("scripts/synthetic_transactions.csv", index=False)
    print("Saved to scripts/synthetic_transactions.csv")
