#!/bin/bash
# Setup script for acquisition system

set -e

echo "========================================="
echo "Business Acquisition System Setup"
echo "========================================="
echo

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "✓ Python $PYTHON_VERSION detected"

# Create virtual environment
echo
echo "Creating virtual environment..."
cd backend
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment
echo
echo "Activating virtual environment..."
source venv/bin/activate
echo "✓ Virtual environment activated"

# Install dependencies
echo
echo "Installing Python dependencies..."
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
echo "✓ Dependencies installed"

# Install Playwright browsers
echo
echo "Installing Playwright browsers..."
playwright install chromium
echo "✓ Playwright browsers installed"

# Create directories
echo
echo "Creating data directories..."
mkdir -p ../data/{raw,processed,models,training}
mkdir -p ../logs
echo "✓ Directories created"

# Copy environment file
echo
echo "Setting up environment configuration..."
if [ ! -f "../config/.env" ]; then
    cp ../config/.env.example ../config/.env
    echo "✓ Created .env file from template"
    echo
    echo "⚠ IMPORTANT: Edit config/.env with your API keys and configuration"
else
    echo "✓ .env file already exists"
fi

# Setup database
echo
echo "Database setup..."
echo "Run the following to set up your PostgreSQL database:"
echo "  1. Create database: createdb acquisition_system"
echo "  2. Run migrations: psql acquisition_system < database/schema.sql"
echo

# Check critical API keys
echo "Checking configuration..."
source ../config/.env 2>/dev/null || true

MISSING_KEYS=()

if [ -z "$DATABASE_URL" ]; then
    MISSING_KEYS+=("DATABASE_URL")
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    MISSING_KEYS+=("ANTHROPIC_API_KEY")
fi

if [ ${#MISSING_KEYS[@]} -gt 0 ]; then
    echo
    echo "⚠ Missing required configuration:"
    for key in "${MISSING_KEYS[@]}"; do
        echo "  - $key"
    done
    echo
    echo "Edit config/.env to add these values"
else
    echo "✓ Required configuration present"
fi

echo
echo "========================================="
echo "Setup complete!"
echo "========================================="
echo
echo "Next steps:"
echo "  1. Edit config/.env with your API keys"
echo "  2. Set up database:"
echo "     createdb acquisition_system"
echo "     psql acquisition_system < database/schema.sql"
echo "  3. Run the system:"
echo "     cd backend"
echo "     source venv/bin/activate"
echo "     python cli.py --help"
echo
