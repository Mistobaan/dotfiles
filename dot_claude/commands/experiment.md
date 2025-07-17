# ML Experiment Setup

You are helping a machine learning engineer set up a new experiment. Follow these steps:

1. **Create experiment directory structure**:
   ```
   experiments/YYYY-MM-DD-experiment-name/
   ├── config.yaml
   ├── train.py
   ├── evaluate.py
   ├── logs/
   └── results/
   ```

2. **Generate configuration file** with:
   - Model hyperparameters
   - Data paths and preprocessing settings
   - Training parameters (epochs, batch_size, learning_rate)
   - Evaluation metrics
   - Random seed for reproducibility

3. **Create training script** that:
   - Loads configuration
   - Sets up logging and experiment tracking
   - Implements training loop with validation
   - Saves best model checkpoints
   - Logs metrics and hyperparameters

4. **Create evaluation script** that:
   - Loads trained model
   - Evaluates on test set
   - Generates performance report
   - Creates visualizations

5. **Set up experiment tracking**:
   - Initialize MLflow or Weights & Biases
   - Log all hyperparameters
   - Track metrics during training
   - Save artifacts (model, plots, reports)

Ask the user for:
- Experiment name and description
- Model type (sklearn, PyTorch, TensorFlow)
- Dataset information
- Specific metrics to track
- Any custom requirements