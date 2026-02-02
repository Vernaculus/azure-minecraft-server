#!/bin/bash

# Script: stop-minecraft-vm.sh
# Purpose: Deallocate Azure Minecraft VM to stop compute charges
# Usage: ./stop-minecraft-vm.sh

# Strict error handling: exit on errors, undefined variables, and pipeline failures
set -e
set -u
set -o pipefail

# VM configuration variables
readonly VM_NAME="vm-minecraft-dev-scus"
readonly RESOURCE_GROUP="rg-minecraft-dev-scus"

# ANSI color codes for terminal output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Colored output helper functions
print_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2  # Send errors to stderr
}

# Calculate human-readable duration from ISO 8601 timestamp to now
# Converts Azure timestamp to days/hours/minutes format
calculate_duration() {
    local start_time="$1"
    local current_time=$(date -u +%s)  # Current time in epoch seconds
    
    # Convert ISO 8601 timestamp to epoch, fallback to 0 on parse failure
    local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "0")
    
    if [[ "$start_epoch" -eq 0 ]]; then
        echo "unknown duration"
        return
    fi
    
    local diff=$((current_time - start_epoch))
    
    # Break down seconds into days, hours, minutes
    local days=$((diff / 86400))
    local hours=$(((diff % 86400) / 3600))
    local minutes=$(((diff % 3600) / 60))
    
    # Format output based on largest non-zero unit
    if [[ $days -gt 0 ]]; then
        echo "${days}d ${hours}h ${minutes}m"
    elif [[ $hours -gt 0 ]]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

main() {
    echo "========================================"
    echo "Azure Minecraft VM Deallocation Script"
    echo "========================================"
    echo ""
    
    # Verify Azure CLI is installed and available in PATH
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Verify user has active Azure authentication session
    print_status "Checking Azure CLI authentication status..."
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure CLI. Run 'az login' first."
        exit 1
    fi
    print_success "Azure CLI authenticated"
    echo ""
    
    # Query current VM power state to avoid unnecessary operations
    print_status "Checking current VM status..."
    
    # Get power state from Azure (e.g., "VM running", "VM deallocated", "VM stopped")
    POWER_STATE=$(az vm show \
        --name "${VM_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --show-details \
        --query "powerState" \
        --output tsv)
    
    # If VM is already deallocated, display status and duration then exit early
    if [[ "${POWER_STATE}" == "VM deallocated" ]]; then
        # Get ProvisioningState timestamp (PowerState/deallocated typically has no time field)
        # This represents when the VM was last provisioned/deallocated
        PROVISION_TIME=$(az vm get-instance-view \
            --name "${VM_NAME}" \
            --resource-group "${RESOURCE_GROUP}" \
            --query "instanceView.statuses[?starts_with(code, 'ProvisioningState')].time | [0]" \
            --output tsv 2>/dev/null || echo "")
        
        echo ""
        echo "========================================"
        print_success "VM is already deallocated!"
        echo "========================================"
        echo ""
        echo "VM Name: ${VM_NAME}"
        echo "Power State: ${POWER_STATE}"
        
        # Display deallocation duration if timestamp was successfully retrieved
        if [[ -n "${PROVISION_TIME}" && "${PROVISION_TIME}" != "null" ]]; then
            DEALLOCATED_TIME=$(calculate_duration "${PROVISION_TIME}")
            echo "Deallocated since: ${DEALLOCATED_TIME} ago"
        fi
        
        echo ""
        print_status "Compute charges are not accruing"
        exit 0
    fi
    
    # VM is not deallocated, display current state and proceed with deallocation
    print_status "Current VM state: ${POWER_STATE}"
    echo ""
    
    # Initiate VM deallocation operation
    # Note: Deallocate releases compute resources and stops billing, unlike stop
    print_status "Deallocating VM: ${VM_NAME}"
    print_status "Resource Group: ${RESOURCE_GROUP}"
    print_status "This will stop the VM and release compute resources"
    print_status "This may take 1-2 minutes. Please wait..."
    echo ""
    
    # Execute deallocate command with explicit error handling
    if az vm deallocate \
        --name "${VM_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --output none; then
        print_success "VM deallocate command completed successfully"
    else
        print_error "Failed to deallocate VM"
        exit 1
    fi
    
    echo ""
    print_status "Verifying VM power state..."
    
    # Re-query power state to confirm VM reached deallocated state
    POWER_STATE=$(az vm show \
        --name "${VM_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --show-details \
        --query "powerState" \
        --output tsv)
    
    # Verify successful deallocation
    if [[ "${POWER_STATE}" == "VM deallocated" ]]; then
        echo ""
        echo "========================================"
        print_success "VM has been deallocated!"
        echo "========================================"
        echo ""
        echo "VM Name: ${VM_NAME}"
        echo "Power State: ${POWER_STATE}"
        echo ""
        print_status "Compute charges have stopped"
        exit 0
    else
        # Deallocate command succeeded but VM didn't reach deallocated state (unusual condition)
        echo ""
        print_error "VM did not reach deallocated state"
        echo "Current Power State: ${POWER_STATE}"
        exit 1
    fi
}

# Script entry point - execute main function
# Due to 'set -e', any failure in main will terminate the script
main

