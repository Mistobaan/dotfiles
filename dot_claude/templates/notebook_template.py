# Jupyter Notebook Template for ML Projects

NOTEBOOK_TEMPLATE = """
# {title}

## Overview
Brief description of the notebook's purpose and what it accomplishes.

## Setup

### Imports
```python
# Standard library
import os
import sys
import warnings
from pathlib import Path

# Data manipulation
import pandas as pd
import numpy as np

# Visualization
import matplotlib.pyplot as plt
import seaborn as sns

# Machine learning
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report

# Configuration
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")
warnings.filterwarnings('ignore')

# Set random seed for reproducibility
RANDOM_STATE = 42
np.random.seed(RANDOM_STATE)
```

### Configuration
```python
# Project paths
PROJECT_ROOT = Path.cwd().parent
DATA_DIR = PROJECT_ROOT / "data"
RAW_DATA_DIR = DATA_DIR / "raw"
PROCESSED_DATA_DIR = DATA_DIR / "processed"
MODELS_DIR = PROJECT_ROOT / "models"
RESULTS_DIR = PROJECT_ROOT / "results"

# Create directories if they don't exist
for dir_path in [PROCESSED_DATA_DIR, MODELS_DIR, RESULTS_DIR]:
    dir_path.mkdir(parents=True, exist_ok=True)

# Display settings
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', 100)
```

## 1. Data Loading

```python
# Load data
data = pd.read_csv(RAW_DATA_DIR / "dataset.csv")

# Display basic information
print(f"Dataset shape: {data.shape}")
print(f"Memory usage: {data.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
data.head()
```

## 2. Data Exploration

### Basic Information
```python
# Data types and missing values
print("Data Info:")
data.info()

print("\nMissing values:")
print(data.isnull().sum())

print("\nBasic statistics:")
data.describe()
```

### Visualizations
```python
# Distribution plots
fig, axes = plt.subplots(2, 2, figsize=(15, 10))
fig.suptitle('Data Distribution Overview', fontsize=16)

# Add your visualizations here
# Example: data['column'].hist(ax=axes[0,0])

plt.tight_layout()
plt.show()
```

## 3. Data Preprocessing

```python
# Handle missing values
# Example: data.fillna(method='forward', inplace=True)

# Feature engineering
# Example: data['new_feature'] = data['feature1'] * data['feature2']

# Encode categorical variables
# Example: data = pd.get_dummies(data, columns=['categorical_column'])

print(f"Processed data shape: {data.shape}")
```

## 4. Model Development

### Train-Test Split
```python
# Define features and target
X = data.drop('target', axis=1)
y = data['target']

# Split the data
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y
)

print(f"Training set shape: {X_train.shape}")
print(f"Test set shape: {X_test.shape}")
```

### Feature Scaling
```python
# Scale features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)
```

### Model Training
```python
# Initialize and train model
# Example: model = LogisticRegression(random_state=RANDOM_STATE)
# model.fit(X_train_scaled, y_train)

# Make predictions
# y_pred = model.predict(X_test_scaled)

# Print results
# print(f"Accuracy: {accuracy_score(y_test, y_pred):.4f}")
# print(f"Classification Report:\n{classification_report(y_test, y_pred)}")
```

## 5. Model Evaluation

```python
# Evaluation metrics and visualizations
# Add confusion matrix, ROC curve, feature importance, etc.
```

## 6. Results and Conclusions

### Key Findings
- Finding 1
- Finding 2
- Finding 3

### Next Steps
- [ ] Improvement 1
- [ ] Improvement 2
- [ ] Improvement 3

### Model Performance Summary
```python
# Summary of model performance
results = {
    'accuracy': 0.85,
    'precision': 0.83,
    'recall': 0.87,
    'f1_score': 0.85
}

results_df = pd.DataFrame([results])
print(results_df)
```

## 7. Save Results

```python
# Save processed data
data.to_csv(PROCESSED_DATA_DIR / "processed_dataset.csv", index=False)

# Save model
# joblib.dump(model, MODELS_DIR / "trained_model.pkl")

# Save results
# results_df.to_csv(RESULTS_DIR / "model_results.csv", index=False)

print("Results saved successfully!")
```
"""

if __name__ == "__main__":
    # Create a new notebook from template
    title = input("Enter notebook title: ")
    filename = input("Enter filename (without .ipynb): ")
    
    # Generate notebook content
    notebook_content = NOTEBOOK_TEMPLATE.format(title=title)
    
    # Save to file
    with open(f"{filename}.py", "w") as f:
        f.write(notebook_content)
    
    print(f"Notebook template saved as {filename}.py")
    print("Convert to .ipynb using: jupytext --to notebook {filename}.py")