#!/usr/bin/env bash
#
# update-ansible-inventory.sh
# Purpose: Extract Terraform-managed public IP and update Ansible inventory
# Usage: ./update-ansible-inventory.sh (from scripts/ directory)
#        OR: ./scripts/update-ansible-inventory.sh (from project root)
#
# This script automatically detects project structure and can be run from
# anywhere within the project hierarchy.

# Exit on any error, undefined variable, or pipe failure
set -euo pipefail

# Script constants - dynamically determine paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
readonly ANSIBLE_INVENTORY="${PROJECT_ROOT}/ansible/inventory/hosts.yml"
readonly BACKUP_SUFFIX=".backup.$(date +%Y%m%d-%H%M%S)"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

#######################################
# Print error message to stderr and exit
# Arguments:
#   Error message string
#######################################
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

#######################################
# Print success message
# Arguments:
#   Success message string
#######################################
success_msg() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

#######################################
# Print info message
# Arguments:
#   Info message string
#######################################
info_msg() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

#######################################
# Validate IPv4 address format
# Arguments:
#   IP address string
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_ipv4() {
    local ip=$1
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ ! $ip =~ $ip_regex ]]; then
        return 1
    fi
    
    # Validate each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if ((octet < 0 || octet > 255)); then
            return 1
        fi
    done
    
    return 0
}

#######################################
# Check if required commands exist
#######################################
check_prerequisites() {
    local missing_cmds=()
    
    for cmd in terraform sed; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_cmds+=("$cmd")
        fi
    done
    
    if [ ${#missing_cmds[@]} -ne 0 ]; then
        error_exit "Missing required commands: ${missing_cmds[*]}"
    fi
}

#######################################
# Verify project structure
#######################################
verify_project_structure() {
    # Check if we're in the right directory structure
    if [ ! -d "$TERRAFORM_DIR" ]; then
        error_exit "Terraform directory not found at: $TERRAFORM_DIR
        
This script must be run from within the project directory structure."
    fi
    
    if [ ! -d "${PROJECT_ROOT}/ansible" ]; then
        error_exit "Ansible directory not found at: ${PROJECT_ROOT}/ansible
        
This script must be run from within the project directory structure."
    fi
}

#######################################
# Extract public IP from Terraform output
# Returns:
#   Public IP address string
#######################################
get_terraform_public_ip() {
    # Change to terraform directory
    cd "$TERRAFORM_DIR" || error_exit "Cannot access Terraform directory: $TERRAFORM_DIR"
    
    # Check if terraform state exists
    if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
        error_exit "No Terraform state found. Have you run 'terraform apply'?"
    fi
    
    # Get the minecraft_public_ip output
    local public_ip
    public_ip=$(terraform output -raw minecraft_public_ip 2>/dev/null) || \
        error_exit "Failed to retrieve terraform output 'minecraft_public_ip'.
        
Possible causes:
  - Terraform has not been applied yet
  - The output 'minecraft_public_ip' does not exist
  - Terraform state is corrupted
  
Run 'cd terraform && terraform output' to debug."
    
    # Check if IP is empty
    if [ -z "$public_ip" ]; then
        error_exit "Retrieved empty IP address from Terraform output"
    fi
    
    # Validate the IP address
    if ! validate_ipv4 "$public_ip"; then
        error_exit "Retrieved invalid IP address: $public_ip"
    fi
    
    echo "$public_ip"
}

#######################################
# Update Ansible inventory with new IP
# Arguments:
#   New IP address
#######################################
update_ansible_inventory() {
    local new_ip=$1
    
    # Verify inventory file exists
    if [ ! -f "$ANSIBLE_INVENTORY" ]; then
        error_exit "Ansible inventory not found: $ANSIBLE_INVENTORY
        
Expected location: ansible/inventory/hosts.yml
Create this file from the example: cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml"
    fi
    
    # Check if ansible_host line exists in inventory
    if ! grep -q "ansible_host:" "$ANSIBLE_INVENTORY"; then
        error_exit "No 'ansible_host:' line found in inventory file: $ANSIBLE_INVENTORY
        
Please ensure your inventory file has the correct format."
    fi
    
    # Create backup before modification
    cp "$ANSIBLE_INVENTORY" "${ANSIBLE_INVENTORY}${BACKUP_SUFFIX}" || \
        error_exit "Failed to create backup of inventory file"
    
    info_msg "Backup created: ${ANSIBLE_INVENTORY}${BACKUP_SUFFIX}"
    
    # Update the ansible_host value using sed
    # Pattern explanation:
    #   ^\\( *ansible_host: *\\) - Match 'ansible_host:' with any surrounding spaces
    #   [0-9.]* - Match the old IP address
    #   \\1${new_ip} - Replace with captured group (ansible_host:) + new IP
    sed -i.tmp "s|^\( *ansible_host: *\)[0-9.]*$|\1${new_ip}|" "$ANSIBLE_INVENTORY" || \
        error_exit "Failed to update inventory file"
    
    # Remove temporary file created by sed -i
    rm -f "${ANSIBLE_INVENTORY}.tmp"
    
    # Verify the change was made
    if ! grep -q "ansible_host: ${new_ip}" "$ANSIBLE_INVENTORY"; then
        error_exit "IP update verification failed. The inventory file may not be in expected format.
        
Expected format:
  ansible_host: x.x.x.x

Check $ANSIBLE_INVENTORY manually."
    fi
}

#######################################
# Display next steps
#######################################
display_next_steps() {
    local public_ip=$1
    
    echo ""
    echo "========================================"
    echo "Next Steps:"
    echo "========================================"
    echo "  1. Verify the update:"
    echo "     cat ${ANSIBLE_INVENTORY}"
    echo ""
    echo "  2. Test SSH connectivity:"
    echo "     ssh -i ~/.ssh/id_rsa <username>@${public_ip}"
    echo ""
    echo "  3. Test Ansible connectivity:"
    echo "     ansible minecraft_server -m ping"
    echo ""
    echo "  4. Run your playbook:"
    echo "     cd ${PROJECT_ROOT}/ansible"
    echo "     ansible-playbook playbooks/site.yml"
    echo ""
}

#######################################
# Main execution function
#######################################
main() {
    echo "========================================"
    echo "Ansible Inventory Update Script"
    echo "========================================"
    echo "Project Root: ${PROJECT_ROOT}"
    echo ""
    
    # Check prerequisites
    info_msg "Checking prerequisites..."
    check_prerequisites
    
    # Verify project structure
    info_msg "Verifying project structure..."
    verify_project_structure
    
    # Get public IP from Terraform
    info_msg "Retrieving public IP from Terraform state..."
    local public_ip
    public_ip=$(get_terraform_public_ip)
    success_msg "Found public IP: $public_ip"
    
    # Update Ansible inventory
    info_msg "Updating Ansible inventory file..."
    update_ansible_inventory "$public_ip"
    
    # Success message
    success_msg "Ansible inventory updated successfully!"
    
    # Display next steps
    display_next_steps "$public_ip"
}

# Execute main function
main "$@"

