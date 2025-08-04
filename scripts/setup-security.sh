#!/bin/bash

# Security Audit Setup Script
# This script clones the private esm-security-tools repository and runs the security setup

set -e  # Exit on any error

ENV_FILE=".env"
REPO_URL="https://github.com/esmagico/esm-security-tools.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to cleanup on exit
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        print_status "Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
        print_success "Cleanup completed"
    fi
}

# Set trap to ensure cleanup happens even on script failure
trap cleanup EXIT

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    print_error ".env file not found in current directory"
    print_error "Please create a .env file with GITHUB_PAT variable"
    exit 1
fi

print_status "Reading environment variables from $ENV_FILE..."

# Extract GITHUB_PAT from .env file
GITHUB_PAT=$(grep '^GITHUB_PAT=' "$ENV_FILE" 2>/dev/null | cut -d '=' -f2 | tr -d '"' | tr -d "'")

if [ -z "$GITHUB_PAT" ]; then
    print_error "GITHUB_PAT not found in .env file"
    print_error "Please add GITHUB_PAT=your_token_here to your .env file"
    print_warning "You need a GitHub Personal Access Token with repository access"
    exit 1
fi

print_success "GITHUB_PAT found in environment"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
print_status "Created temporary directory: $TEMP_DIR"

# Change to temporary directory
cd "$TEMP_DIR"

# Clone repository with authentication
print_status "📥 Downloading security tools from private repository..."

# Use GITHUB_PAT for authentication
AUTHENTICATED_URL="https://${GITHUB_PAT}@github.com/esmagico/esm-security-tools.git"

if git clone "$AUTHENTICATED_URL" esm-security-tools; then
    print_success "Repository cloned successfully"
else
    print_error "Failed to clone repository. Please check your GITHUB_PAT permissions"
    exit 1
fi

# Change to repository directory
cd esm-security-tools

# Check if required files exist
if [ ! -f "setup_security.sh" ]; then
    print_error "setup_security.sh not found in repository"
    exit 1
fi

# Make scripts executable
print_status "Making scripts executable..."
chmod +x setup_security.sh

if [ -f "password_strength_checker.py" ]; then
    chmod +x password_strength_checker.py
fi

if [ -f "install.sh" ]; then
    chmod +x install.sh
fi

print_success "Scripts made executable"

# Check if sudo is available and user has sudo privileges
if ! command -v sudo &> /dev/null; then
    print_error "sudo command not found. This script requires sudo privileges"
    exit 1
fi

# Run setup script with sudo
print_status "⚙️  Running security setup script..."
print_warning "This step requires sudo privileges and may prompt for your password"

if sudo -E ./setup_security.sh; then
    print_success "Security audit tools setup completed successfully!"
    print_success "The security tools have been installed and configured on your system"
else
    print_error "Setup script failed. Please check the output above for details"
    exit 1
fi

print_success "🎉 Security audit setup completed successfully!"