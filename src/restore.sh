#! /bin/sh
# shellcheck disable=SC2034,SC2153,SC2039,SC2059

include process.lib
include visual.lib

__check_git_status() {
    local package_vendor_local_dir="$VENDOR_LOCAL_DIR/$PACKAGE_DIR"

    visual_step_message "Checking if repo is dirty"

    # Check if there where changes made
    if git -C "$package_vendor_local_dir" status --porcelain | grep -qv ' vendor'; then
        printf "\r[${COL_BOLD_TURQUOISE}INF${COL_RESET}] Changes where made in the working directory $package_vendor_local_dir\n"

        if ! input_helpers_confirmation "Do you want to continue?"; then
            exit 0
        fi

        process_command_wait "Resetting working directory" git -C "$package_vendor_local_dir" reset --quiet --hard
    fi
}

__package_is_existing() {
    local package="$1"
    local package_vendor_dir="./vendor/$PACKAGE_DIR"

    # Check if the symlink exists and remove it.
    if [ -L "$package_vendor_dir" ]; then
        rm "$package_vendor_dir"
    elif [ -d "$package_vendor_dir" ]; then
        ERROR_MSG="Package was not checked-out for development."
        rm -rf "$package_vendor_backup_dir"
        rm -rf "$package_vendor_local_dir"

        return 1
    else
        ERROR_MSG="No symlink or directory found for '$package', nothing to do."

        return 1
    fi
}

__restore_package() {
    local package="$1"
    local package_vendor_dir="./vendor/$PACKAGE_DIR"
    local package_vendor_backup_dir="$VENDOR_BACKUP_DIR/$PACKAGE_DIR"
    local package_vendor_local_dir="$VENDOR_LOCAL_DIR/$PACKAGE_DIR"
    local target_dir

    # Restore from back-up
    mkdir -p "$package_vendor_dir"
    target_dir=$(dirname "$package_vendor_dir")
    cp -R "$package_vendor_backup_dir/" "$target_dir"
    rm -rf "$package_vendor_backup_dir"
    rm -rf "$package_vendor_local_dir"

    find "$VENDOR_BACKUP_DIR" -type d -empty -exec rmdir {} +
    find "$VENDOR_LOCAL_DIR" -type d -empty -exec rmdir {} +
}

restore_main() {
    process_command_wait "Checking package" __package_is_existing "$PACKAGE_NAME"
    __check_git_status
    process_command_wait "Restoring package" __restore_package "$PACKAGE_NAME"
}
