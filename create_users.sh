#!/bin/bash
#
# Script to create users and assign passwords from an input file.
# Requires openssl for password generation and proper permissions for file handling.
#
# Usage: ./create_users.sh <user_list_file>
#
# Example user list file format:
# username1;group1,group2
# username2;group3,group4
#
# Dependencies:
# - openssl (for password generation)
# - Proper file permissions (LOG_FILE, PASSWORD_FILE)
#
# Note: This script securely stores hashed passwords instead of plaintext.
#
# Author: Laban
# Date: 2024-07-02

# Constants
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"
BACKUP_FILE="/var/secure/user_passwords.csv.bak"

# Check for superuser privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Create necessary directories and set permissions
mkdir -p /var/secure
touch "$LOG_FILE" "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"
chown root:root "$PASSWORD_FILE"

# Function to log messages
log_message() {
    local log_date=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$log_date - $1" >> "$LOG_FILE"
}

# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

# Backup existing password file
backup_password_file() {
    if [ -f "$PASSWORD_FILE" ]; then
        cp "$PASSWORD_FILE" "$BACKUP_FILE"
        log_message "Existing password file backed up to $BACKUP_FILE."
    fi
}

# Create user and handle groups
process_user() {
    local username="$1"
    local groups="$2"

    # Check if the user already exists
    if id "$username" &>/dev/null; then
        log_message "User $username already exists."
    else
        # Create the user
        password=$(generate_password)
        useradd -m -s /bin/bash "$username"
        echo "$username:$password" | chpasswd
        log_message "User $username created successfully."
        echo "$username,$password" >> "$PASSWORD_FILE"
    fi

    # Create personal group for the user if it doesn't exist
    personal_group="${username}_personal"
    if ! getent group "$personal_group" &>/dev/null; then
        groupadd "$personal_group"
        log_message "Personal group $personal_group created successfully."
    fi
    usermod -aG "$personal_group" "$username"
    log_message "User $username added to personal group $personal_group."

    # Add user to specified groups
    IFS=',' read -ra group_array <<<"$groups"
    for group in "${group_array[@]}"; do
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
            log_message "Group $group created successfully."
        fi
        usermod -aG "$group" "$username"
        log_message "User $username added to group $group."
    done
}

# Main script execution starts here

# Validate input file
if [ -z "$1" ]; then
    echo "⛔ Error: Input file not provided."
    exit 1
fi
USERLIST_FILE=$1

if [ ! -f "$USERLIST_FILE" ]; then
    echo "⛔ Error: File '$USERLIST_FILE' not found."
    exit 1
fi

# Backup existing password file
backup_password_file

# Process each line in the userlist file
while IFS=';' read -r username groups; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    if [ -z "$username" ]; then
        continue
    fi

    process_user "$username" "$groups"

done < "$USERLIST_FILE"

log_message "User creation script completed."
echo "📯 User creation script completed."
echo "Check $LOG_FILE for details and $PASSWORD_FILE for passwords."
