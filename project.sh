#!/bin/bash

TRASH_DIR="$PWD/.trash"
DELETED_LOG="$PWD/.deleted_files.log"


mkdir -p "$TRASH_DIR"
touch "$DELETED_LOG"

show_progress() {
    local message=$1
    {
        for ((i = 0; i <= 100; i+=5)); do
            sleep 0.1
            echo $i
        done
    } | whiptail --gauge "$message" 6 50 0
}

show_output() {
    local message=$1
    whiptail --title "Output" --msgbox "$message" 20 60
}

show_textbox() {
    local file=$1
    whiptail --title "Output" --textbox "$file" 20 60
}

restore_file() {
    local file=$1
    if [ -f "$TRASH_DIR/$file" ]; then
        mv "$TRASH_DIR/$file" .
        show_output "File restored successfully."
    else
        whiptail --msgbox "File does not exist in trash." 8 39
    fi
}

permanently_delete_file() {
    local file=$1
    if [ -f "$file" ]; then
        echo "$file was deleted at $(date)" >> "$DELETED_LOG"
        rm "$file"
        show_output "File permanently deleted."
    else
        whiptail --msgbox "File does not exist." 8 39
    fi
}

sign_up() {
    users=($(cat user_name.csv 2>/dev/null))
    username=$(whiptail --inputbox "Enter Username:" 8 39 3>&1 1>&2 2>&3)
    for user in "${users[@]}"; do
        if [ "$user" = "$username" ]; then
            whiptail --msgbox "Username already exists! Please use a different username." 8 39
            sign_up
            return
        fi
    done
    
    password=""
    while [ ${#password} -lt 6 ]; do
        password=$(whiptail --passwordbox "Enter Password (at least 6 characters):" 8 39 3>&1 1>&2 2>&3)
        if [ ${#password} -lt 6 ]; then
            whiptail --msgbox "Password must be at least 6 characters long." 8 39
        fi
    done

    conf_password=$(whiptail --passwordbox "Confirm Password:" 8 39 3>&1 1>&2 2>&3)
    if [ "$password" != "$conf_password" ]; then
        whiptail --msgbox "Passwords do not match. Please try again." 8 39
        sign_up
        return
    fi

    echo "$username" >> user_name.csv
    echo "$password" >> password.csv
    whiptail --msgbox "Signup successful!" 8 39
}

sign_in() {
    users=($(cat user_name.csv 2>/dev/null))
    passwords=($(cat password.csv 2>/dev/null))
    attempts=4
    while [ $attempts -gt 0 ]; do
        username=$(whiptail --inputbox "Enter Username:" 8 39 3>&1 1>&2 2>&3)
        found=0
        for i in "${!users[@]}"; do
            if [ "${users[$i]}" = "$username" ]; then
                found=1
                break
            fi
        done
        if [ $found -eq 1 ]; then
            break
        else
            attempts=$((attempts - 1))
            whiptail --msgbox "Username does not exist. You have $attempts attempts remaining." 8 39
        fi
    done

    if [ $attempts -le 0 ]; then
        whiptail --msgbox "Too many attempts. Please try again later." 8 39
        exit 1
    fi

    attempts=4
    while [ $attempts -gt 0 ]; do
        password=$(whiptail --passwordbox "Enter Password:" 8 39 3>&1 1>&2 2>&3)
        if [ "$password" = "${passwords[$i]}" ]; then
            whiptail --msgbox "Login successful!" 8 39
            return
        else
            attempts=$((attempts - 1))
            whiptail --msgbox "Wrong password. You have $attempts attempts remaining." 8 39
        fi
    done

    whiptail --msgbox "Too many attempts. Please try again later." 8 39
    exit 1
}

# Main script starts here

header() {
    whiptail --title "Welcome" --msgbox "OS - File Controlling System" 10 60
}

welcome() {
    choice=$(whiptail --title "Login/Signup" --menu "Choose an option" 15 50 2 \
        "1" "Sign In" \
        "2" "Sign Up" 3>&2 2>&1 1>&3)
    
    case $choice in
        1)
            sign_in
            ;;
        2)
            sign_up
            ;;
        *)
            exit 0
            ;;
    esac
}

header
welcome

while true; do
    opt=$(whiptail --title "MAIN MENU" --menu "" 20 60 10 \
        1 "List All Files and Directories." \
        2 "Create New Files." \
        3 "Edit File Content." \
        4 "Rename Files." \
        5 "Search Files." \
        6 "Details of Particular File." \
        7 "Count Number of Files." \
        8 "Sort File Content." \
        9 "List only Directories in Folders." \
        10 "Count Number of Directories." \
        11 "View Content of File." \
        12 "Temporary Delete File." \
        13 "Permanent Delete File." \
        14 "View Trash and Restore Files." \
        0 "End Menu" 3>&2 2>&1 1>&3
    )

    case $opt in
        1)
            show_progress "Loading..."
            output=$(ls)
            show_output "$output"
            ;;
        2)
            fileName=$(whiptail --inputbox "Enter File Name:" 8 39 3>&1 1>&2 2>&3)
            touch "$fileName"
            show_progress "Creating..."
            show_output "File Created Successfully"
            ;;
        3)
            edit=$(whiptail --inputbox "Enter File Name with Extension:" 8 39 3>&1 1>&2 2>&3)
            show_progress "Checking File..."
            
            if [ -f "$edit" ]; then
                show_progress "Opening..."
                nano "$edit"
            else
                whiptail --msgbox "$edit File does not exist..Try again." 8 39
            fi
            ;;
        4)
            old=$(whiptail --inputbox "Enter Old Name of File with Extension:" 8 39 3>&1 1>&2 2>&3)
            show_progress "Checking File..."
    
            if [ -f "$old" ]; then
                new=$(whiptail --inputbox "Enter New Name for file with Extension:" 8 39 3>&1 1>&2 2>&3)
                mv "$old" "$new"
                show_progress "Renaming..."
                show_output "Successfully Renamed. Now Your File Exists with $new Name"
            else
                whiptail --msgbox "$old does not exist..Try again with correct filename." 8 39
            fi
            ;;
        5)
            f=$(whiptail --inputbox "Enter File Name with Extension to search:" 8 39 3>&1 1>&2 2>&3)
            
            show_progress "Searching for $f file..."
            
            output=$(find . -name "$f" 2>/dev/null)
            if [ -n "$output" ]; then
                show_output "File Found: $output"
            else
                whiptail --msgbox "File Does not Exist..Try again." 8 39
            fi
            ;;
        6)
            detail=$(whiptail --inputbox "Enter File Name with Extension to see Detail:" 8 39 3>&1 1>&2 2>&3)
            
            show_progress "Checking..."
            
            if [ -f "$detail" ]; then
                show_progress "Loading Properties..."
                output=$(stat "$detail")
                show_output "$output"
            else
                whiptail --msgbox "$detail File does not exist..Try again" 8 39
            fi
            ;;
        7)
            show_progress "Counting..."
            output=$(ls -l | grep -v 'total' | wc -l)
            show_output "Number of Files are: $output"
            ;;
        8)
            sortfile=$(whiptail --inputbox "Enter File Name with Extension to sort:" 8 39 3>&1 1>&2 2>&3)
            
            show_progress "Sorting..."
            
            if [ -f "$sortfile" ]; then
                output=$(sort "$sortfile")
                show_output "$output"
            else
                whiptail --msgbox "$sortfile File does not exist..Try again." 8 39
            fi
            ;;
        9)
            show_progress "Loading..."
            output=$(ls -d */)
            show_output "$output"
            ;;
        10)
            show_progress "Loading..."
            output=$(echo */ | wc -w)
            show_output "Number of Directories are: $output"
            ;;
        11)
            readfile=$(whiptail --inputbox "Enter File Name:" 8 39 3>&1 1>&2 2>&3)
            
            show_progress "Showing..."
            
            if [ -f "$readfile" ]; then
                show_textbox "$readfile"
            else
                whiptail --msgbox "$readfile does not exist" 8 39
            fi
            ;;
        12)
            delFile=$(whiptail --inputbox "Enter name of File you want to Temporary Delete:" 8 39 3>&1 1>&2 2>&3)
            
            show_progress "Deleting..."
                    
            if [ -f "$delFile" ]; then
                if mv "$delFile" "$TRASH_DIR"; then
                    show_output "File moved to trash."
                else
                    whiptail --msgbox "Failed to move file to trash." 8 39
                fi
            else
                whiptail --msgbox "File Does not Exist..Try again" 8 39
            fi
            ;;
        13)
            delFile=$(whiptail --inputbox "Enter name of File you want to Permanent Delete:" 8 39 3>&1 1>&2 2>&3)
            
            show_progress "Deleting..."
            
            permanently_delete_file "$delFile"
            ;;
        14)
            if [ -n "$(ls -A $TRASH_DIR)" ]; then
                trash_files=$(ls "$TRASH_DIR")
                file_to_restore=$(whiptail --title "Trash" --menu "Select file to restore:" 20 60 12 $(for f in $trash_files; do echo "$f [Trash]"; done) 3>&2 2>&1 1>&3)
                
                if [ -n "$file_to_restore" ]; then
                    restore_file "$file_to_restore"
                fi
            else
                whiptail --msgbox "Trash is empty." 8 39
            fi
            ;;
        0)
            show_progress "Closing..."
            show_output "Successfully Exit..."
            exit 0
            ;;
        *)
            whiptail --msgbox "Invalid Input! Try again...." 8 39
            ;;
    esac
done
