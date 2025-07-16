# Claude Code Configuration for Machine Learning Engineers

This directory contains optimized Claude Code configuration for machine learning projects.

## Files Overview

### Core Configuration
- `CLAUDE.md` - Main configuration with ML-specific guidelines, commands, and best practices
- `settings.json` - Shared project settings with ML environment variables
- `settings.local.json` - Personal settings template (copy and customize)

### Slash Commands
- `/experiment` - Set up new ML experiment with proper structure
- `/debug` - Debug ML models and code systematically
- `/eda` - Perform comprehensive exploratory data analysis

### Templates
- `ml_project_structure.md` - Standard ML project layout and key files
- `notebook_template.py` - Jupyter notebook template with ML best practices

## Setup Instructions

1. **Copy to your project**:
   ```bash
   cp -r dot_claude .claude
   ```

2. **Customize local settings**:
   ```bash
   cp .claude/settings.local.json.example .claude/settings.local.json
   # Edit with your API keys and preferences
   ```

3. **Set environment variables**:
   ```bash
   export WANDB_API_KEY="your_wandb_key"
   export MLFLOW_TRACKING_URI="http://localhost:5000"
   export KAGGLE_USERNAME="your_username"
   export KAGGLE_KEY="your_key"
   ```

## Usage

### Quick Start
1. Create new ML project: `/experiment`
2. Explore data: `/eda`
3. Debug issues: `/debug`

### Common Commands (from CLAUDE.md)
- `conda create -n myenv python=3.10` - Create environment
- `python train.py --config configs/experiment.yaml` - Train model
- `tensorboard --logdir=logs` - Start TensorBoard
- `black .` - Format code
- `python -m pytest tests/ --cov=src` - Run tests with coverage

### Project Structure
Use the template in `templates/ml_project_structure.md` to set up new projects with:
- Proper data organization
- Source code structure
- Configuration management
- Testing framework
- Documentation

## Best Practices Included

- **Code Style**: Black formatting, type hints, PEP 8 compliance
- **Data Handling**: Validation, versioning, reproducible pipelines
- **Model Development**: Experiment tracking, proper splits, validation
- **Testing**: Unit tests, data validation, model testing
- **Security**: No hardcoded credentials, environment variables
- **Collaboration**: Clear commits, documentation, reproducibility

## Environment Variables

The configuration includes commonly used ML environment variables:
- `PYTHONPATH` - Python module search path
- `WANDB_PROJECT` - Weights & Biases project name
- `MLFLOW_TRACKING_URI` - MLflow tracking server
- `CUDA_VISIBLE_DEVICES` - GPU selection
- `TOKENIZERS_PARALLELISM` - Disable for stability

## Customization

Edit `CLAUDE.md` to add:
- Project-specific guidelines
- Custom commands
- Additional libraries
- Team conventions

The configuration is designed to be flexible and extensible for different ML workflows and team preferences.