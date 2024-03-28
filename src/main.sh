#! /bin/sh
# shellcheck disable=SC2034,SC2153

include checkout.sh
include restore.sh

include visual.lib

# ↓ -- Global variables -- ↓

readonly VENDOR_LOCAL_DIR="./vendor-local"
readonly VENDOR_BACKUP_DIR="$HOME/.composer/interlude/backup-local"

PACKAGE_DIR=$(echo "$PACKAGE_NAME" | sed 's/\//\//g')
PACKAGE_DIR_HASHED=$(printf "%s" "$(pwd)" | openssl md5 | cut -d' ' -f2)

# ↓ -- Functions -- ↓

__create_vendor_dirs() {
    if [ ! -d "$VENDOR_LOCAL_DIR" ]; then
        mkdir -p "$VENDOR_LOCAL_DIR"
    fi
    if [ ! -d "$VENDOR_BACKUP_DIR" ]; then
        mkdir -p "$VENDOR_BACKUP_DIR"
    fi
}

main() {
    if [ "$COMMAND" = "" ] || [ "$PACKAGE_NAME" = "" ]; then
        echo "Usage: $0 <command> <package>"
        echo ""
        echo "This script is a helper to develop external packages locally."
        echo "Package will be put in the 'vendor-local' directory where you can work with 'git'"
        echo ""
        echo "Commands:"
        echo "  checkout <package-name> Checkout a package and develop from the vendor-local directory"
        echo "  restore <package-name>  Restore a package to its state before checking out"

        exit 0
    fi

    __create_vendor_dirs

    printf "\n%bDevelop locally for:%b %s\n\n" "$COL_GREEN" "$COL_RESET" "$PACKAGE_NAME"

    if [ "$COMMAND" = "checkout" ]; then
        checkout_main
    fi

    if [ "$COMMAND" = "restore" ]; then
        restore_main
    fi
}

# ↓ -- Script flow -- ↓

loader_finish
main
