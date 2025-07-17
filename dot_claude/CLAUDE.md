# Machine Learning Engineer Configuration

## Code Style & Conventions

- Use 4-space indentation for Python code
- Use type hints for all function parameters and return values
- Follow PEP 8 style guidelines with 88-character line length (Black formatter)
- Use descriptive variable names for data science variables (e.g., `train_features`, `test_labels`)
- Prefer f-strings for string formatting
- Use docstrings in NumPy format for all functions and classes

## Common Commands

### Environment Management
- `conda create -n <env_name> python=3.10` - Create new conda environment
- `conda activate <env_name>` - Activate environment
- `pip install -r requirements.txt` - Install dependencies
- `pip freeze > requirements.txt` - Export dependencies

### Data Processing
- `jupyter notebook` - Start Jupyter notebook server
- `python -m pytest tests/` - Run unit tests
- `python -m pytest tests/ -v` - Run tests with verbose output
- `python -m pytest tests/ --cov=src` - Run tests with coverage

### Model Training & Evaluation
- `python train.py --config configs/experiment.yaml` - Train model with config
- `python evaluate.py --model-path models/best_model.pkl` - Evaluate model
- `tensorboard --logdir=logs` - Start TensorBoard
- `mlflow ui` - Start MLflow UI

### Code Quality
- `black .` - Format code with Black
- `isort .` - Sort imports
- `flake8 .` - Lint code
- `mypy .` - Type checking
- `pre-commit run --all-files` - Run pre-commit hooks

## Project Structure Patterns

### Standard ML Project Layout
```
project/
├── data/
│   ├── raw/
│   ├── processed/
│   └── external/
├── models/
├── notebooks/
├── src/
│   ├── data/
│   ├── features/
│   ├── models/
│   └── visualization/
├── tests/
├── configs/
├── requirements.txt
└── setup.py
```

### Data Science Notebook Structure
- Start with imports and configuration
- Load and explore data first
- Create clear markdown sections for each analysis step
- Include data validation and quality checks
- Document assumptions and limitations
- End with conclusions and next steps

## ML-Specific Guidelines

### Data Handling
- Always validate data types and shapes before processing
- Use pandas for structured data, NumPy for numerical operations
- Implement data validation with Great Expectations or similar
- Create reproducible data pipelines with versioning

### Model Development
- Use sklearn for traditional ML, PyTorch/TensorFlow for deep learning
- Implement proper train/validation/test splits
- Use cross-validation for model selection
- Track experiments with MLflow or Weights & Biases
- Save model artifacts with versioning

### Experiment Tracking
- Log all hyperparameters and metrics
- Use configuration files (YAML/JSON) for reproducibility
- Version control data and model artifacts
- Document model performance and limitations

### Testing
- Write unit tests for data processing functions
- Test model inference with sample data
- Validate model outputs and edge cases
- Use pytest fixtures for common test data

## Security & Ethics

- Never commit API keys or credentials
- Use environment variables for sensitive configuration
- Implement data privacy safeguards
- Document model bias and fairness considerations
- Follow responsible AI practices

## Performance Optimization

- Profile code with cProfile or line_profiler
- Use vectorized operations with NumPy/Pandas
- Implement parallel processing with joblib or multiprocessing
- Monitor memory usage with memory_profiler
- Use GPU acceleration when appropriate (CUDA/Metal)

## Collaboration

- Use clear commit messages following conventional commits
- Create detailed pull request descriptions
- Include model cards for documentation
- Share reproducible environments with requirements.txt or environment.yml
- Document data sources and preprocessing steps