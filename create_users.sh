#!/bin/bash
#
# Script to create users and assign passwords from an input file.
# Requires openssl for password generation and proper permissions for file handling.
#
# Usage: ./user_creation_script.sh <user_list_file>
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
# Author: [Your Name]
# Date: [Date]

# Define log file and secure password file
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"
BACKUP_FILE="/var/secure/user_passwords.txt.bak"

# Create necessary directories and set permissions
mkdir -p /var/secure
touch "$LOG_FILE"
touch "$PASSWORD_FILE"

chmod 644 "$LOG_FILE"
chmod 400 "$PASSWORD_FILE"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    [ "$verbose" = true ] && echo "$1"
}

# Function to handle errors and log messages
handle_error() {
    local error_message="$1"
    log_message "$error_message"
    error_count=$((error_count + 1))
}

# Function to generate hashed password
generate_hashed_password() {
    local password="$1"
    echo "$(openssl passwd -6 -salt xyz "$password")"
}

# Backup existing password file
if [ -f "$PASSWORD_FILE" ]; then
    cp "$PASSWORD_FILE" "$BACKUP_FILE"
    log_message "Existing password file backed up to $BACKUP_FILE."
fi

# Initialize error counter
error_count=0

# Check if the input file is provided
if [ -z "$1" ]; then
    echo "⛔ Error: Input file not provided."
    exit 1
fi
USER_LIST_FILE=$1

# Check if the input file exists
if [ ! -f "$USER_LIST_FILE" ]; then
    echo "⛔ Error: File '$USER_LIST_FILE' not found."
    exit 1
fi

# Read the file line by line
while IFS=';' read -r raw_username raw_groups; do
    # Trim whitespaces
    username=$(echo "$raw_username" | xargs)
    groups=$(echo "$raw_groups" | xargs)

    # Skip empty lines
    if [ -z "$username" ]; then
        log_message "Skipped empty or invalid line."
        continue
    fi

    if id "$username" &>/dev/null; then
        log_message "User $username already exists."
        continue
    fi

    # Create personal group with error handling
    if ! getent group "$username" &>/dev/null; then
        if [ "$dry_run" = false ]; then
            if ! groupadd "$username"; then
                handle_error "⛔ Failed to create group $username."
            else
                log_message "Group $username created."
            fi
        else
            log_message "Simulated creation of group $username."
        fi
    fi

    # Create user and home directory with error handling
    if [ "$dry_run" = false ]; then
        if ! useradd -m -g "$username" -s /bin/bash "$username"; then
            handle_error "⛔ Failed to create user $username."
            continue
        else
            log_message "User $username created with home directory."
        fi
    else
        log_message "Simulated creation of user $username with home directory."
    fi

    # Assign additional groups with error handling
    IFS=',' read -ra ADDR <<< "$groups"
    for group in "${ADDR[@]}"; do
        group=$(echo "$group" | xargs) # Trim whitespaces
        if [ -z "$group" ]; then
            continue
        fi
        if ! getent group "$group" &>/dev/null; then
            if [ "$dry_run" = false ]; then
                if ! groupadd "$group"; then
                    handle_error "⛔ Failed to create group $group."
                else
                    log_message "Group $group created."
                fi
            else
                log_message "Simulated creation of group $group."
            fi
        fi
        if [ "$dry_run" = false ]; then
            if ! usermod -aG "$group" "$username"; then
                handle_error "⛔ Failed to add user $username to group $group."
            else
                log_message "User $username added to group $group."
            fi
        else
            log_message "Simulated addition of user $username to group $group."
        fi
    done

    # Generate and assign hashed password
    password=$(openssl rand -base64 12)
    hashed_password=$(generate_hashed_password "$password")
    if [ "$dry_run" = false ]; then
        echo "$username:$hashed_password" >> "$PASSWORD_FILE"
        log_message "Hashed password stored for user $username."
    else
        log_message "Simulated hashed password setting for user $username."
    fi
done < "$USER_LIST_FILE"

log_message "User creation process completed with $error_count errors."
echo "📯 User creation process completed with $error_count errors."
echo "Check $LOG_FILE for details and $PASSWORD_FILE for hashed passwords."
