# Create Users and Groups Script: An Automated Approach

## Overview

`create_users.sh` is a Bash script for automating the creation of users and groups, setting up home directories, generating random passwords, logging actions, and securely storing passwords.

## Usage

### Basic Usage

To run the script:


`sudo ./create_users.sh users.txt` 

### Verbose Mode

For detailed output during execution:


`sudo ./create_users.sh -v users.txt` 

### Dry Run (Simulation)

To simulate user creation without making changes:


`sudo ./create_users.sh -d users.txt` 

### User List File Format

Ensure your `users.txt` file is formatted as follows:


    `username1;group1,group2
    username2;group3,group4` 

### Example

    light;sudo,dev,www-data
    idimma;sudo
    mayowa;dev,www-data

 

## Notes

-   The script logs actions to `/var/log/user_management.log`.
-   Passwords are securely stored in `/var/secure/user_passwords.txt`.
-   Existing password files are backed up before any changes are made.

[Article link](https://dev.to/labank_/creating-users-and-groups-with-a-bash-script-an-automated-approach-2399)

## Author

[Laban Kibet](https://github.com/Laban254/)

## License

This project is licensed under the MIT License.
