#!/bin/bash

# Function to check if a command is installed
check_command() {
    local command=$1
    if ! command -v "$command" &> /dev/null; then
        echo "Error: $command is not installed. Please install it and try again."
        exit 1
    fi
}

# Function to convert a string to kebab-case
to_kebab_case() {
    local input="$1"
    # Convert to lowercase
    local lowercase_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    # Replace spaces and special characters with hyphens
    local kebab_case=$(echo "$lowercase_input" | tr -c '[:alnum:]' '-' | tr -s '-')
    # Remove leading and trailing hyphens
    echo "${kebab_case#-}" | sed 's/-$//'
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
    local project_name=$1
    local original_project_name=$2
    local project_dir="${project_name}-site"
    local content_dir="${project_name}-content"

    # Initialize local Git repositories
    echo "Initializing local Git repository for the site..."
    cd "$project_dir" || exit
    git init
    git branch -M main
    echo -e "\n# Local Installation Files\n# ---------------\n\n/kirby\n/vendor" >> .gitignore
    echo -e "# ${original_project_name} - Website source code\nThis is the main site repository for the ${original_project_name} site." > README.md
    git add .
    git commit -m "Initial commit"
    cd ..

    echo "Initializing local Git repository for the content..."
    cd "$content_dir" || exit
    git init
    git branch -M main
    echo -e "# ${original_project_name} - Website content\nThis is the content repository for the ${original_project_name} site." > README.md
    git add .
    git commit -m "Initial commit"
    cd ..

    # Create GitHub repositories
    echo "Creating GitHub repository for the site..."
    gh repo create "${project_name}-site" --private --source="$project_dir" --remote=upstream --push
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create GitHub repository for the site."
        exit 1
    fi

    echo "Creating GitHub repository for the content..."
    gh repo create "${project_name}-content" --private --source="$content_dir" --remote=upstream --push
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create GitHub repository for the content."
        exit 1
    fi

    echo "Git repositories set up successfully."
}

# Function to delete the GitHub repositories
delete_github_repos() {
    local project_name=$1

    # Ensure the necessary permissions
    echo "Ensuring necessary permissions for deleting repositories..."
    gh auth refresh -h github.com -s delete_repo
    if [ $? -ne 0 ]; then
        echo "Error: Failed to refresh GitHub authentication. Please ensure you have the necessary permissions."
        exit 1
    fi

    # Delete GitHub repositories
    echo "Deleting GitHub repository for the site..."
    gh repo delete "${project_name}-site" --yes
    if [ $? -ne 0 ]; then
        echo "Error: Failed to delete GitHub repository for the site."
        exit 1
    fi

    echo "Deleting GitHub repository for the content..."
    gh repo delete "${project_name}-content" --yes
    if [ $? -ne 0 ]; then
        echo "Error: Failed to delete GitHub repository for the content."
        exit 1
    fi

    echo "GitHub repositories deleted successfully."
}

# Function to remove the local folders
remove_local_folders() {
    local project_name=$1
    local project_dir="${project_name}-site"
    local content_dir="${project_name}-content"

    # Remove local folders
    echo "Removing local site folder..."
    rm -rf "$project_dir"

    echo "Removing local content folder..."
    rm -rf "$content_dir"

    echo "Local folders removed successfully."
}

# Function to create a non-editable info file
create_info_file() {
    local project_name=$1
    local original_project_name=$2
    local info_file=".${project_name}-info.json"

    # Create the info file
    cat <<EOL > "$info_file"
{
    "original_project_name": "$original_project_name"
}
EOL

    # Make the info file non-editable
    chmod 444 "$info_file"

    echo "Info file created successfully."
}

# Main function to delete the Kirby project
delete_kirby_project() {
    # Prompt the user for the project name
    read -p "Enter the project name: " original_project_name
    local project_name=$(to_kebab_case "$original_project_name")

    # Check if the project name is too short or too long
    if [ -z "$project_name" ]; then
        echo "Error: Project name cannot be empty."
        exit 1
    elif [ ${#project_name} -gt 50 ]; then
        echo "Error: Project name is too long. Maximum length is 50 characters."
        exit 1
    fi

    # Check if the project exists
    if [ ! -d "${project_name}-site" ] || [ ! -d "${project_name}-content" ]; then
        echo "Error: Project does not exist."
        exit 1
    fi

    echo "Starting deletion process for the Kirby project..."
    delete_github_repos "$project_name"
    remove_local_folders "$project_name"
    echo -e "\033[32mKirby project deletion completed successfully.\033[0m"
}

# Main function to set up the Kirby project
setup_kirby_project() {
    # Prompt the user for the project name
    read -p "Enter the project name: " original_project_name
    local project_name=$(to_kebab_case "$original_project_name")

    # Check if the project name is too short or too long
    if [ -z "$project_name" ]; then
        echo "Error: Project name cannot be empty."
        exit 1
    elif [ ${#project_name} -gt 50 ]; then
        echo "Error: Project name is too long. Maximum length is 50 characters."
        exit 1
    fi

    # Check if the project already exists
    if [ -d "${project_name}-site" ] || [ -d "${project_name}-content" ]; then
        echo "Error: Project already exists."
        exit 1
    fi

    echo "Starting Kirby installation process..."
    install_kirby "$project_name"
    echo "Setting up the custom content folder..."
    setup_content_folder "$project_name"
    setup_git "$project_name" "$original_project_name"
    create_info_file "$project_name" "$original_project_name"
    echo -e "\033[32mKirby project setup completed successfully.\033[0m"
}

# Check for required tools
echo "Checking for required tools..."
check_command "gh"
check_command "composer"
check_command "php"
check_command "node"
check_command "npm"
echo "All required tools are installed."

# Check for the delete option
if [ "$1" == "delete" ]; then
    delete_kirby_project
else
    setup_kirby_project
fi
