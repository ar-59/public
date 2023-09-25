#!/bin/bash

# Ensure the script is executed with sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (with sudo)."
   exit 1
fi

# Define the command to add to .bashrc
command_to_add="PROMPT_COMMAND='history -a'"
timestamp_command="export HISTTIMEFORMAT='%F %T '"  # Add this command to enable history timestamps

# Iterate through all users in /home and root
for user_dir in /home/* /root; do
   user=$(basename "$user_dir")

   # Check if .bashrc exists for the user
   if [ -f "$user_dir/.bashrc" ]; then
      # Append the command to .bashrc
      echo "$command_to_add" | tee -a "$user_dir/.bashrc" > /dev/null
      echo "$timestamp_command" | tee -a "$user_dir/.bashrc" > /dev/null
      echo "Added $command_to_add to $user's .bashrc" | wall
   else
      echo "$user does not have a .bashrc file." | wall
   fi
done

echo "Script completed." | wall

# Define excluded editors
excluded_editors=("vi" "nano" "vim" "emacs")  # Add other editors if needed

# Check if any excluded editor is running
for editor in "${excluded_editors[@]}"; do
    if pgrep "$editor" >/dev/null; then
        echo "An excluded editor ($editor) is running. Exiting the script."
        exit 0  # Exit the script
    fi
done

# Set thresholds for idle times in seconds
shutdown_threshold=600  # 15 minutes

# Get the list of all non-root users
#users=$(who | awk '$1 != "root" {print $1}')

# Get the list of all users (including root)
users=$(who | awk '{print $1}')

# Include the root user explicitly
users="$users root"

# Print the list of users using wall
echo "$users" | wall

# Initialize a flag to track whether all users meet the criteria
all_users_met_criteria=true

# Loop through all users
for user in $users; do
    # Get the user's home directory
    user_home=$(eval echo ~$user)

    # Check if the user's .bash_history file exists
    history_file="$user_home/.bash_history"

    if [ -f "$history_file" ]; then
        # Calculate the time difference based on the last modification time of .bash_history
        current_time=$(date +%s)
        last_modification_time_seconds=$(stat -c %Y "$history_file")
        time_difference=$((current_time - last_modification_time_seconds))

        # Check if the user's bash history file meets the validation criteria
        if [ "$time_difference" -le "$shutdown_threshold" ]; then
            all_users_met_criteria=false
            break  # Exit the loop as soon as one user's criteria is not met
        fi
    fi
done

# Check if all users met the criteria before initiating a shutdown
if [ "$all_users_met_criteria" = true ]; then
    echo "Machine is idle. Initiating automatic shutdown." | wall
 #   sudo shutdown -h now
elif [ "$all_users_met_criteria" = false ]; then
    echo "Machine is idle. Please use the terminal else will shut down in 10 minutes." | wall
fi

