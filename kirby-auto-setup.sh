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
    # Remove accents
    local no_accents=$(echo "$lowercase_input" | iconv -f utf8 -t ascii//TRANSLIT)
    # Remove any special characters except spaces and hyphens
    local cleaned_input=$(echo "$no_accents" | sed 's/[^a-z0-9 -]//g')
    # Replace spaces with hyphens and ensure no extra hyphens
    local kebab_case=$(echo "$cleaned_input" | tr ' ' '-' | sed -e 's/--*/-/g' -e 's/^-//' -e 's/-$//')
    # Output the result
    echo "$kebab_case"
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

    echo "Updating the .gitignore file..."
    echo -e "\n# Local Installation Files\n# ---------------\n\n/kirby\n/vendor" >> "${project_name}-site/.gitignore"
    echo ".gitignore file updated successfully"

    echo "Kirby installed successfully."
}

# Function to set up the custom content folder
setup_content_folder() {
    local project_name=$1
    local project_dir="${project_name}-site"
    local content_dir="${project_name}-content"

    echo "Setting up the custom content folder..."

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
    mv "content" "$content_dir"
    echo "Renamed 'content' folder to '${content_dir}'."
}

# Function to copy the index.php file
copy_index_php() {
    local project_name=$1
    local project_dir="${project_name}-site"
    local index_file="$project_dir/index.php"

    # Copy the external index.php file to the project directory
    cp "index.php" "$index_file"
    echo "index.php has been copied successfully."
}

# Function to copy the GitHub Actions workflow file for staging
copy_github_actions_workflow_staging() {
    local project_name=$1
    local project_dir="${project_name}-site"
    local workflow_file="${project_dir}/.github/workflows/staging.yml"

    # Create the .github/workflows directory
    mkdir -p "${project_dir}/.github/workflows"

    # Copy the external staging.yml file to the project directory
    cp "staging.yml" "$workflow_file"
    echo "GitHub Actions workflow file for staging copied successfully."
}

# Function to copy the GitHub Actions workflow file for production
copy_github_actions_workflow_production() {
    local project_name=$1
    local project_dir="${project_name}-site"
    local workflow_file="${project_dir}/.github/workflows/production.yml"

    # Create the .github/workflows directory
    mkdir -p "${project_dir}/.github/workflows"

    # Copy the external production.yml file to the project directory
    cp "production.yml" "$workflow_file"
    echo "GitHub Actions workflow file for production copied successfully."
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
    setup_content_folder "$project_name"
    copy_index_php "$project_name"
    copy_github_actions_workflow_staging "$project_name"
    copy_github_actions_workflow_production "$project_name"
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

# Run the setup process
setup_kirby_project
