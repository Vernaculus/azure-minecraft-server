#!/bin/bash
# Script: start-minecraft-vm.sh
# Purpose: Start Azure Minecraft VM and verify it's running
# Usage: ./start-minecraft-vm.sh

# Enable strict error handling
set -e          # Exit immediately if any command fails
set -u          # Treat unset variables as errors
set -o pipefail # Fail if any command in a pipeline fails

# Define VM details as variables for easy maintenance
readonly VM_NAME="vm-minecraft-dev-scus"
readonly RESOURCE_GROUP="rg-minecraft-dev-scus"

# Color codes for better terminal output readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Main execution starts here
main() {
    echo "========================================"
    echo "Azure Minecraft VM Startup Script"
    echo "========================================"
    echo ""

    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed or not in PATH"
        exit 1
    fi

    # Verify Azure CLI is logged in
    print_status "Checking Azure CLI authentication status..."
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure CLI. Run 'az login' first."
        exit 1
    fi
    print_success "Azure CLI authenticated"
    echo ""

    # Start the VM
    print_status "Starting VM: ${VM_NAME}"
    print_status "Resource Group: ${RESOURCE_GROUP}"
    print_status "This may take 1-2 minutes. Please wait..."
    echo ""

    # Execute the start command with error handling
    if az vm start \
        --name "${VM_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --output none; then
        print_success "VM start command completed successfully"
    else
        print_error "Failed to start VM"
        exit 1
    fi

    echo ""
    print_status "Verifying VM power state..."
    
    # Query the VM power state
    POWER_STATE=$(az vm show \
        --name "${VM_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --show-details \
        --query "powerState" \
        --output tsv)

    # Check if the VM is actually running
    if [[ "${POWER_STATE}" == "VM running" ]]; then
        echo ""
        echo "========================================"
        print_success "VM is now running!"
        echo "========================================"
        echo ""
        echo "VM Name: ${VM_NAME}"
        echo "Power State: ${POWER_STATE}"
        exit 0
    else
        echo ""
        print_error "VM did not reach running state"
        echo "Current Power State: ${POWER_STATE}"
        exit 1
    fi
}

# Run main function
# If main fails, the script will exit due to 'set -e'
main

