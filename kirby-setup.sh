#!/bin/bash

# Function to check if a command is installed
check_command() {
    local command=$1
    if ! command -v "$command" &> /dev/null; then
        echo "Error: $command is not installed. Please install it and try again."
        exit 1
    fi
}

# Function to install Kirby
install_kirby() {
    local project_name=$1

    echo "Installing Kirby via Composer..."
    composer create-project getkirby/plainkit "${project_name}-site"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Kirby."
        exit 1
    fi

    echo "Kirby installed successfully."
}

# Function to set up the custom content folder
setup_content_folder() {
    local project_name=$1
    local project_dir="${project_name}-site"

    # Check if the "content" folder exists
    if [ -d "$project_dir/content" ]; then
        # Move the "content" folder to the current directory
        mv "$project_dir/content" ./
        echo "Moved 'content' folder to the current directory."
    else
        echo "Error: 'content' folder not found in the project directory."
        exit 1
    fi

    # Rename the "content" folder to "*project-folder-name*-content"
    if [ -d "content" ]; then
        mv "content" "${project_name}-content"
        echo "Renamed 'content' folder to '${project_name}-content'."
    else
        echo "Error: 'content' folder not found in the current directory."
        exit 1
    fi

    # Update the index.php file with the new Kirby root config
    update_index_php "$project_name" "$project_dir"
}

# Function to update the index.php file
update_index_php() {
    local project_name=$1
    local project_dir=$2
    local index_file="$project_dir/index.php"

    # Check if the index.php file exists
    if [ -f "$index_file" ]; then
        # Backup the original index.php file
        cp "$index_file" "${index_file}.bak"
        echo "Backup of 'index.php' created as 'index.php.bak'."

        # Replace the contents of index.php with the new configuration
        cat <<EOL > "$index_file"
<?php

include __DIR__ . '/kirby/bootstrap.php';

\$kirby = new Kirby([
    'roots' => [
        'content' => dirname(__DIR__) . '/${project_name}-content'
    ]
]);

echo \$kirby->render();
EOL

        echo "index.php has been updated successfully."
    else
        echo "Error: index.php not found in the project directory."
        exit 1
    fi
}

# Function to set up Git
setup_git() {
    local project_dir="${1}-site"
    echo "Setting up Git..."
    # Exclude unwanted folders
    echo -e "\n# Local Installation Files\n# ---------------\n\n/kirby\n/vendor" >> "$project_dir/.gitignore"
    echo "Gitignore updated to exclude unwanted folders."
}

# Main function to set up the Kirby project
setup_kirby_project() {
    # Prompt the user for the project name
    read -p "Enter the project name: " project_name

    echo "Starting Kirby installation process..."
    install_kirby "$project_name"
    echo "Setting up the custom content folder..."
    setup_content_folder "$project_name"
    setup_git "$project_name"
    echo "Kirby project setup completed successfully."
}

# Check for required tools
echo "Checking for required tools..."
check_command "gh"
check_command "composer"
check_command "php"
check_command "node"
check_command "npm"
echo "All required tools are installed."

# Call the main function
setup_kirby_project
