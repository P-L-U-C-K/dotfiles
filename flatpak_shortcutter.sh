#!/bin/bash

# Ensure the local binary directory exists
mkdir -p "$HOME/.local/bin"

# Get a list of all installed Flatpak application IDs
flatpak list --app --columns=application | while read -r app_id; do
    # Skip the header row if it exists
    if [ "$app_id" = "Application ID" ] || [ -z "$app_id" ]; then
        continue
    fi

    # Extract the last part of the reverse-DNS string (e.g., GIMP from org.gimp.GIMP)
    # and convert it entirely to lowercase
    short_name=$(echo "$app_id" | awk -F'.' '{print $NF}' | tr '[:upper:]' '[:lower:]')

    # Define the target shortcut path
    shortcut_path="$HOME/.local/bin/$short_name"

    # Check if a file or shortcut already exists to avoid overwriting system commands
    if [ -e "$shortcut_path" ]; then
        echo "⚠️ Skipping '$short_name': file or shortcut already exists."
    else
        # Create a tiny script wrapper to execute the Flatpak properly
        echo -e "#!/bin/sh\nexec flatpak run $app_id \"\$@\"" > "$shortcut_path"
        chmod +x "$shortcut_path"
        echo "✅ Created shortcut: $short_name -> flatpak run $app_id"
    fi
done

echo "🎉 Done! Restart your terminal or run 'source ~/.bashrc' to apply."
