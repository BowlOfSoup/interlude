#! /bin/sh
# shellcheck disable=SC2034,SC2153,SC2039,SC2059

include process.lib
include visual.lib

readonly COMPOSER_JSON_PATH="./composer.json"
readonly COMPOSER_LOCK_PATH="./composer.lock"

REPO_URL=""

# Check if a package exists in composer.json
__does_package_exist() {
    local package="$1"
    local composer_file="$2"

    # Check if composer.json exists
    if [ ! -f "$composer_file" ]; then
        echo "composer.json not found at specified path: $composer_file"

        exit 1
    fi

    awk -v package="$package" '
    BEGIN {in_require=0; found=0;}
    /"require":/ {in_require=1; next}
    /"require-dev":/ {in_require=1; next}
    /},/ {if(in_require) in_require=0;}
    {
        if(in_require && $0 ~ package) {
            found=1;

            exit;
        }
    }
    END {exit !found}
    ' "$composer_file"

    return $?
}

# get package from composer.json and check if directory exists
__check_package_and_directory() {
    local package="$1"

    if __does_package_exist "$package" "$COMPOSER_JSON_PATH"; then
        local package_dir_full="./vendor/$PACKAGE_DIR"

        if [ -L "$package_dir_full" ]; then
            ERROR_MSG="Package is already checked-out for development!"

            return 1
        fi

        if [ ! -d "$package_dir_full" ]; then
            ERROR_MSG="The package directory does not exist. Have you run 'composer install'?"

            return 1
        fi
    else
        ERROR_MSG="Package '$package' not found in composer.json"

        return 1
    fi

    return 0
}

__parse_repo_url() {
    local package="$1"

    REPO_URL=$(grep -A 20 -E "\"name\": \"$package\"" $COMPOSER_LOCK_PATH | grep -m 1 '"url":' | sed -E 's/.*"url": "(.*)",/\1/')

    if [ -z "$REPO_URL" ]; then
        ERROR_MSG="Repository URL for package '$package' not found."

        return 1
    fi

    return 0
}

__clone_package_for_local_dev() {
    if [ -d "${VENDOR_LOCAL_DIR}"/"${PACKAGE_DIR}" ]; then
        rm -rf "${VENDOR_LOCAL_DIR:?}"/"${PACKAGE_DIR:?}"
    fi

    git clone --quiet "$REPO_URL" "${VENDOR_LOCAL_DIR}"/"${PACKAGE_DIR}"

    return $?
}

__backup_package() {
    local package_vendor_dir="./vendor/$PACKAGE_DIR"
    local package_vendor_backup_dir="$VENDOR_BACKUP_DIR/$PACKAGE_DIR_HASHED/$PACKAGE_DIR"

    if [ -d "$package_vendor_dir" ]; then
        mkdir -p "$package_vendor_backup_dir"
        cp -R  "$package_vendor_dir" "$package_vendor_backup_dir"
        rm -rf "$package_vendor_dir"
    fi
}

__symlink_vendor_to_dev() {
    local package="$1"
    local package_vendor_dir="./vendor/$PACKAGE_DIR"
    local package_vendor_local_dir_relative_to_vendor="../vendor-local"
    local package_vendor_dev_dir_relative="../$package_vendor_local_dir_relative_to_vendor/$PACKAGE_DIR"
    local package_vendor_dir_root
    local package_name

    # Create symlink
    package_vendor_dir_root=$(dirname "$package_vendor_dir")
    package_name=$(basename "$package")
    cd "$package_vendor_dir_root" || exit
    ln -s "$package_vendor_dev_dir_relative" "$package_name"

    # Symlink project vendor directory, if we want to add deps.
    cd "$package_name" || exit
    ln -s "../../../vendor" "vendor"

    cd "$APP_DIR" || exit
}

checkout_main () {
    process_command_wait "Checking existence of package" __check_package_and_directory "$PACKAGE_NAME"
    process_command_wait "Parsing repository URL" __parse_repo_url "$PACKAGE_NAME"
    process_command_wait "Cloning package for local development" __clone_package_for_local_dev
    process_command_wait "Backing up package" __backup_package
    process_command_wait "Creating symlink to vendor-local directory" __symlink_vendor_to_dev "$PACKAGE_NAME"
}
