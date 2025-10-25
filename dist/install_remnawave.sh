#!/bin/bash

# Remnawave Installer 

# Including module: constants.sh

LANG_CODE="${LANG_CODE:-en}"
REMNAWAVE_BRANCH="${REMNAWAVE_BRANCH:-main}"
INSTALLER_BRANCH="${INSTALLER_BRANCH:-main}"
KEEP_CADDY_DATA="${KEEP_CADDY_DATA:-false}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --lang=*)
            LANG_CODE="${1#*=}"
            shift
            ;;
        --lang)
            LANG_CODE="$2"
            shift 2
            ;;
        --panel-branch=*)
            REMNAWAVE_BRANCH="${1#*=}"
            shift
            ;;
        --panel-branch)
            REMNAWAVE_BRANCH="$2"
            shift 2
            ;;
        --installer-branch=*)
            INSTALLER_BRANCH="${1#*=}"
            shift
            ;;
        --installer-branch)
            INSTALLER_BRANCH="$2"
            shift 2
            ;;
        --keep-caddy-data)
            KEEP_CADDY_DATA="true"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

BOLD_BLUE=$(tput setaf 4)
BOLD_GREEN=$(tput setaf 2)
BOLD_YELLOW=$(tput setaf 11)
LIGHT_GREEN=$(tput setaf 10)
BOLD_BLUE_MENU=$(tput setaf 6)
ORANGE=$(tput setaf 3)
BOLD_RED=$(tput setaf 1)
BLUE=$(tput setaf 6)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

VERSION="1.6.2"

if [[ "$REMNAWAVE_BRANCH" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    REMNAWAVE_BACKEND_TAG="$REMNAWAVE_BRANCH"
    REMNAWAVE_NODE_TAG="$REMNAWAVE_BRANCH"
elif [ "$REMNAWAVE_BRANCH" = "dev" ]; then
    REMNAWAVE_BACKEND_TAG="dev"
    REMNAWAVE_NODE_TAG="dev"
elif [ "$REMNAWAVE_BRANCH" = "alpha" ]; then
    REMNAWAVE_BACKEND_TAG="alpha"
    REMNAWAVE_NODE_TAG="dev"  # Node doesn't have alpha tag, use dev
else
    REMNAWAVE_BACKEND_TAG="latest"
    REMNAWAVE_NODE_TAG="latest"
fi

REMNAWAVE_BACKEND_REPO="https://raw.githubusercontent.com/remnawave/backend/refs/heads"
INSTALLER_REPO="https://raw.githubusercontent.com/xxphantom/remnawave-installer/refs/heads"

REMNAWAVE_DIR="/opt/remnawave"
REMNANODE_DIR="/opt/remnanode"
SELFSTEAL_DIR="/opt/remnanode/selfsteal"

LOCAL_REMNANODE_DIR="$REMNAWAVE_DIR/node"

# Including module: i18n.sh


declare -A TRANSLATIONS_EN
declare -A TRANSLATIONS_RU

t() {
    local key="$1"
    local value=""

    case "$LANG_CODE" in
        "ru")
            value="${TRANSLATIONS_RU[$key]:-}"
            ;;
        "en"|*)
            value="${TRANSLATIONS_EN[$key]:-}"
            ;;
    esac

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "[$key]" # Show key if no translation found
    fi
}

# Including module: en.sh



TRANSLATIONS_EN[error_root_required]="Error: This script must be run as root (sudo)"
TRANSLATIONS_EN[error_invalid_choice]="Invalid choice, please try again."
TRANSLATIONS_EN[error_empty_response]="Error: Empty response from server when creating user."
TRANSLATIONS_EN[error_failed_create_user]="Error: Failed to create user. HTTP status:"
TRANSLATIONS_EN[error_passwords_no_match]="Passwords do not match. Please try again."
TRANSLATIONS_EN[error_enter_yn]="Please enter 'y' or 'n'."
TRANSLATIONS_EN[error_enter_number_between]="Please enter a number between"

TRANSLATIONS_EN[main_menu_title]="Remnawave Panel Installer by uphantom v"
TRANSLATIONS_EN[main_menu_script_branch]="Script branch:"
TRANSLATIONS_EN[main_menu_panel_branch]="Panel branch:"
TRANSLATIONS_EN[main_menu_install_components]="Install Panel/Node"
TRANSLATIONS_EN[main_menu_update_components]="Update Panel/Node"
TRANSLATIONS_EN[main_menu_restart_panel]="Restart panel"
TRANSLATIONS_EN[main_menu_remove_panel]="Remove panel"
TRANSLATIONS_EN[main_menu_rescue_cli]="Remnawave Rescue CLI [Reset admin]"
TRANSLATIONS_EN[main_menu_show_credentials]="Show panel access credentials"
TRANSLATIONS_EN[main_menu_warp_integration]="Add WARP integration (Native WARP in Docker)"
TRANSLATIONS_EN[main_menu_exit]="Exit"
TRANSLATIONS_EN[main_menu_select_option]="Select option:"

TRANSLATIONS_EN[install_menu_title]="Install Panel/Node"
TRANSLATIONS_EN[install_menu_panel_only]="Panel Only:"
TRANSLATIONS_EN[install_menu_panel_full_security]="Panel with FULL Caddy security (recommended)"
TRANSLATIONS_EN[install_menu_panel_simple_security]="Panel with SIMPLE cookie security"
TRANSLATIONS_EN[install_menu_node_only]="Node Only:"
TRANSLATIONS_EN[install_menu_node_separate]="Node only (for separate server)"
TRANSLATIONS_EN[install_menu_all_in_one]="All-in-One:"
TRANSLATIONS_EN[install_menu_panel_node_full]="Panel + Node with FULL Caddy security"
TRANSLATIONS_EN[install_menu_panel_node_simple]="Panel + Node with SIMPLE cookie security"
TRANSLATIONS_EN[install_menu_back]="Back to main menu"

TRANSLATIONS_EN[update_menu_title]="Update Panel/Node"
TRANSLATIONS_EN[update_menu_panel_only]="Panel Only:"
TRANSLATIONS_EN[update_menu_panel_update]="Update Panel"
TRANSLATIONS_EN[update_menu_node_only]="Node Only:"
TRANSLATIONS_EN[update_menu_node_separate]="Update Node (separate server)"
TRANSLATIONS_EN[update_menu_back]="Back to main menu"

TRANSLATIONS_EN[prompt_yes_no_suffix]=" (y/n): "
TRANSLATIONS_EN[prompt_yes_no_default_suffix]=" (y/n) ["
TRANSLATIONS_EN[prompt_enter_to_continue]="Press Enter to continue..."
TRANSLATIONS_EN[prompt_enter_to_return]="Press Enter to return to menu..."

TRANSLATIONS_EN[success_bbr_enabled]="BBR successfully enabled"
TRANSLATIONS_EN[success_bbr_disabled]="BBR disabled, active cubic + fq_codel"
TRANSLATIONS_EN[success_credentials_saved]="Credentials saved in file:"
TRANSLATIONS_EN[success_installation_complete]="Installation complete. Press Enter to continue..."

TRANSLATIONS_EN[warning_skipping_telegram]="Skipping Telegram integration."
TRANSLATIONS_EN[warning_bbr_not_configured]="BBR was not configured in /etc/sysctl.conf"
TRANSLATIONS_EN[warning_enter_different_domain]="Please enter a different domain for"

TRANSLATIONS_EN[info_removing_bbr_config]="Removing BBR configuration from /etc/sysctl.conf…"
TRANSLATIONS_EN[info_installation_directory]="Installation directory:"

TRANSLATIONS_EN[bbr_enable]="Enable BBR"
TRANSLATIONS_EN[bbr_disable]="Disable BBR"

TRANSLATIONS_EN[telegram_enable_notifications]="Do you want to enable Telegram notifications?"
TRANSLATIONS_EN[telegram_bot_token]="Enter your Telegram bot token: "
TRANSLATIONS_EN[telegram_enable_user_notifications]="Do you want to enable notifications about user events? (if disabled, only node event notifications will be sent)"
TRANSLATIONS_EN[telegram_users_chat_id]="Enter the chat ID for user event notifications: "
TRANSLATIONS_EN[telegram_enable_crm_notifications]="Do you want to enable CRM notifications?"
TRANSLATIONS_EN[telegram_crm_chat_id]="Enter the chat ID for CRM notifications: "
TRANSLATIONS_EN[telegram_nodes_chat_id]="Enter the chat ID for node event notifications: "
TRANSLATIONS_EN[telegram_use_topics]="Do you want to use Telegram topics?"
TRANSLATIONS_EN[telegram_users_thread_id]="Enter the thread ID for user events: "
TRANSLATIONS_EN[telegram_crm_thread_id]="Enter the thread ID for CRM notifications: "
TRANSLATIONS_EN[telegram_nodes_thread_id]="Enter the thread ID for node events: "

TRANSLATIONS_EN[domain_panel_prompt]="Enter Panel domain (will be used on panel server), e.g. panel.example.com"
TRANSLATIONS_EN[domain_subscription_prompt]="Enter Subscription domain (will be used on panel server), e.g. sub.example.com"
TRANSLATIONS_EN[domain_selfsteal_prompt]="Enter Selfsteal domain (will be used on node server), e.g. domain.example.com"

TRANSLATIONS_EN[auth_admin_username]="Enter admin username: "
TRANSLATIONS_EN[auth_admin_password]="Enter admin password: "
TRANSLATIONS_EN[auth_admin_email]="Enter the admin email for Caddy Auth"
TRANSLATIONS_EN[auth_confirm_password]="Please confirm your password"

TRANSLATIONS_EN[panel_invalid_auth_type]="Invalid authentication type"
TRANSLATIONS_EN[panel_auth_type_options]="Valid options: 'cookie' or 'full'"

TRANSLATIONS_EN[results_secure_login_link]="Secure login link (with secret key):"
TRANSLATIONS_EN[results_user_subscription_url]="User subscription URL:"
TRANSLATIONS_EN[results_admin_login]="Admin login:"
TRANSLATIONS_EN[results_admin_password]="Admin password:"
TRANSLATIONS_EN[results_caddy_auth_login]="Caddy auth login:"
TRANSLATIONS_EN[results_caddy_auth_password]="Caddy auth password:"
TRANSLATIONS_EN[results_remnawave_admin_login]="Remnawave admin login:"
TRANSLATIONS_EN[results_remnawave_admin_password]="Remnawave admin password:"
TRANSLATIONS_EN[results_auth_portal_page]="Auth Portal page:"

TRANSLATIONS_EN[qr_subscription_url]="Subscription URL QR Code"

TRANSLATIONS_EN[password_min_length]="Password must contain at least"
TRANSLATIONS_EN[password_min_length_suffix]="characters."
TRANSLATIONS_EN[password_need_digit]="Password must contain at least one digit."
TRANSLATIONS_EN[password_need_lowercase]="Password must contain at least one lowercase letter."
TRANSLATIONS_EN[password_need_uppercase]="Password must contain at least one uppercase letter."
TRANSLATIONS_EN[password_try_again]="Please try again."

TRANSLATIONS_EN[port_panel_prompt]="Enter Panel port (default: 443): "
TRANSLATIONS_EN[port_node_prompt]="Enter Node port (default: 2222): "
TRANSLATIONS_EN[port_caddy_local_prompt]="Enter Caddy local port (default: 9443): "

TRANSLATIONS_EN[installation_preparing]="Preparing installation..."
TRANSLATIONS_EN[installation_starting_services]="Starting services..."
TRANSLATIONS_EN[installation_configuring]="Configuring..."

TRANSLATIONS_EN[credentials_found]="Panel access credentials found:"
TRANSLATIONS_EN[credentials_not_found]="Credentials file not found!"
TRANSLATIONS_EN[credentials_file_location]="The credentials file does not exist at:"
TRANSLATIONS_EN[credentials_reasons]="This usually means:"
TRANSLATIONS_EN[credentials_reason_not_installed]="Panel is not installed yet"
TRANSLATIONS_EN[credentials_reason_incomplete]="Installation was not completed successfully"
TRANSLATIONS_EN[credentials_reason_deleted]="Credentials file was manually deleted"
TRANSLATIONS_EN[credentials_try_install]="Try installing the panel first using option 1 from the main menu."

TRANSLATIONS_EN[cli_container_not_running]="Remnawave container is not running!"
TRANSLATIONS_EN[cli_ensure_panel_running]="Please make sure the panel is installed and running."
TRANSLATIONS_EN[cli_session_completed]="CLI session completed successfully"
TRANSLATIONS_EN[cli_session_failed]="CLI session failed or was interrupted"

TRANSLATIONS_EN[removal_installation_detected]="RemnaWave installation detected."
TRANSLATIONS_EN[removal_confirm_delete]="Are you sure you want to completely DELETE Remnawave? IT WILL REMOVE ALL DATA!!! Continue?"
TRANSLATIONS_EN[removal_previous_detected]="Previous RemnaWave installation detected."
TRANSLATIONS_EN[removal_confirm_continue]="To continue, you need to DELETE previous Remnawave installation. IT WILL REMOVE ALL DATA!!! Continue?"
TRANSLATIONS_EN[removal_complete_success]="Remnawave has been completely removed from your system. Press any key to continue..."
TRANSLATIONS_EN[removal_previous_success]="Previous installation removed."
TRANSLATIONS_EN[removal_no_installation]="No Remnawave installation detected on this system."
TRANSLATIONS_EN[removal_keep_caddy_data]="✓ Caddy data (certificates) will be preserved."

TRANSLATIONS_EN[restart_panel_dir_not_found]="Error: panel directory not found at /opt/remnawave!"
TRANSLATIONS_EN[restart_install_panel_first]="Please install Remnawave panel first."
TRANSLATIONS_EN[restart_compose_not_found]="Error: docker-compose.yml not found in panel directory!"
TRANSLATIONS_EN[restart_installation_corrupted]="Panel installation may be corrupted or incomplete."
TRANSLATIONS_EN[restart_starting_panel]="Starting main panel..."
TRANSLATIONS_EN[restart_starting_subscription]="Starting subscription page..."
TRANSLATIONS_EN[restart_success]="Panel restarted successfully"

TRANSLATIONS_EN[update_panel_dir_not_found]="Error: panel directory not found at /opt/remnawave!"
TRANSLATIONS_EN[update_node_dir_not_found]="Error: node directory not found at /opt/remnanode!"
TRANSLATIONS_EN[update_install_first]="Please install components first."
TRANSLATIONS_EN[update_compose_not_found]="Error: docker-compose.yml not found!"
TRANSLATIONS_EN[update_installation_corrupted]="Installation may be corrupted or incomplete."
TRANSLATIONS_EN[update_warning_title]="⚠️  IMPORTANT: Before updating"
TRANSLATIONS_EN[update_warning_backup]="• Make sure you have backups of your data"
TRANSLATIONS_EN[update_warning_changelog]="• Read the changelog before updating:"
TRANSLATIONS_EN[update_warning_panel_releases]="  Panel: https://github.com/remnawave/panel/releases/"
TRANSLATIONS_EN[update_warning_node_releases]="  Node: https://hub.remna.st/changelog"
TRANSLATIONS_EN[update_warning_downtime]="• Update process will cause temporary service downtime"
TRANSLATIONS_EN[update_warning_confirm]="Do you want to continue with the update?"
TRANSLATIONS_EN[update_checking_images]="Checking for image updates..."
TRANSLATIONS_EN[update_pulling_images]="Pulling latest images..."
TRANSLATIONS_EN[update_no_updates_available]="No updates available - all images are already up to date"
TRANSLATIONS_EN[update_images_updated]="New images downloaded, proceeding with restart..."
TRANSLATIONS_EN[update_pull_failed]="Failed to pull images"
TRANSLATIONS_EN[update_stopping_services]="Stopping services..."
TRANSLATIONS_EN[update_starting_services]="Starting updated services..."
TRANSLATIONS_EN[update_panel_success]="Panel updated successfully"
TRANSLATIONS_EN[update_node_success]="Node updated successfully"
TRANSLATIONS_EN[update_all_success]="Panel and Node updated successfully"
TRANSLATIONS_EN[update_no_restart_needed]="No restart needed - services are already running the latest versions"
TRANSLATIONS_EN[update_cleaning_images]="Cleaning unused images..."
TRANSLATIONS_EN[update_cleanup_complete]="Cleanup completed"
TRANSLATIONS_EN[update_cancelled]="Update cancelled by user"

TRANSLATIONS_EN[services_starting_containers]="Starting containers..."
TRANSLATIONS_EN[services_installation_stopped]="Installation stopped"

TRANSLATIONS_EN[system_distro_not_supported]="Distribution"
TRANSLATIONS_EN[system_dependencies_success]="All dependencies installed and configured."
TRANSLATIONS_EN[system_created_directory]="Created directory:"
TRANSLATIONS_EN[system_installation_cancelled]="Installation cancelled. Returning to main menu."
TRANSLATIONS_EN[system_distro_not_supported]="Distribution not supported:"
TRANSLATIONS_EN[docker_already_installed]="Modern Docker is already installed and up-to-date:"
TRANSLATIONS_EN[docker_check_failed]="Modern Docker installation not found. Proceeding with a full (re)installation."
TRANSLATIONS_EN[removing_old_docker]="Removing old or conflicting Docker installation..."
TRANSLATIONS_EN[old_docker_removed]="Old Docker installation successfully removed."
TRANSLATIONS_EN[deleting_docker_data]="WARNING: Deleting all existing Docker data (images, containers, volumes)..."
TRANSLATIONS_EN[spinner_updating_apt_cache]="Updating package cache (apt)..."
TRANSLATIONS_EN[spinner_installing_packages]="Installing required packages:"
TRANSLATIONS_EN[packages_already_installed]="Required packages are already installed."
TRANSLATIONS_EN[installing_docker]="Installing Docker Engine..."
TRANSLATIONS_EN[docker_installed]="Docker Engine has been successfully installed."
TRANSLATIONS_EN[spinner_starting_docker]="Starting Docker service..."
TRANSLATIONS_EN[spinner_docker_already_running]="Docker service is already running."
TRANSLATIONS_EN[spinner_adding_user_to_group]="Adding current user to the 'docker' group..."
TRANSLATIONS_EN[relogin_required]="You need to log out and log back in for group changes to take effect."
TRANSLATIONS_EN[spinner_firewall_already_set]="Firewall rules are already configured."
TRANSLATIONS_EN[spinner_configuring_firewall]="Configuring firewall (UFW)..."
TRANSLATIONS_EN[ufw_ports_opened]="Firewall configured. Opened TCP ports:"
TRANSLATIONS_EN[spinner_auto_updates_already_set]="Automatic security updates are already enabled."
TRANSLATIONS_EN[spinner_setting_auto_updates]="Enabling automatic security updates..."
TRANSLATIONS_EN[auto_updates_enabled]="Automatic security updates have been enabled."
TRANSLATIONS_EN[all_dependencies_installed]="All dependencies and basic setup are complete."

TRANSLATIONS_EN[prompt_press_any_key]="Press any key to continue..."

TRANSLATIONS_EN[spinner_generating_keys]="Generating x25519 keys..."
TRANSLATIONS_EN[spinner_updating_xray]="Updating Xray configuration..."
TRANSLATIONS_EN[spinner_registering_user]="Registering user"
TRANSLATIONS_EN[spinner_getting_public_key]="Getting public key..."
TRANSLATIONS_EN[spinner_creating_node]="Creating node..."
TRANSLATIONS_EN[spinner_getting_inbounds]="Getting list of inbounds..."
TRANSLATIONS_EN[spinner_creating_config_profile]="Creating configuration profile..."
TRANSLATIONS_EN[spinner_getting_config_profiles]="Getting configuration profiles..."
TRANSLATIONS_EN[spinner_deleting_config_profile]="Deleting default configuration profile..."
TRANSLATIONS_EN[spinner_getting_squads]="Getting list of squads..."
TRANSLATIONS_EN[spinner_updating_squad]="Updating squad with new inbound..."
TRANSLATIONS_EN[spinner_creating_host]="Creating host..."
TRANSLATIONS_EN[spinner_cleaning_services]="Cleaning up"
TRANSLATIONS_EN[spinner_force_removing]="Force removing container"
TRANSLATIONS_EN[spinner_removing_directory]="Removing directory"
TRANSLATIONS_EN[spinner_stopping_subscription]="Stopping remnawave-subscription-page container"
TRANSLATIONS_EN[spinner_restarting_panel]="Restarting panel..."
TRANSLATIONS_EN[spinner_launching]="Launching"
TRANSLATIONS_EN[spinner_updating_apt_cache]="Updating APT cache"
TRANSLATIONS_EN[spinner_installing_packages]="Installing packages:"
TRANSLATIONS_EN[spinner_starting_docker]="Starting Docker daemon"
TRANSLATIONS_EN[spinner_docker_already_running]="Docker daemon already running"
TRANSLATIONS_EN[spinner_firewall_already_set]="Firewall already set"
TRANSLATIONS_EN[spinner_configuring_firewall]="Configuring firewall"
TRANSLATIONS_EN[spinner_auto_updates_already_set]="Auto-updates already set"
TRANSLATIONS_EN[spinner_setting_auto_updates]="Setting auto-updates"
TRANSLATIONS_EN[spinner_downloading_static_files]="Downloading static files for the selfsteal site..."

TRANSLATIONS_EN[config_invalid_arguments]="Error: invalid number of arguments. Should be even number of keys and values."
TRANSLATIONS_EN[config_domain_already_used]="Domain"
TRANSLATIONS_EN[config_domains_must_be_unique]="Each domain must be unique: panel domain, subscription domain, and selfsteal domain must all be different."
TRANSLATIONS_EN[config_caddy_port_available]="Required Caddy port 9443 is available"
TRANSLATIONS_EN[config_caddy_port_in_use]="Required Caddy port 9443 is already in use!"
TRANSLATIONS_EN[config_node_port_available]="Required Node API port 2222 is available"
TRANSLATIONS_EN[config_node_port_in_use]="Required Node API port 2222 is already in use!"
TRANSLATIONS_EN[config_separate_installation_port_required]="For separate panel and node installation, port"
TRANSLATIONS_EN[config_free_port_and_retry]="Please free up port"
TRANSLATIONS_EN[config_installation_cannot_continue]="Installation cannot continue with occupied port"

TRANSLATIONS_EN[misc_qr_generation_failed]="QR code generation failed"

TRANSLATIONS_EN[network_error_port_number]="Error: Port must be a number."
TRANSLATIONS_EN[network_error_port_range]="Error: Port must be between 1 and 65535."
TRANSLATIONS_EN[network_invalid_email]="Invalid email format."
TRANSLATIONS_EN[network_proceed_with_value]="Proceed with this value? Current value:"
TRANSLATIONS_EN[network_using_default_port]="Using default port:"
TRANSLATIONS_EN[network_port_in_use]="port is already in use. Finding available port..."
TRANSLATIONS_EN[network_using_port]="Using port:"
TRANSLATIONS_EN[network_failed_find_port]="Failed to find an available port for"
TRANSLATIONS_EN[network_invalid_domain]="Invalid domain format. Please try again."
TRANSLATIONS_EN[network_failed_determine_ip]="Failed to determine domain or server IP address."
TRANSLATIONS_EN[network_make_sure_domain]="Make sure that the domain"
TRANSLATIONS_EN[network_points_to_server]="is properly configured and points to the server"
TRANSLATIONS_EN[network_continue_despite_ip]="Continue with this domain despite being unable to verify its IP address?"
TRANSLATIONS_EN[network_domain_points_cloudflare]="Domain"
TRANSLATIONS_EN[network_points_cloudflare_ip]="points to Cloudflare IP"
TRANSLATIONS_EN[network_disable_cloudflare]="Disable Cloudflare proxying - selfsteal domain proxying is not allowed."
TRANSLATIONS_EN[network_continue_despite_cloudflare]="Continue with this domain despite Cloudflare proxy configuration issue?"
TRANSLATIONS_EN[network_domain_points_server]="Domain"
TRANSLATIONS_EN[network_points_this_server]="points to this server IP"
TRANSLATIONS_EN[network_separate_installation_note]="For separate installation, selfsteal domain should point to the node server, not the panel server."
TRANSLATIONS_EN[network_continue_despite_current_server]="Continue with this domain despite it pointing to the current server?"
TRANSLATIONS_EN[network_domain_points_different]="Domain"
TRANSLATIONS_EN[network_points_different_ip]="points to IP address"
TRANSLATIONS_EN[network_differs_from_server]="which differs from the server IP"
TRANSLATIONS_EN[network_continue_despite_mismatch]="Continue with this domain despite the IP address mismatch?"

TRANSLATIONS_EN[api_empty_server_response]="Empty server response"
TRANSLATIONS_EN[api_registration_failed]="Registration failed: unknown error"
TRANSLATIONS_EN[api_failed_get_public_key]="Error: Failed to get public key."
TRANSLATIONS_EN[api_failed_extract_public_key]="Error: Failed to extract public key from response."
TRANSLATIONS_EN[api_empty_response_creating_node]="Error: Empty response from server when creating node."
TRANSLATIONS_EN[api_failed_create_node]="Error: Failed to create node, response:"
TRANSLATIONS_EN[api_empty_response_getting_inbounds]="Error: Empty response from server when getting inbounds."
TRANSLATIONS_EN[api_failed_extract_uuid]="Error: Failed to extract UUID from response."
TRANSLATIONS_EN[api_empty_response_creating_profile]="Error: Empty response from server when creating config profile."
TRANSLATIONS_EN[api_failed_create_profile]="Error: Failed to create config profile."
TRANSLATIONS_EN[api_empty_response_getting_profiles]="Error: Empty response from server when getting config profiles."
TRANSLATIONS_EN[api_failed_delete_profile]="Error: Failed to delete config profile."
TRANSLATIONS_EN[api_empty_response_getting_squads]="Error: Empty response from server when getting squads."
TRANSLATIONS_EN[api_empty_response_updating_squad]="Error: Empty response from server when updating squad."
TRANSLATIONS_EN[api_failed_update_squad]="Error: Failed to update squad."
TRANSLATIONS_EN[api_empty_response_creating_host]="Error: Empty response from server when creating host."
TRANSLATIONS_EN[api_failed_create_host]="Error: Failed to create host."
TRANSLATIONS_EN[api_empty_response_creating_user]="Error: Empty response from server when creating user."
TRANSLATIONS_EN[api_failed_create_user_status]="Error: Failed to create user. HTTP status:"
TRANSLATIONS_EN[api_failed_create_user_format]="Error: Failed to create user, invalid response format:"
TRANSLATIONS_EN[api_failed_register_user]="Failed to register user."
TRANSLATIONS_EN[api_request_body_was]="Request body was:"
TRANSLATIONS_EN[api_response]="Response:"

TRANSLATIONS_EN[validation_value_min]="Value must be at least"
TRANSLATIONS_EN[validation_value_max]="Value must be at most"
TRANSLATIONS_EN[validation_enter_numeric]="Please enter a valid numeric value."
TRANSLATIONS_EN[validation_input_empty]="Input cannot be empty. Please enter a valid domain or IP address."
TRANSLATIONS_EN[validation_invalid_ip]="Invalid IP address format. IP must be in format X.X.X.X, where X is a number from 0 to 255."
TRANSLATIONS_EN[validation_invalid_domain]="Invalid domain name format. Domain must contain at least one dot and not start/end with dot or dash."
TRANSLATIONS_EN[validation_use_only_letters]="Use only letters, digits, dots, and dashes."
TRANSLATIONS_EN[validation_invalid_domain_ip]="Invalid domain or IP address format."
TRANSLATIONS_EN[validation_domain_format]="Domain must contain at least one dot and not start/end with dot or dash."
TRANSLATIONS_EN[validation_ip_format]="IP address must be in format X.X.X.X, where X is a number from 0 to 255."
TRANSLATIONS_EN[validation_max_attempts_default]="Maximum number of attempts exceeded. Using default value:"
TRANSLATIONS_EN[validation_max_attempts_no_input]="Maximum number of attempts exceeded. No valid input provided."
TRANSLATIONS_EN[validation_cannot_continue]="Installation cannot continue without a valid domain or IP address."

TRANSLATIONS_EN[vless_failed_generate_keys]="Error: Failed to generate keys."
TRANSLATIONS_EN[vless_empty_response_xray]="Error: Empty response from server when updating Xray config."
TRANSLATIONS_EN[vless_failed_update_xray]="Error: Failed to update Xray configuration."

TRANSLATIONS_EN[node_port_9443_in_use]="Required Caddy port 9443 is already in use!"
TRANSLATIONS_EN[node_separate_port_9443]="For separate node installation, port 9443 must be available."
TRANSLATIONS_EN[node_free_port_9443]="Please free up port 9443 and try again."
TRANSLATIONS_EN[node_cannot_continue_9443]="Installation cannot continue with occupied port 9443"
TRANSLATIONS_EN[node_port_2222_in_use]="Required Node API port 2222 is already in use!"
TRANSLATIONS_EN[node_separate_port_2222]="For separate node installation, port 2222 must be available."
TRANSLATIONS_EN[node_free_port_2222]="Please free up port 2222 and try again."
TRANSLATIONS_EN[node_cannot_continue_2222]="Installation cannot continue with occupied port 2222"
TRANSLATIONS_EN[node_enter_ssl_cert]="Enter the server certificate in format SSL_CERT=\"...\" (paste the content and press Enter twice):"
TRANSLATIONS_EN[node_ssl_cert_valid]="✓ SSL certificate format is valid"
TRANSLATIONS_EN[node_ssl_cert_invalid]="✗ Invalid SSL certificate format. Please try again."
TRANSLATIONS_EN[node_ssl_cert_expected]="Expected format: SSL_CERT=\"...eyJub2RlQ2VydFBldW0iOiAi...\""
TRANSLATIONS_EN[node_port_info]="• Node port:"
TRANSLATIONS_EN[node_directory_info]="• Node directory:"

TRANSLATIONS_EN[container_error_provide_args]="Error: provide directory and display name"
TRANSLATIONS_EN[container_error_directory_not_found]="Error: directory \"%s\" not found"
TRANSLATIONS_EN[container_error_compose_not_found]="Error: docker-compose.yml not found in \"%s\""
TRANSLATIONS_EN[container_error_docker_not_installed]="Error: Docker is not installed or not in PATH"
TRANSLATIONS_EN[container_error_docker_not_running]="Error: Docker daemon is not running"
TRANSLATIONS_EN[container_rate_limit_error]="✖ Docker Hub rate limit while pulling images for \"%s\"."
TRANSLATIONS_EN[container_rate_limit_cause]="Cause: pull rate limit exceeded."
TRANSLATIONS_EN[container_rate_limit_solutions]="Possible solutions:"
TRANSLATIONS_EN[container_rate_limit_wait]="1. Wait ~6 h and retry"
TRANSLATIONS_EN[container_rate_limit_login]="2. docker login"
TRANSLATIONS_EN[container_rate_limit_vpn]="3. Use VPN / other IP"
TRANSLATIONS_EN[container_rate_limit_mirror]="4. Set up a mirror"
TRANSLATIONS_EN[container_success_up]="✔ \"%s\" is up (services: %s)."
TRANSLATIONS_EN[container_failed_start]="✖ \"%s\" failed to start entirely."
TRANSLATIONS_EN[container_compose_output]="→ docker compose output:"
TRANSLATIONS_EN[container_problematic_services]="→ Problematic services status:"

TRANSLATIONS_EN[exiting]="Exiting."
TRANSLATIONS_EN[creating_user]="Creating user:"
TRANSLATIONS_EN[please_wait]="Please wait..."
TRANSLATIONS_EN[operation_completed]="Operation completed."

TRANSLATIONS_EN[node_enter_selfsteal_domain]="Enter Selfsteal domain, e.g. domain.example.com"
TRANSLATIONS_EN[node_enter_panel_ip]="Enter the IP address of the panel server (for configuring firewall)"
TRANSLATIONS_EN[node_allow_connections]="Allow connections from panel server to node port 2222..."
TRANSLATIONS_EN[node_enter_ssl_cert_prompt]="Enter the server certificate in format SSL_CERT=\"...\" (paste the content and press Enter twice):"
TRANSLATIONS_EN[node_press_enter_return]="Press Enter to return to the main menu..."

TRANSLATIONS_EN[vless_enter_node_host]="Enter the IP address or domain of the node server (if different from Selfsteal domain)"
TRANSLATIONS_EN[vless_public_key_required]="Public key (required for node installation):"

TRANSLATIONS_EN[container_name_remnawave_panel]="Remnawave Panel"
TRANSLATIONS_EN[container_name_subscription_page]="Subscription Page"
TRANSLATIONS_EN[container_name_remnawave_node]="Remnawave Node"

TRANSLATIONS_EN[selfsteal_installation_stopped]="Installation stopped"
TRANSLATIONS_EN[selfsteal_domain_info]="• Domain:"
TRANSLATIONS_EN[selfsteal_port_info]="• Port:"
TRANSLATIONS_EN[selfsteal_directory_info]="• Directory:"

TRANSLATIONS_EN[warp_title]="WARP Integration Setup"
TRANSLATIONS_EN[warp_checking_installation]="Checking panel installation..."
TRANSLATIONS_EN[warp_panel_not_found]="Panel installation not found"
TRANSLATIONS_EN[warp_panel_not_running]="Panel is not running"
TRANSLATIONS_EN[warp_credentials_not_found]="Panel credentials not found"
TRANSLATIONS_EN[warp_terms_title]="Cloudflare WARP Terms of Service"
TRANSLATIONS_EN[warp_terms_text]="This project is in no way affiliated with Cloudflare.\nBy proceeding, you agree to Cloudflare's Terms of Service:"
TRANSLATIONS_EN[warp_terms_url]="https://www.cloudflare.com/application/terms/"
TRANSLATIONS_EN[warp_terms_confirm]="Do you agree to the terms and want to continue?"
TRANSLATIONS_EN[warp_terms_declined]="WARP integration cancelled"
TRANSLATIONS_EN[warp_downloading_wgcf]="Downloading wgcf utility..."
TRANSLATIONS_EN[warp_installing_wgcf]="Installing wgcf..."
TRANSLATIONS_EN[warp_authenticating_panel]="Authenticating with panel..."
TRANSLATIONS_EN[warp_registering_account]="Registering WARP account..."
TRANSLATIONS_EN[warp_generating_config]="Generating WireGuard configuration..."
TRANSLATIONS_EN[warp_getting_current_config]="Getting current XRAY configuration..."
TRANSLATIONS_EN[warp_updating_config]="Updating XRAY configuration with WARP..."
TRANSLATIONS_EN[warp_success]="WARP integration added successfully!"
TRANSLATIONS_EN[warp_success_details]="WARP outbound has been added to your XRAY configuration.\nYou can add more domains in the panel, by editing the Xray config."
TRANSLATIONS_EN[warp_failed_download]="Failed to download wgcf"
TRANSLATIONS_EN[warp_failed_install]="Failed to install wgcf"
TRANSLATIONS_EN[warp_failed_register]="Failed to register WARP account"
TRANSLATIONS_EN[warp_failed_generate]="Failed to generate WireGuard configuration"
TRANSLATIONS_EN[warp_failed_get_config]="Failed to get current XRAY configuration"
TRANSLATIONS_EN[warp_failed_update_config]="Failed to update XRAY configuration"
TRANSLATIONS_EN[warp_failed_auth]="Failed to authenticate with panel"
TRANSLATIONS_EN[warp_already_configured]="WARP is already configured in XRAY"

TRANSLATIONS_EN[warp_docker_title]="Docker WARP Native Integration"
TRANSLATIONS_EN[warp_docker_subtitle]="GitHub: https://github.com/xxphantom/docker-warp-native"
TRANSLATIONS_EN[warp_docker_downloading]="Downloading docker-compose.yml..."
TRANSLATIONS_EN[warp_docker_download_failed]="Failed to download docker-compose.yml"
TRANSLATIONS_EN[warp_docker_starting]="Starting WARP container..."
TRANSLATIONS_EN[warp_docker_start_failed]="Failed to start WARP container"
TRANSLATIONS_EN[warp_docker_logs]="Container logs:"
TRANSLATIONS_EN[warp_docker_no_docker]="Docker is not installed"
TRANSLATIONS_EN[warp_docker_already_installed]="Docker WARP Native is already installed"
TRANSLATIONS_EN[warp_docker_reinstall]="Do you want to reinstall it?"
TRANSLATIONS_EN[warp_docker_config_title]="WARP Configuration for XRAY"
TRANSLATIONS_EN[warp_docker_config_info]="To use WARP in your XRAY configuration, add the following:"
TRANSLATIONS_EN[warp_docker_outbound_title]="Outbound configuration"
TRANSLATIONS_EN[warp_docker_routing_title]="Routing rule example"
TRANSLATIONS_EN[warp_docker_config_note]="Note: Replace 'example.com' with domains you want to route through WARP"
TRANSLATIONS_EN[warp_docker_success]="Docker WARP Native installed successfully!"
TRANSLATIONS_EN[warp_docker_success_details]="WARP outbound has been added. ipinfo.io will route through WARP"
TRANSLATIONS_EN[warp_docker_profile_not_found]="Profile not found"
TRANSLATIONS_EN[warp_docker_updating_config_only]="Updating configuration only (container already running)"
TRANSLATIONS_EN[warp_docker_config_added]="WARP configuration has been added to the profile:"
TRANSLATIONS_EN[warp_docker_outbound_added]="Outbound added"
TRANSLATIONS_EN[warp_docker_routing_added]="Routing rule added"
TRANSLATIONS_EN[warp_docker_edit_domains]="Edit domains in the panel to route specific sites through WARP"
TRANSLATIONS_EN[warp_docker_config_updated]="Profile has been updated with WARP configuration"

TRANSLATIONS_EN[spinner_getting_nodes]="Getting list of nodes..."
TRANSLATIONS_EN[api_empty_response_getting_nodes]="Empty response when getting nodes"
TRANSLATIONS_EN[warp_select_nodes_title]="Select nodes for WARP integration:"
TRANSLATIONS_EN[warp_all_nodes]="All nodes"
TRANSLATIONS_EN[warp_node_local]="(local)"
TRANSLATIONS_EN[warp_no_nodes_found]="No nodes found in the panel"
TRANSLATIONS_EN[warp_select_node_prompt]="Enter node number: "
TRANSLATIONS_EN[warp_invalid_selection]="Invalid selection"
TRANSLATIONS_EN[warp_panel_only_detected]="Panel-only installation detected"
TRANSLATIONS_EN[warp_node_only_detected]="Node-only installation detected"
TRANSLATIONS_EN[warp_installing_container_only]="Installing Docker WARP container only..."
TRANSLATIONS_EN[warp_remote_nodes_warning]="For remote nodes, you must run this script on each node server to install Docker WARP"
TRANSLATIONS_EN[warp_docker_repo_link]="Docker WARP repository: https://github.com/xxphantom/docker-warp-native"
TRANSLATIONS_EN[warp_config_will_update]="Xray configuration will be updated for selected nodes"
TRANSLATIONS_EN[warp_manual_config_needed]="You need to update the Xray configuration manually or run this script with panel access"
TRANSLATIONS_EN[warp_container_installed_node_only]="Docker WARP container installed. Panel configuration update required."
TRANSLATIONS_EN[warp_single_local_node_detected]="Local node detected"
TRANSLATIONS_EN[warp_single_remote_node_detected]="Remote node detected"
TRANSLATIONS_EN[warp_found_profiles]="Found unique profiles"
TRANSLATIONS_EN[warp_profile_updated]="Profile updated for nodes"
TRANSLATIONS_EN[warp_affected_nodes_profiles]="Affected nodes and profiles"
TRANSLATIONS_EN[warp_nodes]="Nodes"
TRANSLATIONS_EN[warp_profile]="profile"
TRANSLATIONS_EN[warp_nodes_lowercase]="nodes"

# Including module: ru.sh



TRANSLATIONS_RU[error_root_required]="Ошибка: Этот скрипт должен быть запущен от имени root (sudo)"
TRANSLATIONS_RU[error_invalid_choice]="Неверный выбор, попробуйте снова."
TRANSLATIONS_RU[error_empty_response]="Ошибка: Пустой ответ от сервера при создании пользователя."
TRANSLATIONS_RU[error_failed_create_user]="Ошибка: Не удалось создать пользователя. HTTP статус:"
TRANSLATIONS_RU[error_passwords_no_match]="Пароли не совпадают. Попробуйте снова."
TRANSLATIONS_RU[error_enter_yn]="Пожалуйста, введите 'y' или 'n'."
TRANSLATIONS_RU[error_enter_number_between]="Пожалуйста, введите число от"

TRANSLATIONS_RU[main_menu_title]="Remnawave Panel Installer by uphantom v"
TRANSLATIONS_RU[main_menu_script_branch]="Ветка скрипта:"
TRANSLATIONS_RU[main_menu_panel_branch]="Ветка панели:"
TRANSLATIONS_RU[main_menu_install_components]="Установить Панель/Ноду"
TRANSLATIONS_RU[main_menu_update_components]="Обновить Панель/Ноду"
TRANSLATIONS_RU[main_menu_restart_panel]="Перезапустить панель"
TRANSLATIONS_RU[main_menu_remove_panel]="Удалить панель"
TRANSLATIONS_RU[main_menu_rescue_cli]="Remnawave Rescue CLI [Сброс админа]"
TRANSLATIONS_RU[main_menu_show_credentials]="Показать учетные данные панели"
TRANSLATIONS_RU[main_menu_warp_integration]="Добавить WARP интеграцию (Native WARP in Docker)"
TRANSLATIONS_RU[main_menu_exit]="Выход"
TRANSLATIONS_RU[main_menu_select_option]="Выберите опцию:"

TRANSLATIONS_RU[install_menu_title]="Установка панели/ноды"
TRANSLATIONS_RU[install_menu_panel_only]="Только панель:"
TRANSLATIONS_RU[install_menu_panel_full_security]="\"FULL Caddy\" вариант установки панели (рекомендуется)"
TRANSLATIONS_RU[install_menu_panel_simple_security]="\"SIMPLE cookie\" вариант установки панели"
TRANSLATIONS_RU[install_menu_node_only]="Только нода:"
TRANSLATIONS_RU[install_menu_node_separate]="Только нода (для отдельного сервера)"
TRANSLATIONS_RU[install_menu_all_in_one]="All-in-One:"
TRANSLATIONS_RU[install_menu_panel_node_full]="Панель + Нода \"FULL Caddy\" вариант"
TRANSLATIONS_RU[install_menu_panel_node_simple]="Панель + Нода \"SIMPLE cookie\" вариант"
TRANSLATIONS_RU[install_menu_back]="Назад в главное меню"

TRANSLATIONS_RU[update_menu_title]="Обновление панели/ноды"
TRANSLATIONS_RU[update_menu_panel_only]="Только панель:"
TRANSLATIONS_RU[update_menu_panel_update]="Обновить панель (также обновит ноду, если на том же сервере)"
TRANSLATIONS_RU[update_menu_node_only]="Только нода:"
TRANSLATIONS_RU[update_menu_node_separate]="Обновить ноду (для отдельного сервера)"
TRANSLATIONS_RU[update_menu_back]="Назад в главное меню"

TRANSLATIONS_RU[prompt_yes_no_suffix]=" (y/n): "
TRANSLATIONS_RU[prompt_yes_no_default_suffix]=" (y/n) ["
TRANSLATIONS_RU[prompt_enter_to_continue]="Нажмите Enter для продолжения..."
TRANSLATIONS_RU[prompt_enter_to_return]="Нажмите Enter для возврата в меню..."

TRANSLATIONS_RU[success_bbr_enabled]="BBR успешно включен"
TRANSLATIONS_RU[success_bbr_disabled]="BBR отключен, активен cubic + fq_codel"
TRANSLATIONS_RU[success_credentials_saved]="Учетные данные сохранены в файле:"
TRANSLATIONS_RU[success_installation_complete]="Установка завершена. Нажмите Enter для продолжения..."

TRANSLATIONS_RU[warning_skipping_telegram]="Пропускаем интеграцию с Telegram."
TRANSLATIONS_RU[warning_bbr_not_configured]="BBR не был настроен в /etc/sysctl.conf"
TRANSLATIONS_RU[warning_enter_different_domain]="Пожалуйста, введите другой домен для"

TRANSLATIONS_RU[info_removing_bbr_config]="Удаление конфигурации BBR из /etc/sysctl.conf…"
TRANSLATIONS_RU[info_installation_directory]="Директория установки:"

TRANSLATIONS_RU[bbr_enable]="Включить BBR"
TRANSLATIONS_RU[bbr_disable]="Отключить BBR"

TRANSLATIONS_RU[telegram_enable_notifications]="Хотите ли вы включить уведомления Telegram?"
TRANSLATIONS_RU[telegram_bot_token]="Введите токен вашего Telegram бота: "
TRANSLATIONS_RU[telegram_enable_user_notifications]="Хотите ли вы включить уведомления о событиях пользователей? (если отключено, будут отправляться только уведомления о событиях нод)"
TRANSLATIONS_RU[telegram_users_chat_id]="Введите ID чата для уведомлений о событиях пользователей: "
TRANSLATIONS_RU[telegram_enable_crm_notifications]="Хотите ли вы включить CRM уведомления?"
TRANSLATIONS_RU[telegram_crm_chat_id]="Введите ID чата для CRM уведомлений: "
TRANSLATIONS_RU[telegram_nodes_chat_id]="Введите ID чата для уведомлений о событиях нод: "
TRANSLATIONS_RU[telegram_use_topics]="Хотите ли вы использовать темы Telegram?"
TRANSLATIONS_RU[telegram_users_thread_id]="Введите ID топика для событий пользователей: "
TRANSLATIONS_RU[telegram_crm_thread_id]="Введите ID топика для CRM уведомлений: "
TRANSLATIONS_RU[telegram_nodes_thread_id]="Введите ID топика для событий нод: "

TRANSLATIONS_RU[domain_panel_prompt]="Введите домен панели (будет использоваться на сервере панели), например panel.example.com"
TRANSLATIONS_RU[domain_subscription_prompt]="Введите домен подписки (будет использоваться на сервере панели), например sub.example.com"
TRANSLATIONS_RU[domain_selfsteal_prompt]="Введите домен Selfsteal (будет использоваться на сервере ноды), например domain.example.com"

TRANSLATIONS_RU[auth_admin_username]="Введите имя пользователя администратора: "
TRANSLATIONS_RU[auth_admin_password]="Введите пароль администратора: "
TRANSLATIONS_RU[auth_admin_email]="Введите email администратора для Caddy Auth"
TRANSLATIONS_RU[auth_confirm_password]="Пожалуйста, подтвердите ваш пароль"

TRANSLATIONS_RU[panel_invalid_auth_type]="Неверный тип аутентификации"
TRANSLATIONS_RU[panel_auth_type_options]="Допустимые варианты: 'cookie' или 'full'"

TRANSLATIONS_RU[results_secure_login_link]="Безопасная ссылка для входа (с секретным ключом):"
TRANSLATIONS_RU[results_user_subscription_url]="URL подписки пользователя:"
TRANSLATIONS_RU[results_admin_login]="Логин администратора:"
TRANSLATIONS_RU[results_admin_password]="Пароль администратора:"
TRANSLATIONS_RU[results_caddy_auth_login]="Логин авторизации Caddy:"
TRANSLATIONS_RU[results_caddy_auth_password]="Пароль авторизации Caddy:"
TRANSLATIONS_RU[results_remnawave_admin_login]="Логин администратора Remnawave:"
TRANSLATIONS_RU[results_remnawave_admin_password]="Пароль администратора Remnawave:"
TRANSLATIONS_RU[results_auth_portal_page]="Страница портала авторизации:"

TRANSLATIONS_RU[qr_subscription_url]="QR-код URL подписки"

TRANSLATIONS_RU[password_min_length]="Пароль должен содержать не менее"
TRANSLATIONS_RU[password_min_length_suffix]="символов."
TRANSLATIONS_RU[password_need_digit]="Пароль должен содержать хотя бы одну цифру."
TRANSLATIONS_RU[password_need_lowercase]="Пароль должен содержать хотя бы одну строчную букву."
TRANSLATIONS_RU[password_need_uppercase]="Пароль должен содержать хотя бы одну заглавную букву."
TRANSLATIONS_RU[password_try_again]="Попробуйте снова."

TRANSLATIONS_RU[port_panel_prompt]="Введите порт панели (по умолчанию: 443): "
TRANSLATIONS_RU[port_node_prompt]="Введите порт ноды (по умолчанию: 2222): "
TRANSLATIONS_RU[port_caddy_local_prompt]="Введите локальный порт Caddy (по умолчанию: 9443): "

TRANSLATIONS_RU[installation_preparing]="Подготовка установки..."
TRANSLATIONS_RU[installation_starting_services]="Запуск сервисов..."
TRANSLATIONS_RU[installation_configuring]="Настройка..."

TRANSLATIONS_RU[credentials_found]="Учетные данные панели найдены:"
TRANSLATIONS_RU[credentials_not_found]="Файл учетных данных не найден!"
TRANSLATIONS_RU[credentials_file_location]="Файл учетных данных не существует по адресу:"
TRANSLATIONS_RU[credentials_reasons]="Обычно это означает:"
TRANSLATIONS_RU[credentials_reason_not_installed]="Панель еще не установлена"
TRANSLATIONS_RU[credentials_reason_incomplete]="Установка не была завершена успешно"
TRANSLATIONS_RU[credentials_reason_deleted]="Файл учетных данных был удален вручную"
TRANSLATIONS_RU[credentials_try_install]="Попробуйте сначала установить панель, используя опцию 1 из главного меню."

TRANSLATIONS_RU[cli_container_not_running]="Контейнер Remnawave не запущен!"
TRANSLATIONS_RU[cli_ensure_panel_running]="Пожалуйста, убедитесь, что панель установлена и запущена."
TRANSLATIONS_RU[cli_session_completed]="Сессия CLI завершена успешно"
TRANSLATIONS_RU[cli_session_failed]="Сессия CLI завершилась неудачно или была прервана"

TRANSLATIONS_RU[removal_installation_detected]="Обнаружена установка RemnaWave."
TRANSLATIONS_RU[removal_confirm_delete]="Вы уверены, что хотите полностью УДАЛИТЬ Remnawave? ЭТО УДАЛИТ ВСЕ ДАННЫЕ!!! Продолжить?"
TRANSLATIONS_RU[removal_previous_detected]="Обнаружена предыдущая установка RemnaWave."
TRANSLATIONS_RU[removal_confirm_continue]="Для продолжения необходимо УДАЛИТЬ предыдущую установку Remnawave. ЭТО УДАЛИТ ВСЕ ДАННЫЕ!!! Продолжить?"
TRANSLATIONS_RU[removal_complete_success]="Remnawave был полностью удален из вашей системы. Нажмите любую клавишу для продолжения..."
TRANSLATIONS_RU[removal_previous_success]="Предыдущая установка удалена."
TRANSLATIONS_RU[removal_no_installation]="Установка Remnawave не обнаружена в этой системе."
TRANSLATIONS_RU[removal_keep_caddy_data]="✓ Данные Caddy (сертификаты) будут сохранены."

TRANSLATIONS_RU[restart_panel_dir_not_found]="Ошибка: директория панели не найдена в /opt/remnawave!"
TRANSLATIONS_RU[restart_install_panel_first]="Пожалуйста, сначала установите панель Remnawave."
TRANSLATIONS_RU[restart_compose_not_found]="Ошибка: docker-compose.yml не найден в директории панели!"
TRANSLATIONS_RU[restart_installation_corrupted]="Установка панели может быть повреждена или неполная."
TRANSLATIONS_RU[restart_starting_panel]="Запуск основной панели..."
TRANSLATIONS_RU[restart_starting_subscription]="Запуск страницы подписки..."
TRANSLATIONS_RU[restart_success]="Панель успешно перезапущена"

TRANSLATIONS_RU[update_panel_dir_not_found]="Ошибка: директория панели не найдена в /opt/remnawave!"
TRANSLATIONS_RU[update_node_dir_not_found]="Ошибка: директория ноды не найдена в /opt/remnanode!"
TRANSLATIONS_RU[update_install_first]="Пожалуйста, сначала установите компоненты."
TRANSLATIONS_RU[update_compose_not_found]="Ошибка: docker-compose.yml не найден!"
TRANSLATIONS_RU[update_installation_corrupted]="Установка может быть повреждена или неполная."
TRANSLATIONS_RU[update_warning_title]="⚠️  ВАЖНО: Перед обновлением"
TRANSLATIONS_RU[update_warning_backup]="• Убедитесь, что у вас есть резервные копии данных"
TRANSLATIONS_RU[update_warning_changelog]="• Прочитайте changelog перед обновлением:"
TRANSLATIONS_RU[update_warning_panel_releases]="  Панель: https://github.com/remnawave/panel/releases/"
TRANSLATIONS_RU[update_warning_node_releases]="  Нода: https://hub.remna.st/changelog"
TRANSLATIONS_RU[update_warning_downtime]="• Процесс обновления вызовет временную недоступность сервисов"
TRANSLATIONS_RU[update_warning_confirm]="Хотите ли вы продолжить обновление?"
TRANSLATIONS_RU[update_checking_images]="Проверка обновлений образов..."
TRANSLATIONS_RU[update_pulling_images]="Загрузка последних образов..."
TRANSLATIONS_RU[update_no_updates_available]="Обновления недоступны - все образы уже актуальны"
TRANSLATIONS_RU[update_images_updated]="Новые образы загружены, выполняется перезапуск..."
TRANSLATIONS_RU[update_pull_failed]="Не удалось загрузить образы"
TRANSLATIONS_RU[update_stopping_services]="Остановка сервисов..."
TRANSLATIONS_RU[update_starting_services]="Запуск обновленных сервисов..."
TRANSLATIONS_RU[update_panel_success]="Панель успешно обновлена"
TRANSLATIONS_RU[update_node_success]="Нода успешно обновлена"
TRANSLATIONS_RU[update_all_success]="Панель и нода успешно обновлены"
TRANSLATIONS_RU[update_no_restart_needed]="Перезапуск не требуется - сервисы уже используют последние версии"
TRANSLATIONS_RU[update_cleaning_images]="Очистка неиспользуемых образов..."
TRANSLATIONS_RU[update_cleanup_complete]="Очистка завершена"
TRANSLATIONS_RU[update_cancelled]="Обновление отменено пользователем"

TRANSLATIONS_RU[services_starting_containers]="Запуск контейнеров..."
TRANSLATIONS_RU[services_installation_stopped]="Установка остановлена"

TRANSLATIONS_RU[system_distro_not_supported]="Дистрибутив"
TRANSLATIONS_RU[system_dependencies_success]="Все зависимости установлены и настроены."
TRANSLATIONS_RU[system_created_directory]="Создана директория:"
TRANSLATIONS_RU[system_installation_cancelled]="Установка отменена. Возврат в главное меню."
TRANSLATIONS_RU[system_distro_not_supported]="Дистрибутив не поддерживается:"
TRANSLATIONS_RU[docker_already_installed]="Современная версия Docker уже установлена:"
TRANSLATIONS_RU[docker_check_failed]="Современная версия Docker не найдена. Выполняется полная (пере)установка."
TRANSLATIONS_RU[removing_old_docker]="Удаление старой или конфликтующей версии Docker..."
TRANSLATIONS_RU[old_docker_removed]="Старая версия Docker успешно удалена."
TRANSLATIONS_RU[deleting_docker_data]="ВНИМАНИЕ: Удаление всех существующих данных Docker (образы, контейнеры, тома)..."
TRANSLATIONS_RU[spinner_updating_apt_cache]="Обновление кэша пакетов (apt)..."
TRANSLATIONS_RU[spinner_installing_packages]="Установка необходимых пакетов:"
TRANSLATIONS_RU[packages_already_installed]="Необходимые пакеты уже установлены."
TRANSLATIONS_RU[installing_docker]="Установка Docker Engine..."
TRANSLATIONS_RU[docker_installed]="Docker Engine успешно установлен."
TRANSLATIONS_RU[spinner_starting_docker]="Запуск службы Docker..."
TRANSLATIONS_RU[spinner_docker_already_running]="Служба Docker уже запущена."
TRANSLATIONS_RU[spinner_adding_user_to_group]="Добавление текущего пользователя в группу 'docker'..."
TRANSLATIONS_RU[relogin_required]="Необходимо выйти из системы и войти снова, чтобы изменения вступили в силу."
TRANSLATIONS_RU[spinner_firewall_already_set]="Правила брандмауэра уже настроены."
TRANSLATIONS_RU[spinner_configuring_firewall]="Настройка брандмауэра (UFW)..."
TRANSLATIONS_RU[ufw_ports_opened]="Брандмауэр настроен. Открыты TCP порты:"
TRANSLATIONS_RU[spinner_auto_updates_already_set]="Автоматические обновления безопасности уже включены."
TRANSLATIONS_RU[spinner_setting_auto_updates]="Включение автоматических обновлений безопасности..."
TRANSLATIONS_RU[auto_updates_enabled]="Автоматические обновления безопасности включены."
TRANSLATIONS_RU[all_dependencies_installed]="Все зависимости и базовая настройка завершены."

TRANSLATIONS_RU[prompt_press_any_key]="Нажмите любую клавишу для продолжения..."

TRANSLATIONS_RU[spinner_generating_keys]="Генерация ключей x25519..."
TRANSLATIONS_RU[spinner_updating_xray]="Обновление конфигурации Xray..."
TRANSLATIONS_RU[spinner_registering_user]="Регистрация пользователя"
TRANSLATIONS_RU[spinner_getting_public_key]="Получение публичного ключа..."
TRANSLATIONS_RU[spinner_creating_node]="Создание ноды..."
TRANSLATIONS_RU[spinner_getting_inbounds]="Получение списка входящих соединений..."
TRANSLATIONS_RU[spinner_creating_config_profile]="Создание профиля конфигурации..."
TRANSLATIONS_RU[spinner_getting_config_profiles]="Получение профилей конфигурации..."
TRANSLATIONS_RU[spinner_deleting_config_profile]="Удаление профиля конфигурации по умолчанию..."
TRANSLATIONS_RU[spinner_getting_squads]="Получение списка сквадов..."
TRANSLATIONS_RU[spinner_updating_squad]="Обновление сквада с новым подключением..."
TRANSLATIONS_RU[spinner_creating_host]="Создание хоста..."
TRANSLATIONS_RU[spinner_cleaning_services]="Очистка сервисов"
TRANSLATIONS_RU[spinner_force_removing]="Принудительное удаление контейнера"
TRANSLATIONS_RU[spinner_removing_directory]="Удаление директории"
TRANSLATIONS_RU[spinner_stopping_subscription]="Остановка контейнера remnawave-subscription-page"
TRANSLATIONS_RU[spinner_restarting_panel]="Перезапуск панели..."
TRANSLATIONS_RU[spinner_launching]="Запуск"
TRANSLATIONS_RU[spinner_updating_apt_cache]="Обновление кэша APT"
TRANSLATIONS_RU[spinner_installing_packages]="Установка пакетов:"
TRANSLATIONS_RU[spinner_starting_docker]="Запуск демона Docker"
TRANSLATIONS_RU[spinner_docker_already_running]="Демон Docker уже запущен"
TRANSLATIONS_RU[spinner_firewall_already_set]="Брандмауэр уже настроен"
TRANSLATIONS_RU[spinner_configuring_firewall]="Настройка брандмауэра"
TRANSLATIONS_RU[spinner_auto_updates_already_set]="Автообновления уже настроены"
TRANSLATIONS_RU[spinner_setting_auto_updates]="Настройка автообновлений"
TRANSLATIONS_RU[spinner_downloading_static_files]="Загрузка статических файлов для сайта selfsteal..."

TRANSLATIONS_RU[config_invalid_arguments]="Ошибка: неверное количество аргументов. Должно быть четное количество ключей и значений."
TRANSLATIONS_RU[config_domain_already_used]="Домен"
TRANSLATIONS_RU[config_domains_must_be_unique]="Каждый домен должен быть уникальным: домен панели, домен подписки и домен selfsteal должны быть разными."
TRANSLATIONS_RU[config_caddy_port_available]="Требуемый порт Caddy 9443 доступен"
TRANSLATIONS_RU[config_caddy_port_in_use]="Требуемый порт Caddy 9443 уже используется!"
TRANSLATIONS_RU[config_node_port_available]="Требуемый порт API ноды 2222 доступен"
TRANSLATIONS_RU[config_node_port_in_use]="Требуемый порт API ноды 2222 уже используется!"
TRANSLATIONS_RU[config_separate_installation_port_required]="Для отдельной установки панели и ноды порт"
TRANSLATIONS_RU[config_free_port_and_retry]="Пожалуйста, освободите порт"
TRANSLATIONS_RU[config_installation_cannot_continue]="Установка не может продолжиться с занятым портом"

TRANSLATIONS_RU[misc_qr_generation_failed]="Не удалось создать QR-код"

TRANSLATIONS_RU[network_error_port_number]="Ошибка: Порт должен быть числом."
TRANSLATIONS_RU[network_error_port_range]="Ошибка: Порт должен быть от 1 до 65535."
TRANSLATIONS_RU[network_invalid_email]="Неверный формат email."
TRANSLATIONS_RU[network_proceed_with_value]="Продолжить с этим значением? Текущее значение:"
TRANSLATIONS_RU[network_using_default_port]="Используется порт по умолчанию:"
TRANSLATIONS_RU[network_port_in_use]="порт уже используется. Поиск доступного порта..."
TRANSLATIONS_RU[network_using_port]="Используется порт:"
TRANSLATIONS_RU[network_failed_find_port]="Не удалось найти доступный порт для"
TRANSLATIONS_RU[network_invalid_domain]="Неверный формат домена. Попробуйте снова."
TRANSLATIONS_RU[network_failed_determine_ip]="Не удалось определить IP-адрес домена или сервера."
TRANSLATIONS_RU[network_make_sure_domain]="Убедитесь, что домен"
TRANSLATIONS_RU[network_points_to_server]="правильно настроен и указывает на сервер"
TRANSLATIONS_RU[network_continue_despite_ip]="Продолжить с этим доменом, несмотря на невозможность проверить его IP-адрес?"
TRANSLATIONS_RU[network_domain_points_cloudflare]="Домен"
TRANSLATIONS_RU[network_points_cloudflare_ip]="указывает на IP Cloudflare"
TRANSLATIONS_RU[network_disable_cloudflare]="Отключите проксирование Cloudflare - проксирование домена selfsteal не разрешено."
TRANSLATIONS_RU[network_continue_despite_cloudflare]="Продолжить с этим доменом, несмотря на проблему с конфигурацией прокси Cloudflare?"
TRANSLATIONS_RU[network_domain_points_server]="Домен"
TRANSLATIONS_RU[network_points_this_server]="указывает на IP этого сервера"
TRANSLATIONS_RU[network_separate_installation_note]="Для отдельной установки домен selfsteal должен указывать на сервер ноды, а не на сервер панели."
TRANSLATIONS_RU[network_continue_despite_current_server]="Продолжить с этим доменом, несмотря на то, что он указывает на текущий сервер?"
TRANSLATIONS_RU[network_domain_points_different]="Домен"
TRANSLATIONS_RU[network_points_different_ip]="указывает на IP-адрес"
TRANSLATIONS_RU[network_differs_from_server]="который отличается от IP сервера"
TRANSLATIONS_RU[network_continue_despite_mismatch]="Продолжить с этим доменом, несмотря на несоответствие IP-адресов?"

TRANSLATIONS_RU[api_empty_server_response]="Пустой ответ сервера"
TRANSLATIONS_RU[api_registration_failed]="Регистрация не удалась: неизвестная ошибка"
TRANSLATIONS_RU[api_failed_get_public_key]="Ошибка: Не удалось получить публичный ключ."
TRANSLATIONS_RU[api_failed_extract_public_key]="Ошибка: Не удалось извлечь публичный ключ из ответа."
TRANSLATIONS_RU[api_empty_response_creating_node]="Ошибка: Пустой ответ от сервера при создании ноды."
TRANSLATIONS_RU[api_failed_create_node]="Ошибка: Не удалось создать ноду, ответ:"
TRANSLATIONS_RU[api_empty_response_getting_inbounds]="Ошибка: Пустой ответ от сервера при получении входящих соединений."
TRANSLATIONS_RU[api_failed_extract_uuid]="Ошибка: Не удалось извлечь UUID из ответа."
TRANSLATIONS_RU[api_empty_response_creating_profile]="Ошибка: Пустой ответ от сервера при создании профиля конфигурации."
TRANSLATIONS_RU[api_failed_create_profile]="Ошибка: Не удалось создать профиль конфигурации."
TRANSLATIONS_RU[api_empty_response_getting_profiles]="Ошибка: Пустой ответ от сервера при получении профилей конфигурации."
TRANSLATIONS_RU[api_failed_delete_profile]="Ошибка: Не удалось удалить профиль конфигурации."
TRANSLATIONS_RU[api_empty_response_getting_squads]="Ошибка: Пустой ответ от сервера при получении сквадов."
TRANSLATIONS_RU[api_empty_response_updating_squad]="Ошибка: Пустой ответ от сервера при обновлении сквада."
TRANSLATIONS_RU[api_failed_update_squad]="Ошибка: Не удалось обновить сквад."
TRANSLATIONS_RU[api_empty_response_creating_host]="Ошибка: Пустой ответ от сервера при создании хоста."
TRANSLATIONS_RU[api_failed_create_host]="Ошибка: Не удалось создать хост."
TRANSLATIONS_RU[api_empty_response_creating_user]="Ошибка: Пустой ответ от сервера при создании пользователя."
TRANSLATIONS_RU[api_failed_create_user_status]="Ошибка: Не удалось создать пользователя. HTTP статус:"
TRANSLATIONS_RU[api_failed_create_user_format]="Ошибка: Не удалось создать пользователя, неверный формат ответа:"
TRANSLATIONS_RU[api_failed_register_user]="Не удалось зарегистрировать пользователя."
TRANSLATIONS_RU[api_request_body_was]="Тело запроса было:"
TRANSLATIONS_RU[api_response]="Ответ:"

TRANSLATIONS_RU[validation_value_min]="Значение должно быть не менее"
TRANSLATIONS_RU[validation_value_max]="Значение должно быть не более"
TRANSLATIONS_RU[validation_enter_numeric]="Пожалуйста, введите корректное числовое значение."
TRANSLATIONS_RU[validation_input_empty]="Ввод не может быть пустым. Пожалуйста, введите корректный домен или IP-адрес."
TRANSLATIONS_RU[validation_invalid_ip]="Неверный формат IP-адреса. IP должен быть в формате X.X.X.X, где X - число от 0 до 255."
TRANSLATIONS_RU[validation_invalid_domain]="Неверный формат доменного имени. Домен должен содержать хотя бы одну точку и не начинаться/заканчиваться точкой или тире."
TRANSLATIONS_RU[validation_use_only_letters]="Используйте только буквы, цифры, точки и тире."
TRANSLATIONS_RU[validation_invalid_domain_ip]="Неверный формат домена или IP-адреса."
TRANSLATIONS_RU[validation_domain_format]="Домен должен содержать хотя бы одну точку и не начинаться/заканчиваться точкой или тире."
TRANSLATIONS_RU[validation_ip_format]="IP-адрес должен быть в формате X.X.X.X, где X - число от 0 до 255."
TRANSLATIONS_RU[validation_max_attempts_default]="Превышено максимальное количество попыток. Используется значение по умолчанию:"
TRANSLATIONS_RU[validation_max_attempts_no_input]="Превышено максимальное количество попыток. Корректный ввод не предоставлен."
TRANSLATIONS_RU[validation_cannot_continue]="Установка не может продолжиться без корректного домена или IP-адреса."

TRANSLATIONS_RU[vless_failed_generate_keys]="Ошибка: Не удалось сгенерировать ключи."
TRANSLATIONS_RU[vless_empty_response_xray]="Ошибка: Пустой ответ от сервера при обновлении конфигурации Xray."
TRANSLATIONS_RU[vless_failed_update_xray]="Ошибка: Не удалось обновить конфигурацию Xray."

TRANSLATIONS_RU[node_port_9443_in_use]="Требуемый порт Caddy 9443 уже используется!"
TRANSLATIONS_RU[node_separate_port_9443]="Для отдельной установки ноды порт 9443 должен быть доступен."
TRANSLATIONS_RU[node_free_port_9443]="Пожалуйста, освободите порт 9443 и попробуйте снова."
TRANSLATIONS_RU[node_cannot_continue_9443]="Установка не может продолжиться с занятым портом 9443"
TRANSLATIONS_RU[node_port_2222_in_use]="Требуемый порт API ноды 2222 уже используется!"
TRANSLATIONS_RU[node_separate_port_2222]="Для отдельной установки ноды порт 2222 должен быть доступен."
TRANSLATIONS_RU[node_free_port_2222]="Пожалуйста, освободите порт 2222 и попробуйте снова."
TRANSLATIONS_RU[node_cannot_continue_2222]="Установка не может продолжиться с занятым портом 2222"
TRANSLATIONS_RU[node_enter_ssl_cert]="Введите сертификат сервера в формате SSL_CERT=\"...\" (вставьте содержимое и нажмите Enter дважды):"
TRANSLATIONS_RU[node_ssl_cert_valid]="✓ Формат SSL сертификата корректен"
TRANSLATIONS_RU[node_ssl_cert_invalid]="✗ Неверный формат SSL сертификата. Попробуйте снова."
TRANSLATIONS_RU[node_ssl_cert_expected]="Ожидаемый формат: SSL_CERT=\"...eyJub2RlQ2VydFBldW0iOiAi...\""
TRANSLATIONS_RU[node_port_info]="• Порт ноды:"
TRANSLATIONS_RU[node_directory_info]="• Директория ноды:"

TRANSLATIONS_RU[container_error_provide_args]="Ошибка: укажите директорию и отображаемое имя"
TRANSLATIONS_RU[container_error_directory_not_found]="Ошибка: директория \"%s\" не найдена"
TRANSLATIONS_RU[container_error_compose_not_found]="Ошибка: docker-compose.yml не найден в \"%s\""
TRANSLATIONS_RU[container_error_docker_not_installed]="Ошибка: Docker не установлен или не находится в PATH"
TRANSLATIONS_RU[container_error_docker_not_running]="Ошибка: Демон Docker не запущен"
TRANSLATIONS_RU[container_rate_limit_error]="✖ Pull rate лимит Docker Hub при загрузке образов для \"%s\"."
TRANSLATIONS_RU[container_rate_limit_cause]="Причина: превышен pull rate лимит."
TRANSLATIONS_RU[container_rate_limit_solutions]="Возможные решения:"
TRANSLATIONS_RU[container_rate_limit_wait]="1. Подождите ~6 ч и повторите попытку"
TRANSLATIONS_RU[container_rate_limit_login]="2. docker login"
TRANSLATIONS_RU[container_rate_limit_vpn]="3. Используйте VPN / другой IP"
TRANSLATIONS_RU[container_rate_limit_mirror]="4. Настройте зеркало"
TRANSLATIONS_RU[container_success_up]="✔ \"%s\" запущен (сервисы: %s)."
TRANSLATIONS_RU[container_failed_start]="✖ \"%s\" не удалось запустить полностью."
TRANSLATIONS_RU[container_compose_output]="→ вывод docker compose:"
TRANSLATIONS_RU[container_problematic_services]="→ Статус проблемных сервисов:"

TRANSLATIONS_RU[exiting]="Выход."
TRANSLATIONS_RU[creating_user]="Создание пользователя:"
TRANSLATIONS_RU[please_wait]="Пожалуйста, подождите..."
TRANSLATIONS_RU[operation_completed]="Операция завершена."

TRANSLATIONS_RU[node_enter_selfsteal_domain]="Введите домен Selfsteal, например domain.example.com"
TRANSLATIONS_RU[node_enter_panel_ip]="Введите IP-адрес сервера панели (для настройки брандмауэра)"
TRANSLATIONS_RU[node_allow_connections]="Разрешение соединений с сервера панели на порт ноды 2222..."
TRANSLATIONS_RU[node_enter_ssl_cert_prompt]="Введите сертификат сервера в формате SSL_CERT=\"...\" (вставьте содержимое и нажмите Enter дважды):"
TRANSLATIONS_RU[node_press_enter_return]="Нажмите Enter для возврата в главное меню..."

TRANSLATIONS_RU[vless_enter_node_host]="Введите IP-адрес или домен сервера ноды (если отличается от домена Selfsteal)"
TRANSLATIONS_RU[vless_public_key_required]="Публичный ключ (требуется для установки ноды):"

TRANSLATIONS_RU[container_name_remnawave_panel]="Панель Remnawave"
TRANSLATIONS_RU[container_name_subscription_page]="Страница подписки"
TRANSLATIONS_RU[container_name_remnawave_node]="Нода Remnawave"

TRANSLATIONS_RU[selfsteal_installation_stopped]="Установка остановлена"
TRANSLATIONS_RU[selfsteal_domain_info]="• Домен:"
TRANSLATIONS_RU[selfsteal_port_info]="• Порт:"
TRANSLATIONS_RU[selfsteal_directory_info]="• Директория:"

TRANSLATIONS_RU[warp_title]="Настройка WARP интеграции"
TRANSLATIONS_RU[warp_checking_installation]="Проверка установки панели..."
TRANSLATIONS_RU[warp_panel_not_found]="Установка панели не найдена"
TRANSLATIONS_RU[warp_panel_not_running]="Панель не запущена"
TRANSLATIONS_RU[warp_credentials_not_found]="Учетные данные панели не найдены"
TRANSLATIONS_RU[warp_terms_title]="Условия использования Cloudflare WARP"
TRANSLATIONS_RU[warp_terms_text]="Этот проект никак не связан с Cloudflare.\nПродолжая, вы соглашаетесь с Условиями использования Cloudflare:"
TRANSLATIONS_RU[warp_terms_url]="https://www.cloudflare.com/application/terms/"
TRANSLATIONS_RU[warp_terms_confirm]="Согласны ли вы с условиями и хотите продолжить?"
TRANSLATIONS_RU[warp_terms_declined]="WARP интеграция отменена"
TRANSLATIONS_RU[warp_downloading_wgcf]="Загрузка утилиты wgcf..."
TRANSLATIONS_RU[warp_installing_wgcf]="Установка wgcf..."
TRANSLATIONS_RU[warp_authenticating_panel]="Авторизация в панели..."
TRANSLATIONS_RU[warp_registering_account]="Регистрация WARP аккаунта..."
TRANSLATIONS_RU[warp_generating_config]="Генерация WireGuard конфигурации..."
TRANSLATIONS_RU[warp_getting_current_config]="Получение текущей конфигурации XRAY..."
TRANSLATIONS_RU[warp_updating_config]="Обновление конфигурации XRAY с WARP..."
TRANSLATIONS_RU[warp_success]="WARP интеграция успешно добавлена!"
TRANSLATIONS_RU[warp_success_details]="WARP outbound добавлен в вашу конфигурацию XRAY.\nВы можете добавить больше доменов в панели изменив Xray конфиг."
TRANSLATIONS_RU[warp_failed_download]="Не удалось загрузить wgcf"
TRANSLATIONS_RU[warp_failed_install]="Не удалось установить wgcf"
TRANSLATIONS_RU[warp_failed_register]="Не удалось зарегистрировать WARP аккаунт"
TRANSLATIONS_RU[warp_failed_generate]="Не удалось сгенерировать WireGuard конфигурацию"
TRANSLATIONS_RU[warp_failed_get_config]="Не удалось получить текущую конфигурацию XRAY"
TRANSLATIONS_RU[warp_failed_update_config]="Не удалось обновить конфигурацию XRAY"
TRANSLATIONS_RU[warp_failed_auth]="Не удалось авторизоваться в панели"
TRANSLATIONS_RU[warp_already_configured]="WARP уже настроен в XRAY"

TRANSLATIONS_RU[warp_docker_title]="Интеграция Docker WARP Native"
TRANSLATIONS_RU[warp_docker_subtitle]="GitHub: https://github.com/xxphantom/docker-warp-native"
TRANSLATIONS_RU[warp_docker_downloading]="Загрузка docker-compose.yml..."
TRANSLATIONS_RU[warp_docker_download_failed]="Не удалось загрузить docker-compose.yml"
TRANSLATIONS_RU[warp_docker_starting]="Запуск WARP контейнера..."
TRANSLATIONS_RU[warp_docker_start_failed]="Не удалось запустить WARP контейнер"
TRANSLATIONS_RU[warp_docker_logs]="Логи контейнера:"
TRANSLATIONS_RU[warp_docker_no_docker]="Docker не установлен"
TRANSLATIONS_RU[warp_docker_already_installed]="Docker WARP Native уже установлен"
TRANSLATIONS_RU[warp_docker_reinstall]="Хотите переустановить?"
TRANSLATIONS_RU[warp_docker_config_title]="Конфигурация WARP для XRAY"
TRANSLATIONS_RU[warp_docker_config_info]="Для использования WARP в конфигурации XRAY добавьте следующее:"
TRANSLATIONS_RU[warp_docker_outbound_title]="Конфигурация исходящего соединения"
TRANSLATIONS_RU[warp_docker_routing_title]="Пример правила маршрутизации"
TRANSLATIONS_RU[warp_docker_config_note]="Примечание: Замените 'example.com' на домены, которые хотите направить через WARP"
TRANSLATIONS_RU[warp_docker_success]="Docker WARP Native успешно установлен!"
TRANSLATIONS_RU[warp_docker_success_details]="Добавлен WARP outbound. ipinfo.io будет маршрутизироваться через WARP"
TRANSLATIONS_RU[warp_docker_profile_not_found]="Профиль не найден"
TRANSLATIONS_RU[warp_docker_updating_config_only]="Обновление только конфигурации (контейнер уже запущен)"
TRANSLATIONS_RU[warp_docker_config_added]="Конфигурация WARP добавлена в профиль:"
TRANSLATIONS_RU[warp_docker_outbound_added]="Добавлен исходящий канал"
TRANSLATIONS_RU[warp_docker_routing_added]="Добавлено правило маршрутизации"
TRANSLATIONS_RU[warp_docker_edit_domains]="Отредактируйте домены в панели для маршрутизации через WARP"
TRANSLATIONS_RU[warp_docker_config_updated]="Профиль обновлен с конфигурацией WARP"

TRANSLATIONS_RU[spinner_getting_nodes]="Получение списка нод..."
TRANSLATIONS_RU[api_empty_response_getting_nodes]="Пустой ответ при получении списка нод"
TRANSLATIONS_RU[warp_select_nodes_title]="Выберите ноды для интеграции WARP:"
TRANSLATIONS_RU[warp_all_nodes]="Все ноды"
TRANSLATIONS_RU[warp_node_local]="(локальная)"
TRANSLATIONS_RU[warp_no_nodes_found]="В панели не найдено ни одной ноды"
TRANSLATIONS_RU[warp_select_node_prompt]="Введите номер ноды: "
TRANSLATIONS_RU[warp_invalid_selection]="Неверный выбор"
TRANSLATIONS_RU[warp_panel_only_detected]="Обнаружена установка только панели"
TRANSLATIONS_RU[warp_node_only_detected]="Обнаружена установка только ноды"
TRANSLATIONS_RU[warp_installing_container_only]="Установка только Docker WARP контейнера..."
TRANSLATIONS_RU[warp_remote_nodes_warning]="Для удаленных нод необходимо запустить этот скрипт на каждом сервере ноды для установки Docker WARP"
TRANSLATIONS_RU[warp_docker_repo_link]="Репозиторий Docker WARP: https://github.com/xxphantom/docker-warp-native"
TRANSLATIONS_RU[warp_config_will_update]="Конфигурация Xray будет обновлена для выбранных нод"
TRANSLATIONS_RU[warp_manual_config_needed]="Необходимо обновить конфигурацию Xray вручную или запустить скрипт с доступом к панели"
TRANSLATIONS_RU[warp_container_installed_node_only]="Docker WARP контейнер установлен. Требуется обновление конфигурации панели."
TRANSLATIONS_RU[warp_single_local_node_detected]="Обнаружена локальная нода"
TRANSLATIONS_RU[warp_single_remote_node_detected]="Обнаружена удаленная нода"
TRANSLATIONS_RU[warp_found_profiles]="Найдено уникальных профилей"
TRANSLATIONS_RU[warp_profile_updated]="Профиль обновлен для нод"
TRANSLATIONS_RU[warp_affected_nodes_profiles]="Затронутые ноды и профили"
TRANSLATIONS_RU[warp_nodes]="Ноды"
TRANSLATIONS_RU[warp_profile]="профиль"
TRANSLATIONS_RU[warp_nodes_lowercase]="ноды"

# Including module: system.sh


set -euo pipefail
IFS=$'\n\t'

install_dependencies() {
    local extra_deps=("$@")

    if ! command -v lsb_release &>/dev/null; then
        show_info "Installing lsb-release..."
        sudo apt-get update -qq
        sudo apt-get install -y --no-install-recommends lsb-release
    fi
    local distro
    distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    local codename
    codename=$(lsb_release -cs)
    if [[ "$distro" != "ubuntu" && "$distro" != "debian" ]]; then
        show_error "$(t system_distro_not_supported) $distro"
        exit 1
    fi

    local docker_ready=false
    if command -v docker &>/dev/null && docker info &>/dev/null && docker compose version &>/dev/null; then
        show_success "$(t docker_already_installed) $(docker --version)"
        docker_ready=true
    fi

    if ! $docker_ready; then
        show_info "$(t removing_old_docker)"

        local bad_pkgs=(
            docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
            docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        )
        sudo apt-get remove -y --purge "${bad_pkgs[@]}" || true
        sudo apt-get autoremove -y || true

        show_success "$(t old_docker_removed)"
    fi

    local base_deps=(ca-certificates curl gnupg jq make dnsutils ufw unattended-upgrades lsb-release coreutils)
    for pkg in "${extra_deps[@]}"; do
        [[ " ${base_deps[*]} " != *" $pkg "* ]] && base_deps+=("$pkg")
    done

    show_info "$(t spinner_updating_apt_cache)"
    sudo apt-get update

    local missing=()
    for pkg in "${base_deps[@]}"; do
        dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
    done

    if ((${#missing[@]})); then
        local missing_str="${missing[*]}"
        show_info "$(t spinner_installing_packages) $missing_str"
        sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get -y install --no-install-recommends "${missing[@]}"
        show_success "$(t spinner_installing_packages) $missing_str"
    else
        show_info "$(t packages_already_installed)"
    fi

    if ! $docker_ready; then
        show_info "$(t installing_docker)"
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "https://download.docker.com/linux/${distro}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro} ${codename} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

        show_info "$(t spinner_updating_apt_cache)"
        sudo apt-get update

        local docker_pkgs=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
        show_info "$(t spinner_installing_packages) ${docker_pkgs[*]}"
        sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get -y install "${docker_pkgs[@]}"
        show_success "$(t docker_installed)"
    fi

    if ! systemctl is-active --quiet docker; then
        (sudo systemctl enable --now docker >/dev/null 2>&1) &
        spinner $! "$(t spinner_starting_docker)"
    else
        (sleep 0.2) &
        spinner $! "$(t spinner_docker_already_running)"
    fi

    if dpkg -s ufw &>/dev/null; then
        local ssh_port=$(grep -Ei '^\s*Port\s+' /etc/ssh/sshd_config | awk '{print $2}' | head -1)
        ssh_port=${ssh_port:-22}

        if ufw status | head -1 | grep -q "Status: active" &&
           ufw status | grep -qw "${ssh_port}/tcp" &&
           ufw status | grep -qw "443/tcp" &&
           ufw status | grep -qw "80/tcp"; then
            (sleep 0.2) &
            spinner $! "$(t spinner_firewall_already_set)"
        else
            (
                sudo ufw --force reset
                sudo ufw default deny incoming
                sudo ufw allow "${ssh_port}/tcp"
                sudo ufw allow 80/tcp
                sudo ufw allow 443/tcp
                sudo ufw --force enable
            ) >/dev/null 2>&1 &
            spinner $! "$(t spinner_configuring_firewall)"
            show_success "$(t ufw_ports_opened) ${ssh_port},80,443"
        fi
    fi

    if dpkg -s unattended-upgrades &>/dev/null; then
        if systemctl is-enabled --quiet unattended-upgrades && systemctl is-active --quiet unattended-upgrades; then
            (sleep 0.2) &
            spinner $! "$(t spinner_auto_updates_already_set)"
        else
            (
                echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | sudo debconf-set-selections
                sudo dpkg-reconfigure -f noninteractive unattended-upgrades 2>/dev/null || true
                sudo sed -i '/^Unattended-Upgrade::SyslogEnable/ d' /etc/apt/apt.conf.d/50unattended-upgrades
                echo 'Unattended-Upgrade::SyslogEnable "true";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null
                sudo systemctl restart unattended-upgrades || true
            ) >/dev/null 2>&1 &
            spinner $! "$(t spinner_setting_auto_updates)"
            show_success "$(t auto_updates_enabled)"
        fi
    fi

    show_success "$(t all_dependencies_installed)"
}

create_dir() {
    local dir_path="$1"
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        show_info "$(t system_created_directory) $dir_path"
    fi
}

prepare_installation() {
    local extra_deps=("$@")
    clear_screen
    install_dependencies "${extra_deps[@]}"

    if ! remove_previous_installation; then
        show_info "$(t system_installation_cancelled)"
        return 1
    fi

    mkdir -p "$REMNAWAVE_DIR/caddy"
    cd "$REMNAWAVE_DIR"
    return 0
}

# Including module: containers.sh


remove_previous_installation() {
    local from_menu=${1:-false}

    if [ -d "$REMNAWAVE_DIR" ]; then
        if [ "$from_menu" = true ]; then
            show_warning "$(t removal_installation_detected)"
            if [ "$KEEP_CADDY_DATA" = "true" ]; then
                echo -e "${BOLD_GREEN}$(t removal_keep_caddy_data)${NC}"
            fi
            if ! prompt_yes_no "$(t removal_confirm_delete)" "$ORANGE"; then
                return 1
            fi
        else
            show_warning "$(t removal_previous_detected)"
            if [ "$KEEP_CADDY_DATA" = "true" ]; then
                echo -e "${BOLD_GREEN}$(t removal_keep_caddy_data)${NC}"
            fi
            if ! prompt_yes_no "$(t removal_confirm_continue)" "$ORANGE"; then
                return 1
            fi
        fi

        local compose_configs=(
            "$REMNAWAVE_DIR/caddy/docker-compose.yml"
            "$REMNAWAVE_DIR/subscription-page/docker-compose.yml"
            "$REMNAWAVE_DIR/docker-compose.yml"
            "$REMNANODE_DIR/docker-compose.yml"
            "$SELFSTEAL_DIR/docker-compose.yml"
            "$REMNAWAVE_DIR/panel/docker-compose.yml" # Old path - for backward compatibility
            "$REMNANODE_DIR/node/docker-compose.yml"  # Old path - for backward compatibility
        )

        for compose_file in "${compose_configs[@]}"; do
            if [ -f "$compose_file" ]; then
                local dir_path=$(dirname "$compose_file")
                local compose_cmd="docker compose down"
                
                if [[ "$dir_path" == *"/caddy"* ]] && [ "$KEEP_CADDY_DATA" = "true" ]; then
                    compose_cmd="$compose_cmd --rmi local --remove-orphans"
                else
                    compose_cmd="$compose_cmd -v --rmi local --remove-orphans"
                fi
                
                cd "$dir_path" && eval "$compose_cmd" >/dev/null 2>&1 &
                spinner $! "$(t spinner_cleaning_services) $(basename "$dir_path")"
            fi
        done

        local containers=("remnawave-subscription-page" "remnawave" "remnawave-db" "remnawave-redis" "remnanode" "caddy-remnawave" "caddy-selfsteal")
        for container in "${containers[@]}"; do
            if docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
                docker stop "$container" >/dev/null 2>&1 && docker rm "$container" >/dev/null 2>&1 &
                spinner $! "$(t spinner_force_removing) $container"
            fi
        done

        rm -rf "$REMNAWAVE_DIR" >/dev/null 2>&1 &
        spinner $! "$(t spinner_removing_directory) $REMNAWAVE_DIR"

        if [ "$from_menu" = true ]; then
            show_success "$(t removal_complete_success)"
            read
        else
            show_success "$(t removal_previous_success)"
        fi
    else
        if [ "$from_menu" = true ]; then
            echo
            show_info "$(t removal_no_installation)"
            echo -e "${BOLD_GREEN}$(t prompt_press_any_key)${NC}"
            read
        fi
    fi
}

restart_panel() {
    local no_wait=${1:-false} # Optional parameter to skip waiting for user input
    echo ''
    if [ ! -d /opt/remnawave ]; then
        show_error "$(t restart_panel_dir_not_found)"
        show_error "$(t restart_install_panel_first)"
    else
        if [ ! -f /opt/remnawave/docker-compose.yml ]; then
            show_error "$(t restart_compose_not_found)"
            show_error "$(t restart_installation_corrupted)"
        else
            SUBSCRIPTION_PAGE_EXISTS=false

            if [ -d /opt/remnawave/subscription-page ] && [ -f /opt/remnawave/subscription-page/docker-compose.yml ]; then
                SUBSCRIPTION_PAGE_EXISTS=true
            fi

            if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ]; then
                cd /opt/remnawave/subscription-page && docker compose down >/dev/null 2>&1 &
                spinner $! "$(t spinner_stopping_subscription)"
            fi

            cd /opt/remnawave && docker compose down >/dev/null 2>&1 &
            spinner $! "$(t spinner_restarting_panel)"

            show_info "$(t restart_starting_panel)" "$ORANGE"
            if ! start_container "/opt/remnawave" "Remnawave Panel"; then
                return 1
            fi

            if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ]; then
                show_info "$(t restart_starting_subscription)" "$ORANGE"
                if ! start_container "/opt/remnawave/subscription-page" "Subscription Page"; then
                    return 1
                fi
            fi

            show_success "$(t restart_success)"
        fi
    fi
    if [ "$no_wait" != "true" ]; then
        echo -e "${BOLD_GREEN}$(t prompt_enter_to_continue)${NC}"
        read
    fi
}

start_container() {
    local compose_dir="$1" display_name="$2"
    local max_wait=20 poll=1 tmp_log compose_file
    tmp_log=$(mktemp /tmp/docker-stack-XXXX.log)

    if [[ -z "$compose_dir" || -z "$display_name" ]]; then
        printf "${BOLD_RED}$(t container_error_provide_args)${NC}\n" >&2
        return 2
    fi
    if [[ ! -d "$compose_dir" ]]; then
        printf "${BOLD_RED}$(t container_error_directory_not_found)${NC}\n" "$compose_dir" >&2
        return 2
    fi
    if [[ -f "$compose_dir/docker-compose.yml" ]]; then
        compose_file="$compose_dir/docker-compose.yml"
    elif [[ -f "$compose_dir/docker-compose.yaml" ]]; then
        compose_file="$compose_dir/docker-compose.yaml"
    else
        printf "${BOLD_RED}$(t container_error_compose_not_found)${NC}\n" "$compose_dir" >&2
        return 2
    fi
    if ! command -v docker >/dev/null 2>&1; then
        printf "${BOLD_RED}$(t container_error_docker_not_installed)${NC}\n" >&2
        return 2
    fi
    if ! docker info >/dev/null 2>&1; then
        printf "${BOLD_RED}$(t container_error_docker_not_running)${NC}\n" >&2
        return 2
    fi

    (docker compose -f "$compose_file" up -d --force-recreate --remove-orphans) \
        >"$tmp_log" 2>&1 &
    spinner $! "$(t spinner_launching) $display_name"
    wait $!

    local output
    output=$(<"$tmp_log")

    if echo "$output" | grep -qiE 'toomanyrequests.*rate limit'; then
        printf "${BOLD_RED}$(t container_rate_limit_error)${NC}\n" "$display_name" >&2
        printf "${BOLD_YELLOW}$(t container_rate_limit_cause)${NC}\n" >&2
        echo -e "${ORANGE}$(t container_rate_limit_solutions)${NC}" >&2
        echo -e "${GREEN}$(t container_rate_limit_wait)${NC}" >&2
        echo -e "${GREEN}$(t container_rate_limit_login)${NC}" >&2
        echo -e "${GREEN}$(t container_rate_limit_vpn)${NC}" >&2
        echo -e "${GREEN}$(t container_rate_limit_mirror)${NC}\n" >&2
        rm -f "$tmp_log"
        return 1
    fi

    mapfile -t services < <(docker compose -f "$compose_file" config --services)

    local all_ok=true elapsed=0
    while [[ $elapsed -lt $max_wait ]]; do
        all_ok=true
        for svc in "${services[@]}"; do
            cid=$(docker compose -f "$compose_file" ps -q "$svc")
            state=$(docker inspect -f '{{.State.Status}}' "$cid" 2>/dev/null)
            if [[ "$state" != "running" ]]; then
                all_ok=false
                break
            fi
        done
        $all_ok && break
        sleep $poll
        ((elapsed += poll))
    done

    if $all_ok; then
        printf "${BOLD_GREEN}$(t container_success_up)${NC}\n" \
            "$display_name" "$(
                IFS=,
                echo "${services[*]}"
            )"
        echo
        rm -f "$tmp_log"
        return 0
    fi

    printf "${BOLD_RED}$(t container_failed_start)${NC}\n" "$display_name" >&2
    printf "${BOLD_RED}$(t container_compose_output)${NC}\n" >&2
    cat "$tmp_log" >&2
    printf "\n${BOLD_RED}$(t container_problematic_services)${NC}\n" >&2
    docker compose -f "$compose_file" ps >&2
    rm -f "$tmp_log"
    return 1
}

create_makefile() {
    local directory="$1"
    cat >"$directory/Makefile" <<'EOF'
.PHONY: start stop restart logs

start:
	docker compose up -d && docker compose logs -f -t
stop:
	docker compose down
restart:
	docker compose down && docker compose up -d
logs:
	docker compose logs -f -t
EOF
}

start_services() {
    echo
    show_info "$(t services_starting_containers)" "$BOLD_GREEN"

    if ! start_container "$REMNAWAVE_DIR" "Remnawave/backend"; then
        show_info "$(t services_installation_stopped)" "$BOLD_RED"
        exit 1
    fi

    if ! start_container "$REMNAWAVE_DIR/subscription-page" "Subscription page"; then
        show_info "$(t services_installation_stopped)" "$BOLD_RED"
        exit 1
    fi
}

# Including module: display.sh


clear_screen() {
    clear
}

draw_section_header() {
    local title="$1"
    local width=${2:-50}

    echo -e "${BOLD_RED}\033[1m┌$(printf '─%.0s' $(seq 1 $width))┐\033[0m${NC}"

    local padding_left=$(((width - ${#title}) / 2))
    local padding_right=$((width - padding_left - ${#title}))
    echo -e "${BOLD_RED}\033[1m│$(printf ' %.0s' $(seq 1 $padding_left))$title$(printf ' %.0s' $(seq 1 $padding_right))│\033[0m${NC}"

    echo -e "${BOLD_RED}\033[1m└$(printf '─%.0s' $(seq 1 $width))┘\033[0m${NC}"
    echo
}

draw_menu_options() {
    local options=("$@")
    local idx=1

    for option in "${options[@]}"; do
        echo -e "${ORANGE}$idx. $option${NC}"
        ((idx++))
    done
    echo
}

show_success() {
    local message="$1"
    local output_fd="${2:-1}" # Default to stdout (1)
    echo -e "${BOLD_GREEN}✓ ${message}${NC}" >&$output_fd
    echo >&$output_fd
}

show_error() {
    local message="$1"
    local output_fd="${2:-2}" # Default to stderr (2)
    echo -e "${BOLD_RED}✗ ${message}${NC}" >&$output_fd
    echo >&$output_fd
}

show_warning() {
    local message="$1"
    local output_fd="${2:-2}" # Default to stderr (2)
    echo -e "${BOLD_YELLOW}⚠  ${message}${NC}" >&$output_fd
    echo >&$output_fd
}

show_info() {
    local message="$1"
    local color="${2:-$ORANGE}"
    local output_fd="${3:-2}" # Default to stderr (2)
    echo -e "${color}${message}${NC}" >&$output_fd
    echo >&$output_fd
}

draw_separator() {
    local width=${1:-50}
    local char=${2:-"-"}

    printf "%s\n" "$(printf "$char%.0s" $(seq 1 $width))"
}

show_progress() {
    local message="$1"
    local progress_char=${2:-"."}
    local count=${3:-3}

    echo -ne "${message}"
    for ((i = 0; i < count; i++)); do
        echo -ne "${progress_char}"
        sleep 0.5
    done
    echo
}

draw_info_row() {
    local label="$1"
    local value="$2"
    local label_color="${3:-$ORANGE}"
    local value_color="${4:-$GREEN}"
    local width=${5:-50}

    local label_display="${label_color}${label}:${NC}"
    local value_display="${value_color}${value}${NC}"

    echo -e "${label_display} ${value_display}"
}

center_text() {
    local text="$1"
    local width=${2:-$(tput cols)}
    local padding_left=$(((width - ${#text}) / 2))

    printf "%${padding_left}s%s\n" "" "$text"
}

draw_completion_message() {
    local title="$1"
    local message="$2"
    local width=${3:-70}

    draw_separator "$width" "="
    center_text "$title" "$width"
    echo
    echo -e "$message"
    draw_separator "$width" "="
}

spinner() {
    local pid=$1
    local text=$2
    local spinstr='⣷⣯⣟⡿⢿⣻⣽⣾'
    local text_code="$BOLD_GREEN"
    local bg_code=""
    local effect_code="\033[1m"
    local delay=0.12
    local reset_code="$NC"

    printf "${effect_code}${text_code}${bg_code}%s${reset_code}" "$text" >/dev/tty

    while kill -0 "$pid" 2>/dev/null; do
        for ((i = 0; i < ${#spinstr}; i++)); do
            printf "\r${effect_code}${text_code}${bg_code}[%s] %s${reset_code}" "$(echo -n "${spinstr:$i:1}")" "$text" >/dev/tty
            sleep $delay
        done
    done

    printf "\r\033[K" >/dev/tty
}

# Including module: input.sh


prompt_input() {
    local prompt_text="$1"
    local prompt_color="${2:-$GREEN}"

    echo -ne "${prompt_color}${prompt_text}${NC}" >&2
    read input_value
    echo >&2

    echo "$input_value"
}

prompt_password() {
    local prompt_text="$1"
    local prompt_color="${2:-$ORANGE}"

    echo -ne "${prompt_color}${prompt_text}${NC}" >&2
    stty -echo
    read password_value
    stty echo
    echo >&2

    echo "$password_value"
}

prompt_yes_no() {
    local prompt_text="$1"
    local prompt_color="${2:-$GREEN}"
    local default="${3:-}"

    local prompt_suffix="$(t prompt_yes_no_suffix)"
    [ -n "$default" ] && prompt_suffix="$(t prompt_yes_no_default_suffix)$default]: "

    while true; do
        echo -ne "${prompt_color}${prompt_text}${prompt_suffix}${NC}" >&2

        while read -t 0.1; do read -n 1; done

        read answer
        echo >&2

        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

        [ -z "$answer" ] && answer="$default"

        if [ "$answer" = "y" ] || [ "$answer" = "yes" ]; then
            return 0
        elif [ "$answer" = "n" ] || [ "$answer" = "no" ]; then
            return 1
        else
            echo -e "${BOLD_RED}$(t error_enter_yn)${NC}" >&2
            echo ''
        fi
    done
}

prompt_menu_option() {
    local prompt_text="$1"
    local prompt_color="${2:-$GREEN}"
    local min="${3:-1}"
    local max="$4"

    local selected_option
    while true; do
        echo -ne "${prompt_color}${prompt_text} (${min}-${max}): ${NC}" >&2
        read selected_option
        echo >&2

        if [[ "$selected_option" =~ ^[0-9]+$ ]] &&
            [ "$selected_option" -ge "$min" ] &&
            [ "$selected_option" -le "$max" ]; then
            break
        else
            echo -e "${BOLD_RED}$(t error_enter_number_between) ${min} and ${max}.${NC}" >&2
        fi
    done

    echo "$selected_option"
}

validate_password_strength() {
    local password="$1"
    local min_length=${2:-8}

    local length=${#password}

    if [ "$length" -lt "$min_length" ]; then
        echo "$(t password_min_length) $min_length $(t password_min_length_suffix)"
        return 1
    fi

    if ! [[ "$password" =~ [0-9] ]]; then
        echo "$(t password_need_digit)"
        return 1
    fi

    if ! [[ "$password" =~ [a-z] ]]; then
        echo "$(t password_need_lowercase)"
        return 1
    fi

    if ! [[ "$password" =~ [A-Z] ]]; then
        echo "$(t password_need_uppercase)"
        return 1
    fi

    return 0
}

prompt_secure_password() {
    local prompt_text="$1"
    local confirm_text="${2:-$(t auth_confirm_password)}"
    local min_length=${3:-8}

    local password1 password2 error_message

    while true; do
        password1=$(prompt_password "$prompt_text")

        error_message=$(validate_password_strength "$password1" "$min_length")
        if [ $? -ne 0 ]; then
            echo -e "${BOLD_RED}${error_message} $(t password_try_again)${NC}" >&2
            continue
        fi

        password2=$(prompt_password "$confirm_text")

        if [ "$password1" = "$password2" ]; then
            break
        else
            echo -e "${BOLD_RED}$(t error_passwords_no_match)${NC}" >&2
        fi
    done

    echo "$password1"
}

# Including module: network.sh


validate_port() {
    local port="$1"

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo -e "${BOLD_RED}$(t network_error_port_number)${NC}" >&2
        return 1
    fi

    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${BOLD_RED}$(t network_error_port_range)${NC}" >&2
        return 1
    fi

    echo "$port"
}

is_port_available() {
    local port="$1"

    if ss -tuln | grep -q ":$port "; then
        return 1 # Port is in use
    else
        return 0 # Port is available
    fi
}

find_available_port() {
    local start_port="$1"
    local max_attempts=100
    local current_port="$start_port"

    for ((i = 0; i < max_attempts; i++)); do
        if is_port_available "$current_port"; then
            echo "$current_port"
            return 0
        fi
        ((current_port++))
    done

    return 1 # No available port found
}

is_ip_in_cidrs() {
    local ip="$1"
    shift
    local cidrs=("$@")

    function ip2dec() {
        local a b c d
        IFS=. read -r a b c d <<<"$1"
        echo $(((a << 24) + (b << 16) + (c << 8) + d))
    }

    function in_cidr() {
        local ip_dec mask base_ip cidr_ip cidr_mask
        ip_dec=$(ip2dec "$1")
        base_ip="${2%/*}"
        mask="${2#*/}"

        cidr_ip=$(ip2dec "$base_ip")
        cidr_mask=$((0xFFFFFFFF << (32 - mask) & 0xFFFFFFFF))

        if (((ip_dec & cidr_mask) == (cidr_ip & cidr_mask))); then
            return 0
        else
            return 1
        fi
    }

    for range in "${cidrs[@]}"; do
        if in_cidr "$ip" "$range"; then
            return 0
        fi
    done

    return 1
}

prompt_email() {
    local prompt="$1"
    local result=""

    while true; do
        prompt_formatted_text="${ORANGE}${prompt}: ${NC}"
        read -p "$prompt_formatted_text" result

        if [[ "$result" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo -e "${BOLD_RED}$(t network_invalid_email)${NC}" >&2
            if prompt_yes_no "$(t network_proceed_with_value) $result" "$ORANGE"; then
                break
            fi
        fi
    done

    echo >&2

    echo "$result"
}

get_available_port() {
    local default_port="$1"
    local port_name="$2" # For display purposes only

    local port=$(validate_port "$default_port")

    if is_port_available "$port"; then
        show_info "$(t network_using_default_port) $port_name port: $port"
        echo "$port"
        return 0
    else
        show_info "Default $port_name $(t network_port_in_use)"
        local available_port=$(find_available_port "$((port + 1))")

        if [ $? -eq 0 ]; then
            show_info "$(t network_using_port) $port_name port: $available_port"
            echo "$available_port"
            return 0
        else
            show_error "$(t network_failed_find_port) $port_name!"
            echo "$default_port"
            return 1
        fi
    fi
}

check_required_port() {
    local required_port="$1"

    local port=$(validate_port "$required_port")

    if is_port_available "$port"; then
        echo "$port"
        return 0
    else
        return 1
    fi
}

prompt_domain() {
    local prompt_text="$1"
    local prompt_color="${2:-$ORANGE}"
    local show_warning="${3:-true}"
    local allow_cf_proxy="${4:-true}"
    local expect_different_ip="${5:-false}" # For separate installation, domain should point to different server

    local domain
    while true; do
        echo -ne "${prompt_color}${prompt_text}: ${NC}" >&2
        read domain
        echo >&2

        if ! [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
            echo -e "${BOLD_RED}$(t network_invalid_domain)${NC}" >&2
            continue
        fi

        local domain_ip=""
        domain_ip=$(dig +short A "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)

        local server_ip=""
        server_ip=$(curl -s -4 ifconfig.me || curl -s -4 api.ipify.org || curl -s -4 ipinfo.io/ip)

        if [ -z "$domain_ip" ] || [ -z "$server_ip" ]; then
            if [ "$show_warning" = true ]; then
                show_warning "$(t network_failed_determine_ip)" 2
                show_warning "$(t network_make_sure_domain) $domain $(t network_points_to_server) ($server_ip)." 2
                if prompt_yes_no "$(t network_continue_despite_ip)" "$ORANGE"; then
                    break
                else
                    continue
                fi
            fi
        fi

        local cf_ranges
        cf_ranges=$(curl -s https://www.cloudflare.com/ips-v4) || true # if curl fails, variable remains empty

        local cf_array=()
        if [ -n "$cf_ranges" ]; then
            IFS=$'\n' read -r -d '' -a cf_array <<<"$cf_ranges"
        fi

        if [ ${#cf_array[@]} -gt 0 ] && is_ip_in_cidrs "$domain_ip" "${cf_array[@]}"; then
            if [ "$allow_cf_proxy" = true ]; then
                break
            else
                if [ "$show_warning" = true ]; then
                    echo
                    show_warning "$(t network_domain_points_cloudflare) $domain $(t network_points_cloudflare_ip) ($domain_ip)." 2
                    show_warning "$(t network_disable_cloudflare)" 2
                    if prompt_yes_no "$(t network_continue_despite_cloudflare)" "$ORANGE"; then
                        break
                    else
                        continue
                    fi
                fi
            fi
        else
            if [ "$expect_different_ip" = "true" ]; then
                if [ "$domain_ip" = "$server_ip" ]; then
                    if [ "$show_warning" = true ]; then
                        show_warning "$(t network_domain_points_server) $domain $(t network_points_this_server) ($server_ip)." 2
                        show_warning "$(t network_separate_installation_note)" 2
                        if prompt_yes_no "$(t network_continue_despite_current_server)" "$ORANGE"; then
                            break
                        else
                            continue
                        fi
                    fi
                else
                    if [ "$show_warning" = true ]; then
                        :
                    fi
                    break
                fi
            else
                if [ "$domain_ip" != "$server_ip" ]; then
                    if [ "$show_warning" = true ]; then
                        show_warning "$(t network_domain_points_different) $domain $(t network_points_different_ip) $domain_ip, $(t network_differs_from_server) ($server_ip)." 2
                        if prompt_yes_no "$(t network_continue_despite_mismatch)" "$ORANGE"; then
                            break
                        else
                            continue
                        fi
                    fi
                else
                    break
                fi
            fi
        fi
    done

    echo "$domain"
    echo
}

allow_ufw_node_port_from_panel() {
    local panel_subnet=172.30.0.0/16
    ufw allow from "$panel_subnet" to any port $NODE_PORT proto tcp
    ufw reload
}

# Including module: crypto.sh


generate_secure_password() {
    local length="${1:-16}"
    local password=""
    local special_chars='!%^&*_+.,'
    local uppercase_chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local lowercase_chars='abcdefghijklmnopqrstuvwxyz'
    local number_chars='0123456789'
    local alphanumeric_chars="${uppercase_chars}${lowercase_chars}${number_chars}"

    if command -v openssl &>/dev/null; then
        password="$(openssl rand -base64 48 | tr -dc "$alphanumeric_chars" | head -c "$length")"
    else
        password="$(head -c 100 /dev/urandom | tr -dc "$alphanumeric_chars" | head -c "$length")"
    fi

    if ! [[ "$password" =~ [$uppercase_chars] ]]; then
        local position=$((RANDOM % length))
        local one_uppercase="$(echo "$uppercase_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_uppercase}${password:$((position + 1))}"
    fi

    if ! [[ "$password" =~ [$lowercase_chars] ]]; then
        local position=$((RANDOM % length))
        local one_lowercase="$(echo "$lowercase_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_lowercase}${password:$((position + 1))}"
    fi

    if ! [[ "$password" =~ [$number_chars] ]]; then
        local position=$((RANDOM % length))
        local one_number="$(echo "$number_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_number}${password:$((position + 1))}"
    fi

    local special_count=$((length / 4))
    special_count=$((special_count > 0 ? special_count : 1))
    special_count=$((special_count < 3 ? special_count : 3))

    for ((i = 0; i < special_count; i++)); do
        local position=$((RANDOM % (length - 2) + 1))
        local one_special="$(echo "$special_chars" | fold -w1 | shuf | head -n1)"
        password="${password:0:$position}${one_special}${password:$((position + 1))}"
    done

    echo "$password"
}

generate_readable_login() {
    local length="${1:-8}"
    local consonants=('b' 'c' 'd' 'f' 'g' 'h' 'j' 'k' 'l' 'm' 'n' 'p' 'r' 's' 't' 'v' 'w' 'x' 'z')
    local vowels=('a' 'e' 'i' 'o' 'u' 'y')
    local login=""
    local type="consonant"

    while [ ${#login} -lt $length ]; do
        if [ "$type" = "consonant" ]; then
            login+=${consonants[$RANDOM % ${#consonants[@]}]}
            type="vowel"
        else
            login+=${vowels[$RANDOM % ${#vowels[@]}]}
            type="consonant"
        fi
    done

    local add_number=$((RANDOM % 2))
    if [ $add_number -eq 1 ]; then
        login+=$((RANDOM % 100))
    fi

    echo "$login"
}

generate_nonce() {
    local length="${1:-64}"
    local nonce=""
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    while [ ${#nonce} -lt $length ]; do
        nonce+="${chars:$((RANDOM % ${#chars})):1}"
    done

    echo "$nonce"
}

generate_custom_path() {
    local length="${1:-36}"
    local path=""
    local chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"

    while [ ${#path} -lt $length ]; do
        path+="${chars:$((RANDOM % ${#chars})):1}"
    done

    echo "$path"
}

generate_secrets() {
    JWT_AUTH_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    JWT_API_TOKENS_SECRET=$(openssl rand -hex 32 | tr -d '\n')
    DB_USER="remnawave_$(openssl rand -hex 4 | tr -d '\n')"
    DB_PASSWORD=$(generate_secure_password 16)
    DB_NAME="remnawave_db"
    METRICS_PASS=$(generate_secure_password 16)
    SUPERADMIN_USERNAME=$(generate_readable_login)
    SUPERADMIN_PASSWORD=$(generate_secure_password 28)
}

# Including module: http.sh


make_api_request() {
    local method=$1
    local url=$2
    local token=$3
    local panel_domain=$4
    local data=$5
    local cookie=${6:-""}

    local host_only=$(echo "${url#http://}" | cut -d'/' -f1)

    local headers=(
        -H "Content-Type: application/json"
        -H "Host: $panel_domain"
        -H "X-Forwarded-For: $host_only"
        -H "X-Forwarded-Proto: https"
        -H "X-Remnawave-Client-type: browser"
    )

    if [ -n "$token" ]; then
        headers+=(-H "Authorization: Bearer $token")
    fi

    if [ -n "$cookie" ]; then
        headers+=(-H "Cookie: $cookie")
    fi

    if [ "$method" = "GET" ]; then
        curl -s -X "$method" "$url" "${headers[@]}"
    else
        if [ -n "$data" ]; then
            curl -s -X "$method" "$url" "${headers[@]}" -d "$data"
        else
            curl -s -X "$method" "$url" "${headers[@]}"
        fi
    fi
}

# Including module: remnawave-api.sh


register_user() {
    local panel_url="$1"
    local panel_domain="$2"
    local username="$3"
    local password="$4"
    local api_url="http://${panel_url}/api/auth/register"

    local reg_token=""
    local reg_error=""
    local response=""
    local max_wait=180

    local temp_result=$(mktemp)

    {
        local start_time=$(date +%s)
        local end_time=$((start_time + max_wait))

        while [ $(date +%s) -lt $end_time ]; do
            response=$(make_api_request "POST" "$api_url" "" "$panel_domain" "{\"username\":\"$username\",\"password\":\"$password\"}")
            if [ -z "$response" ]; then
                reg_error="$(t api_empty_server_response)"
            elif [[ "$response" == *"accessToken"* ]]; then
                reg_token=$(echo "$response" | jq -r '.response.accessToken')
                echo "$reg_token" >"$temp_result"
                exit 0
            else
                reg_error="$response"
            fi
            sleep 1
        done
        echo "${reg_error:-$(t api_registration_failed)}" >"$temp_result"
        exit 1
    } &

    local pid=$!

    spinner "$pid" "$(t spinner_registering_user) $username..."

    wait $pid
    local status=$?

    local result=$(cat "$temp_result")
    rm -f "$temp_result"

    echo "$result"
    return $status
}

get_public_key() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"

    local temp_file=$(mktemp)

    make_api_request "GET" "http://$panel_url/api/keygen" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_public_key)"
    api_response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ -z "$api_response" ]; then
        echo -e "${BOLD_RED}$(t api_failed_get_public_key)${NC}"
        return 1
    fi

    local pubkey=$(echo "$api_response" | jq -r '.response.pubKey')
    if [ -z "$pubkey" ]; then
        echo -e "${BOLD_RED}$(t api_failed_extract_public_key)${NC}"
        return 1
    fi

    echo "$pubkey"
}

create_node() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local node_host="$4"
    local node_port="$5"
    local profile_uuid="$6"
    local inbound_uuid="$7"

    local node_name="VLESS"
    local temp_file=$(mktemp)

    local new_node_data=$(
        cat <<EOF
{
    "name": "$node_name",
    "address": "$node_host",
    "port": $node_port,
    "configProfile": {
        "activeConfigProfileUuid": "$profile_uuid",
        "activeInbounds": [
            "$inbound_uuid"
        ]
    },
    "isTrafficTrackingActive": false,
    "trafficLimitBytes": 0,
    "notifyPercent": 0,
    "trafficResetDay": 31,
    "excludedInbounds": [],
    "countryCode": "XX",
    "consumptionMultiplier": 1.0
}
EOF
    )

    make_api_request "POST" "http://$panel_url/api/nodes" "$token" "$panel_domain" "$new_node_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_creating_node)"
    node_response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ -z "$node_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_creating_node)${NC}"
        return 1
    fi

    if echo "$node_response" | jq -e '.response.uuid' >/dev/null; then
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_node)${NC}"
        echo
        echo "$(t api_request_body_was)"
        echo "$new_node_data"
        echo
        echo "$(t api_response):"
        echo
        echo "$node_response"
        return 1
    fi
}

get_config_profiles() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/config-profiles" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_config_profiles)"
    profiles_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$profiles_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_profiles)${NC}"
        return 1
    fi
    
    echo "$profiles_response"
}

delete_config_profile() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local profile_uuid="$4"
    
    local temp_file=$(mktemp)
    
    make_api_request "DELETE" "http://$panel_url/api/config-profiles/$profile_uuid" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_deleting_config_profile)"
    delete_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$delete_response" ] || echo "$delete_response" | jq -e '.response.isDeleted == true' >/dev/null 2>&1; then
        return 0
    fi
    
    if echo "$delete_response" | jq -e '.error' >/dev/null 2>&1; then
        echo -e "${BOLD_RED}$(t api_failed_delete_profile)${NC}"
        echo
        echo "$(t api_response):"
        echo "$delete_response"
        return 1
    fi
    
    return 0
}

create_config_profile() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local profile_name="$4"
    local xray_config="$5"
    
    local temp_file=$(mktemp)
    
    local profile_data=$(cat <<EOF
{
    "name": "$profile_name",
    "config": $xray_config
}
EOF
    )
    
    make_api_request "POST" "http://$panel_url/api/config-profiles" "$token" "$panel_domain" "$profile_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_creating_config_profile)"
    profile_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$profile_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_creating_profile)${NC}"
        return 1
    fi
    
    if echo "$profile_response" | jq -e '.response.uuid' >/dev/null; then
        local profile_uuid=$(echo "$profile_response" | jq -r '.response.uuid')
        local inbound_uuid=$(echo "$profile_response" | jq -r '.response.inbounds[0].uuid')
        echo "$profile_uuid:$inbound_uuid"
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_profile)${NC}"
        echo
        echo "$(t api_response):"
        echo "$profile_response"
        return 1
    fi
}

get_squads() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/internal-squads" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_squads)"
    squads_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$squads_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_squads)${NC}"
        return 1
    fi
    
    echo "$squads_response"
}

update_squad() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local squad_uuid="$4"
    local inbound_uuid="$5"
    
    local temp_file=$(mktemp)
    
    local squad_response=$(get_squads "$panel_url" "$token" "$panel_domain")
    if [ -z "$squad_response" ] || ! echo "$squad_response" | jq -e '.response.internalSquads' >/dev/null; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_squads)${NC}"
        return 1
    fi
    
    local existing_inbounds=$(echo "$squad_response" | jq -r --arg uuid "$squad_uuid" '.response.internalSquads[] | select(.uuid == $uuid) | .inbounds[].uuid')
    if [ -z "$existing_inbounds" ]; then
        existing_inbounds="[]"
    else
        existing_inbounds=$(echo "$existing_inbounds" | jq -R . | jq -s .)
    fi
    
    local inbounds_array=$(jq -n --argjson existing "$existing_inbounds" --arg new "$inbound_uuid" '$existing + [$new] | unique')
    
    local squad_data=$(jq -n --arg uuid "$squad_uuid" --argjson inbounds "$inbounds_array" '{
        uuid: $uuid,
        inbounds: $inbounds
    }')
    
    make_api_request "PATCH" "http://$panel_url/api/internal-squads" "$token" "$panel_domain" "$squad_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_updating_squad)"
    local update_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$update_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_updating_squad)${NC}"
        return 1
    fi
    
    if echo "$update_response" | jq -e '.response.uuid' >/dev/null; then
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_update_squad)${NC}"
        echo
        echo "$(t api_response):"
        echo "$update_response"
        return 1
    fi
}

get_inbounds() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"

    local temp_file=$(mktemp)

    make_api_request "GET" "http://$panel_url/api/inbounds" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_inbounds)"
    inbounds_response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ -z "$inbounds_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_inbounds)${NC}"
        return 1
    fi

    local inbound_uuid=$(echo "$inbounds_response" | jq -r '.response[0].uuid')
    if [ -z "$inbound_uuid" ]; then
        echo -e "${BOLD_RED}$(t api_failed_extract_uuid)${NC}"
        return 1
    fi

    echo "$inbound_uuid"
}

get_nodes() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/nodes" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_getting_nodes)"
    local response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_getting_nodes)${NC}"
        return 1
    fi
    
    echo "$response"
}

create_host() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local profile_uuid="$4"
    local inbound_uuid="$5"
    local self_steal_domain="$6"

    local temp_file=$(mktemp)

    local host_data=$(
        cat <<EOF
{
    "inbound": {
        "configProfileUuid": "$profile_uuid",
        "configProfileInboundUuid": "$inbound_uuid"
    },
    "remark": "VLESS",
    "address": "$self_steal_domain",
    "port": 443,
    "path": "",
    "sni": "$self_steal_domain",
    "host": "",
    "alpn": null,
    "fingerprint": "chrome",
    "allowInsecure": false,
    "isDisabled": false,
    "securityLayer": "DEFAULT"
}
EOF
    )

    make_api_request "POST" "http://$panel_url/api/hosts" "$token" "$panel_domain" "$host_data" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_creating_host)..."
    host_response=$(cat "$temp_file")
    rm -f "$temp_file"

    if [ -z "$host_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_creating_host)${NC}"
        return 1
    fi

    if echo "$host_response" | jq -e '.response.uuid' >/dev/null; then
        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_host)${NC}"
        return 1
    fi
}

create_user() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    local username="$4"
    local inbound_uuid="$5"
    local squad_uuid="$6"

    local temp_file=$(mktemp)
    local temp_headers=$(mktemp)

    local user_data=$(
        cat <<EOF
{
    "username": "$username",
    "status": "ACTIVE",
    "trafficLimitBytes": 0,
    "trafficLimitStrategy": "NO_RESET",
    "activeUserInbounds": [
        "$inbound_uuid"
    ],
    "activeInternalSquads": [
        "$squad_uuid"
    ],
    "expireAt": "2099-12-31T23:59:59.000Z",
    "description": "Default user created during installation",
    "hwidDeviceLimit": 0
}
EOF
    )

    {
        local host_only=$(echo "http://$panel_url/api/users" | sed 's|http://||' | cut -d'/' -f1)

        local headers=(
            -H "Content-Type: application/json"
            -H "Host: $panel_domain"
            -H "X-Forwarded-For: $host_only"
            -H "X-Forwarded-Proto: https"
            -H "X-Remnawave-Client-type: browser"
            -H "Authorization: Bearer $token"
        )

        curl -s -w "%{http_code}" -X "POST" "http://$panel_url/api/users" "${headers[@]}" -d "$user_data" -D "$temp_headers" >"$temp_file"
    } &

    spinner $! "$(t creating_user) $username..."

    local full_response=$(cat "$temp_file")
    local status_code="${full_response: -3}"   # Last 3 characters
    local user_response="${full_response%???}" # Everything except last 3 characters

    rm -f "$temp_file" "$temp_headers"

    if [ -z "$user_response" ]; then
        echo -e "${BOLD_RED}$(t api_empty_response_creating_user)${NC}"
        return 1
    fi

    if [ "$status_code" != "201" ]; then
        echo -e "${BOLD_RED}$(t api_failed_create_user_status) $status_code${NC}"
        echo
        echo "$(t api_request_body_was)"
        echo "$user_data"
        echo
        echo "$(t api_response):"
        echo "$user_response"
        return 1
    fi

    if echo "$user_response" | jq -e '.response.uuid' >/dev/null; then
        USER_UUID=$(echo "$user_response" | jq -r '.response.uuid')
        USER_SHORT_UUID=$(echo "$user_response" | jq -r '.response.shortUuid')
        USER_SUBSCRIPTION_UUID=$(echo "$user_response" | jq -r '.response.subscriptionUuid')
        USER_VLESS_UUID=$(echo "$user_response" | jq -r '.response.vlessUuid')
        USER_TROJAN_PASSWORD=$(echo "$user_response" | jq -r '.response.trojanPassword')
        USER_SS_PASSWORD=$(echo "$user_response" | jq -r '.response.ssPassword')
        USER_SUBSCRIPTION_URL=$(echo "$user_response" | jq -r '.response.subscriptionUrl')

        return 0
    else
        echo -e "${BOLD_RED}$(t api_failed_create_user_format)${NC}"
        echo
        echo "$(t api_request_body_was)"
        echo "$user_data"
        echo
        echo "$(t api_response):"
        echo "$user_response"
        return 1
    fi
}

generate_x25519_keys_api() {
    local panel_url="$1"
    local token="$2"
    local panel_domain="$3"
    
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/system/tools/x25519/generate" "$token" "$panel_domain" "" >"$temp_file" 2>&1 &
    spinner $! "$(t spinner_generating_keys)"
    local api_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$api_response" ]; then
        echo -e "${BOLD_RED}$(t api_failed_generate_keys)${NC}"
        return 1
    fi
    
    local private_key=$(echo "$api_response" | jq -r '.response.keypairs[0].privateKey')
    local public_key=$(echo "$api_response" | jq -r '.response.keypairs[0].publicKey')
    
    if [ -z "$private_key" ] || [ -z "$public_key" ] || [ "$private_key" = "null" ] || [ "$public_key" = "null" ]; then
        echo -e "${BOLD_RED}$(t api_failed_extract_keys)${NC}"
        return 1
    fi
    
    echo "$private_key:$public_key"
}

register_panel_user() {
    REG_TOKEN=$(register_user "127.0.0.1:3000" "$PANEL_DOMAIN" "$SUPERADMIN_USERNAME" "$SUPERADMIN_PASSWORD")

    if [ -z "$REG_TOKEN" ]; then
        show_error "$(t api_failed_register_user)"
        exit 1
    fi
}

# Including module: config.sh


update_file() {
    local env_file="$1"
    shift

    if [ "$#" -eq 0 ] || [ $(($# % 2)) -ne 0 ]; then
        echo "$(t config_invalid_arguments)" >&2
        return 1
    fi

    local keys=()
    local values=()

    while [ "$#" -gt 0 ]; do
        keys+=("$1")
        values+=("$2")
        shift 2
    done

    local temp_file=$(mktemp)

    while IFS= read -r line || [[ -n "$line" ]]; do
        local key_found=false
        for i in "${!keys[@]}"; do
            if [[ "$line" =~ ^${keys[$i]}= ]]; then
                echo "${keys[$i]}=${values[$i]}" >>"$temp_file"
                key_found=true
                break
            fi
        done

        if [ "$key_found" = false ]; then
            echo "$line" >>"$temp_file"
        fi
    done <"$env_file"

    mv "$temp_file" "$env_file"
}

collect_telegram_config() {
    if prompt_yes_no "$(t telegram_enable_notifications)"; then
        IS_TELEGRAM_NOTIFICATIONS_ENABLED=true
        TELEGRAM_BOT_TOKEN=$(prompt_input "$(t telegram_bot_token)" "$ORANGE")

        TELEGRAM_NOTIFY_NODES_CHAT_ID=$(prompt_input "$(t telegram_nodes_chat_id)" "$ORANGE")

        if prompt_yes_no "$(t telegram_enable_user_notifications)"; then
            TELEGRAM_NOTIFY_USERS_CHAT_ID=$(prompt_input "$(t telegram_users_chat_id)" "$ORANGE")
        else
            TELEGRAM_NOTIFY_USERS_CHAT_ID=""
        fi

        if prompt_yes_no "$(t telegram_enable_crm_notifications)"; then
            TELEGRAM_NOTIFY_CRM_CHAT_ID=$(prompt_input "$(t telegram_crm_chat_id)" "$ORANGE")
        else
            TELEGRAM_NOTIFY_CRM_CHAT_ID=""
        fi

        if prompt_yes_no "$(t telegram_use_topics)"; then
            if [ -n "$TELEGRAM_NOTIFY_USERS_CHAT_ID" ]; then
                TELEGRAM_NOTIFY_USERS_THREAD_ID=$(prompt_input "$(t telegram_users_thread_id)" "$ORANGE")
            else
                TELEGRAM_NOTIFY_USERS_THREAD_ID=""
            fi
            if [ -n "$TELEGRAM_NOTIFY_CRM_CHAT_ID" ]; then
                TELEGRAM_NOTIFY_CRM_THREAD_ID=$(prompt_input "$(t telegram_crm_thread_id)" "$ORANGE")
            else
                TELEGRAM_NOTIFY_CRM_THREAD_ID=""
            fi
            TELEGRAM_NOTIFY_NODES_THREAD_ID=$(prompt_input "$(t telegram_nodes_thread_id)" "$ORANGE")
        else
            TELEGRAM_NOTIFY_USERS_THREAD_ID=""
            TELEGRAM_NOTIFY_CRM_THREAD_ID=""
            TELEGRAM_NOTIFY_NODES_THREAD_ID=""
        fi
    else
        show_warning "$(t warning_skipping_telegram)"
        IS_TELEGRAM_NOTIFICATIONS_ENABLED=false
        TELEGRAM_BOT_TOKEN="change-me"
        TELEGRAM_NOTIFY_USERS_CHAT_ID="change-me"
        TELEGRAM_NOTIFY_NODES_CHAT_ID="change-me"
        TELEGRAM_NOTIFY_CRM_CHAT_ID="change-me"
        TELEGRAM_NOTIFY_USERS_THREAD_ID=""
        TELEGRAM_NOTIFY_NODES_THREAD_ID=""
        TELEGRAM_NOTIFY_CRM_THREAD_ID=""
    fi
}

check_domain_uniqueness() {
    local new_domain="$1"
    local domain_type="$2"
    local existing_domains=("${@:3}")

    for existing_domain in "${existing_domains[@]}"; do
        if [ -n "$existing_domain" ] && [ "$new_domain" = "$existing_domain" ]; then
            show_error "$(t config_domain_already_used) '$new_domain'"
            show_error "$(t config_domains_must_be_unique)"
            return 1
        fi
    done
    return 0
}

collect_domain_config() {
    PANEL_DOMAIN=$(prompt_domain "$(t domain_panel_prompt)")

    while true; do
        SUB_DOMAIN=$(prompt_domain "$(t domain_subscription_prompt)")

        if check_domain_uniqueness "$SUB_DOMAIN" "subscription" "$PANEL_DOMAIN"; then
            break
        fi
        show_warning "$(t warning_enter_different_domain) subscription."
    done
}

collect_ports_all_in_one() {
    CADDY_LOCAL_PORT=$(get_available_port "9443" "Caddy")
    NODE_PORT=$(get_available_port "2222" "Node API")
}

collect_ports_separate_installation() {

    if CADDY_LOCAL_PORT=$(check_required_port "9443"); then
        show_info "$(t config_caddy_port_available)"
    else
        show_error "$(t config_caddy_port_in_use)"
        show_error "$(t config_separate_installation_port_required) 9443."
        show_error "$(t config_free_port_and_retry) 9443."
        show_error "$(t config_installation_cannot_continue) 9443"
        return 1
    fi

    if NODE_PORT=$(check_required_port "2222"); then
        show_info "$(t config_node_port_available)"
    else
        show_error "$(t config_node_port_in_use)"
        show_error "$(t config_separate_installation_port_required) 2222."
        show_error "$(t config_free_port_and_retry) 2222."
        show_error "$(t config_installation_cannot_continue) 2222"
        return 1
    fi
}

setup_panel_environment() {
    local env_branch="$REMNAWAVE_BRANCH"
    if [ "$REMNAWAVE_BRANCH" = "alpha" ]; then
        env_branch="dev"
    elif [[ "$REMNAWAVE_BRANCH" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        env_branch="main"
    fi
    curl -s -o .env "$REMNAWAVE_BACKEND_REPO/$env_branch/.env.sample"

    update_file ".env" \
        "JWT_AUTH_SECRET" "$JWT_AUTH_SECRET" \
        "JWT_API_TOKENS_SECRET" "$JWT_API_TOKENS_SECRET" \
        "IS_TELEGRAM_NOTIFICATIONS_ENABLED" "$IS_TELEGRAM_NOTIFICATIONS_ENABLED" \
        "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN" \
        "TELEGRAM_NOTIFY_USERS_CHAT_ID" "$TELEGRAM_NOTIFY_USERS_CHAT_ID" \
        "TELEGRAM_NOTIFY_NODES_CHAT_ID" "$TELEGRAM_NOTIFY_NODES_CHAT_ID" \
        "TELEGRAM_NOTIFY_CRM_CHAT_ID" "$TELEGRAM_NOTIFY_CRM_CHAT_ID" \
        "TELEGRAM_NOTIFY_USERS_THREAD_ID" "$TELEGRAM_NOTIFY_USERS_THREAD_ID" \
        "TELEGRAM_NOTIFY_NODES_THREAD_ID" "$TELEGRAM_NOTIFY_NODES_THREAD_ID" \
        "TELEGRAM_NOTIFY_CRM_THREAD_ID" "$TELEGRAM_NOTIFY_CRM_THREAD_ID" \
        "SUB_PUBLIC_DOMAIN" "$SUB_DOMAIN" \
        "DATABASE_URL" "postgresql://$DB_USER:$DB_PASSWORD@remnawave-db:5432/$DB_NAME" \
        "POSTGRES_USER" "$DB_USER" \
        "POSTGRES_PASSWORD" "$DB_PASSWORD" \
        "POSTGRES_DB" "$DB_NAME" \
        "METRICS_PASS" "$METRICS_PASS"
}

setup_panel_docker_compose() {
    cat >>docker-compose.yml <<"EOF"
services:
  remnawave-db:
    image: postgres:17.6
    container_name: 'remnawave-db'
    hostname: remnawave-db
    restart: always
    env_file:
      - .env
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - TZ=UTC
    ports:
      - '127.0.0.1:6767:5432'
    volumes:
      - remnawave-db-data:/var/lib/postgresql/data
    networks:
      - remnawave-network
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}']
      interval: 3s
      timeout: 10s
      retries: 3

  remnawave:
    image: remnawave/backend:REMNAWAVE_BACKEND_TAG_PLACEHOLDER
    container_name: 'remnawave'
    hostname: remnawave
    restart: always
    ports:
      - '127.0.0.1:3000:3000'
    env_file:
      - .env
    networks:
      - remnawave-network
    depends_on:
      remnawave-db:
        condition: service_healthy
      remnawave-redis:
        condition: service_healthy
    healthcheck:
      test: ['CMD-SHELL', 'curl -f http://localhost:$${METRICS_PORT}/health || exit 1']
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  remnawave-redis:
    image: valkey/valkey:8.1-alpine
    container_name: remnawave-redis
    hostname: remnawave-redis
    restart: always
    networks:
      - remnawave-network
    volumes:
      - remnawave-redis-data:/data
    healthcheck:
      test: [ "CMD", "valkey-cli", "ping" ]
      interval: 3s
      timeout: 10s
      retries: 3

networks:
  remnawave-network:
    name: remnawave-network
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.0.0/16
    external: false

volumes:
  remnawave-db-data:
    driver: local
    external: false
    name: remnawave-db-data
  remnawave-redis-data:
    driver: local
    external: false
    name: remnawave-redis-data
EOF

    sed -i "s/REMNAWAVE_BACKEND_TAG_PLACEHOLDER/$REMNAWAVE_BACKEND_TAG/g" docker-compose.yml
}

# Including module: validation.sh


validate_ip() {
    local input="$1"

    input=$(echo "$input" | tr -d ' ')

    if [ -z "$input" ]; then
        return 1
    fi

    if [[ $input =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<<"$input"
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ]; then
                return 1
            fi
        done
        echo "$input"
        return 0
    fi

    return 1
}

validate_domain_name() {
    local input="$1"
    local max_length="${2:-253}" # Maximum domain length by standard

    input=$(echo "$input" | tr -d ' ')

    if [ -z "$input" ]; then
        return 1
    fi

    if [ ${#input} -gt $max_length ]; then
        return 1
    fi

    if [[ $input =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)+$ ]] &&
        [[ ! $input =~ \.\. ]]; then
        echo "$input"
        return 0
    fi

    return 1
}

validate_domain() {
    local input="$1"
    local max_length="${2:-253}"

    local result=$(validate_ip "$input")
    if [ $? -eq 0 ]; then
        echo "$result"
        return 0
    fi

    result=$(validate_domain_name "$input" "$max_length")
    if [ $? -eq 0 ]; then
        echo "$result"
        return 0
    fi

    return 1
}

prompt_number() {
    local prompt_text="$1"
    local prompt_color="${2:-$ORANGE}"
    local min="${3:-1}"
    local max="${4:-}"

    local number
    while true; do
        echo -ne "${prompt_color}${prompt_text}: ${NC}" >&2
        read number
        echo >&2

        if [[ "$number" =~ ^[0-9]+$ ]]; then
            if [ -n "$min" ] && [ "$number" -lt "$min" ]; then
                echo -e "${BOLD_RED}$(t validation_value_min) ${min}.${NC}" >&2
                continue
            fi

            if [ -n "$max" ] && [ "$number" -gt "$max" ]; then
                echo -e "${BOLD_RED}$(t validation_value_max) ${max}.${NC}" >&2
                continue
            fi

            break
        else
            echo -e "${BOLD_RED}$(t validation_enter_numeric)${NC}" >&2
        fi
    done

    echo "$number"
}

validate_ssl_certificate() {
    local certificate="$1"

    if [ -z "$certificate" ]; then
        return 1
    fi

    if [[ ! "$certificate" =~ ^SSL_CERT= ]]; then
        return 1
    fi

    local cert_value="${certificate#SSL_CERT=}"

    cert_value="${cert_value#\"}"
    cert_value="${cert_value%\"}"

    if [ -z "$cert_value" ]; then
        return 1
    fi

    if ! echo "$cert_value" | base64 -d >/dev/null 2>&1; then
        return 1
    fi

    local decoded_json
    if ! decoded_json=$(echo "$cert_value" | base64 -d 2>/dev/null); then
        return 1
    fi

    if ! echo "$decoded_json" | jq -e '.nodeCertPem and .nodeKeyPem and .caCertPem and .jwtPublicKey' >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

simple_read_domain_or_ip() {
    local prompt="$1"
    local default_value="$2"
    local validation_type="${3:-both}" # Can be 'domain_only', 'ip_only', or 'both'
    local result=""
    local attempts=0
    local max_attempts=10
    while [ $attempts -lt $max_attempts ]; do
        if [ -n "$default_value" ]; then
            echo -ne "${ORANGE}${prompt} [$default_value]: ${NC}" >&2
        else
            echo -ne "${ORANGE}${prompt}: ${NC}" >&2
        fi
        read input
        echo >&2

        if [ -z "$input" ] && [ -n "$default_value" ]; then
            result="$default_value"
            break
        fi
        if [ -z "$input" ]; then
            echo -e "${BOLD_RED}$(t validation_input_empty)${NC}" >&2
            ((attempts++))
            continue
        fi
        if [ "$validation_type" = "ip_only" ]; then
            result=$(validate_ip "$input")
            local status=$?
            if [ $status -eq 0 ]; then
                break
            else
                echo -e "${BOLD_RED}$(t validation_invalid_ip)${NC}" >&2
            fi
        elif [ "$validation_type" = "domain_only" ]; then
            result=$(validate_domain_name "$input")
            local status=$?
            if [ $status -eq 0 ]; then
                break
            else
                echo -e "${BOLD_RED}$(t validation_invalid_domain)${NC}" >&2
                echo -e "${BOLD_RED}$(t validation_use_only_letters)${NC}" >&2
            fi
        else
            result=$(validate_domain "$input")
            local status=$?
            if [ $status -eq 0 ]; then
                break
            else
                echo -e "${BOLD_RED}$(t validation_invalid_domain_ip)${NC}" >&2
                echo -e "${BOLD_RED}$(t validation_domain_format)${NC}" >&2
                echo -e "${BOLD_RED}$(t validation_ip_format)${NC}" >&2
            fi
        fi
        ((attempts++))
    done
    if [ $attempts -eq $max_attempts ]; then
        if [ -n "$default_value" ]; then
            echo -e "${BOLD_RED}$(t validation_max_attempts_default) $default_value${NC}" >&2
            result="$default_value"
        else
            echo -e "${BOLD_RED}$(t validation_max_attempts_no_input)${NC}" >&2
            echo -e "${BOLD_RED}$(t validation_cannot_continue)${NC}" >&2
            return 1
        fi
    fi
    echo "$result"
}

# Including module: misc.sh


generate_qr_code() {
    local url="$1"
    local title="${2:-QR Code}"

    if [ -z "$url" ]; then
        return 1
    fi

    if command -v qrencode &>/dev/null; then
        echo -e "\033[1m$title:\033[0m"
        echo

        local qr_output=$(qrencode -t ANSIUTF8 "$url" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$qr_output" ]; then
            echo "$qr_output" | while IFS= read -r line; do
                printf "    %s\n" "$line"
            done
        else
            echo "$(t misc_qr_generation_failed)"
        fi
        echo
    else
        :
    fi
}

# Including module: vless.sh


generate_vless_keys() {
  local panel_url="$1"
  local token="$2"
  local panel_domain="$3"
  
  if [ -n "$panel_url" ] && [ -n "$token" ] && [ -n "$panel_domain" ]; then
    local api_keys=$(generate_x25519_keys_api "$panel_url" "$token" "$panel_domain")
    if [ $? -eq 0 ] && [ -n "$api_keys" ]; then
      echo "$api_keys"
      return 0
    fi
  fi
  
  local temp_file=$(mktemp)

  docker run --rm ghcr.io/xtls/xray-core x25519 >"$temp_file" 2>&1 &
  spinner $! "$(t spinner_generating_keys)"
  keys=$(cat "$temp_file")

  local private_key=$(echo "$keys" | grep "PrivateKey:" | awk '{print $2}')
  local public_key=$(echo "$keys" | grep "Password:" | awk '{print $2}')
  rm -f "$temp_file"

  if [ -z "$private_key" ] || [ -z "$public_key" ]; then
    echo -e "${BOLD_RED}$(t vless_failed_generate_keys)${NC}"
    return 1
  fi

  echo "$private_key:$public_key"
}

generate_xray_config() {
  local config_file="$1"
  local self_steal_domain="$2"
  local CADDY_LOCAL_PORT="$3"
  local private_key="$4"

  local short_id=$(openssl rand -hex 8)

  cat >"$config_file" <<EOL
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      {
        "address": "https://dns.google/dns-query",
        "skipFallback": false
      }
    ],
    "queryStrategy": "UseIPv4"
  },
  "inbounds": [
    {
      "tag": "VLESS",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "127.0.0.1:$CADDY_LOCAL_PORT",
          "show": false,
          "xver": 1,
          "shortIds": [
            "$short_id"
          ],
          "privateKey": "$private_key",
          "serverNames": [
            "$self_steal_domain"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "DIRECT",
      "protocol": "freedom"
    },
    {
      "tag": "BLOCK",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "rules": [
      {
        "ip": [
          "geoip:private"
        ],
        "type": "field",
        "outboundTag": "BLOCK"
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "BLOCK"
      }
    ]
  }
}
EOL
}

update_xray_config() {
  local panel_url="$1"
  local token="$2"
  local panel_domain="$3"
  local config_file="$4"

  local temp_file=$(mktemp)
  local new_config=$(cat "$config_file")

  make_api_request "PUT" "http://$panel_url/api/xray" "$token" "$panel_domain" "$new_config" >"$temp_file" 2>&1 &
  spinner $! "$(t spinner_updating_xray)"
  local update_response=$(cat "$temp_file")
  rm -f "$temp_file"

  if [ -z "$update_response" ]; then
    echo -e "${BOLD_RED}$(t vless_empty_response_xray)${NC}"
    return 1
  fi

  if echo "$update_response" | jq -e '.response.config' >/dev/null; then
    return 0
  else
    echo -e "${BOLD_RED}$(t vless_failed_update_xray)${NC}"
    return 1
  fi
}

# Including module: generate-selfsteal.sh

JUNK_CSS_RULE_COUNT=300
JUNK_HTML_MAX_DEPTH=6
JUNK_HTML_MAX_CHILDREN=4

command -v shuf >/dev/null || {
    echo "Error: 'shuf' not found. Please install 'coreutils'." >&2
    exit 1
}

generate_realistic_identifier() {
    local style=$((RANDOM % 4))
    local words=("app" "ui" "form" "input" "btn" "wrap" "grid" "item" "box" "nav" "main" "user" "data" "auth" "login" "pass" "field" "group" "widget" "view" "icon" "control" "container" "wrapper" "avatar" "link")
    case $style in
    0)
        local prefixes=("ui" "app" "js" "mod" "el")
        local p1=${prefixes[$RANDOM % ${#prefixes[@]}]}
        local w1=${words[$RANDOM % ${#words[@]}]}
        local w2=${words[$RANDOM % ${#words[@]}]}
        echo "${p1}-${w1}-${w2}"
        ;;
    1)
        local w1=${words[$RANDOM % ${#words[@]}]}
        local w2=${words[$RANDOM % ${#words[@]}]}
        local w3=${words[$RANDOM % ${#words[@]}]}
        echo "${w1}${w2^}${w3^}"
        ;;
    2)
        local len=$((RANDOM % 12 + 8))
        cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c $len
        ;;
    *)
        local w1=${words[$RANDOM % ${#words[@]}]}
        local hash=$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 6)
        echo "${w1}-${hash}"
        ;;
    esac
}
generate_random_var_name() {
    local len=$((RANDOM % 10 + 6))
    echo "--$(cat /dev/urandom | tr -dc 'a-z' | head -c $len)"
}
url_encode_svg() { echo "$1" | sed 's/"/\x27/g' | sed 's/</%3C/g' | sed 's/>/%3E/g' | sed 's/#/%23/g' | sed 's/{/%7B/g' | sed 's/}/%7D/g'; }

generate_junk_html_nodes() {
    local current_depth=$1
    if ((current_depth >= JUNK_HTML_MAX_DEPTH)); then return; fi
    local tags=("div" "p" "span")
    local num_children=$((RANDOM % JUNK_HTML_MAX_CHILDREN + 1))
    for ((i = 0; i < num_children; i++)); do
        local tag=${tags[$RANDOM % ${#tags[@]}]}
        local class=$(generate_realistic_identifier)
        echo "<${tag} class=\"${class}\">$(generate_junk_html_nodes $((current_depth + 1)))</${tag}>"
    done
}
generate_junk_css() {
    local count=$1
    local rules=()
    local colors=("#f44336" "#e91e63" "#9c27b0" "#673ab7" "#3f51b5")
    local units=("px" "rem" "em" "%")
    for ((i = 0; i < count; i++)); do
        local junk_class=$(generate_realistic_identifier)
        local prop1="color: ${colors[$RANDOM % ${#colors[@]}]};"
        local prop2="font-size: $((RANDOM % 14 + 10))px;"
        local prop3="margin: $((RANDOM % 20))${units[$RANDOM % ${#units[@]}]};"
        local prop4="opacity: 0.$((RANDOM % 9 + 1));"
        local props_array=("$prop1" "$prop2" "$prop3" "$prop4")
        local shuffled_props=$(printf "%s\n" "${props_array[@]}" | shuf | tr '\n' ' ')
        rules+=(".${junk_class} { ${shuffled_props} }")
    done
    printf "%s\n" "${rules[@]}"
}

setup_random_theme() {
    local palettes=(
        "#5e72e4;#324cdd;#f6f9fc;#ffffff;#32325d;#8898aa;#dee2e6"
        "#2dce89;#24a46d;#f6f9fc;#ffffff;#32325d;#8898aa;#dee2e6"
        "#11cdef;#0b8ba3;#f6f9fc;#ffffff;#32325d;#8898aa;#dee2e6"
        "#fb6340;#fa3a0e;#f6f9fc;#ffffff;#32325d;#8898aa;#dee2e6"
        "#6772e5;#5469d4;#f6f9fc;#ffffff;#32325d;#8898aa;#dee2e6"
    )
    local font_stacks=(
        "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif"
        "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif"
        "'Source Sans Pro', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif"
    )

    local selected_palette=${palettes[$RANDOM % ${#palettes[@]}]}
    IFS=';' read -r VAR_PRIMARY_COLOR VAR_HOVER_COLOR VAR_BG_COLOR VAR_CARD_COLOR VAR_TEXT_COLOR VAR_TEXT_LIGHT_COLOR VAR_BORDER_COLOR <<<"$selected_palette"
    VAR_FONT_SANS_SERIF=${font_stacks[$RANDOM % ${#font_stacks[@]}]}

    CSS_VAR_PRIMARY=$(generate_random_var_name)
    CSS_VAR_HOVER=$(generate_random_var_name)
    CSS_VAR_BG=$(generate_random_var_name)
    CSS_VAR_CARD_BG=$(generate_random_var_name)
    CSS_VAR_TEXT=$(generate_random_var_name)
    CSS_VAR_TEXT_LIGHT=$(generate_random_var_name)
    CSS_VAR_BORDER=$(generate_random_var_name)
    CSS_VAR_FONT=$(generate_random_var_name)
}

generate_selfsteal_form() {
    setup_random_theme

    local html_filename="index.html"
    local css_filename="$(generate_realistic_identifier).css"
    local class_container=$(generate_realistic_identifier)
    local class_form_wrapper=$(generate_realistic_identifier)
    local class_title=$(generate_realistic_identifier)
    local class_input_email=$(generate_realistic_identifier)
    local class_input_pass=$(generate_realistic_identifier)
    local class_button=$(generate_realistic_identifier)
    local class_junk_wrapper=$(generate_realistic_identifier)
    local name_user=$(generate_realistic_identifier)
    local name_pass=$(generate_realistic_identifier)
    local action_url="/gateway/$(generate_realistic_identifier)/auth"
    local class_extra_links=$(generate_realistic_identifier)
    local class_forgot_link=$(generate_realistic_identifier)

    local svg_email_icon_raw='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="'${VAR_TEXT_LIGHT_COLOR}'"><path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg>'
    local svg_lock_icon_raw='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="'${VAR_TEXT_LIGHT_COLOR}'"><path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/></svg>'
    local encoded_email_icon=$(url_encode_svg "$svg_email_icon_raw")
    local encoded_lock_icon=$(url_encode_svg "$svg_lock_icon_raw")

    local main_content_html="<div class=\"${class_container}\"><div class=\"${class_form_wrapper}\"><h2 class=\"${class_title}\">Login</h2><form action=\"${action_url}\" method=\"post\"><input type=\"email\" name=\"${name_user}\" class=\"${class_input_email}\" placeholder=\"Email\" required><input type=\"password\" name=\"${name_pass}\" class=\"${class_input_pass}\" placeholder=\"Password\" required><div class=\"${class_extra_links}\"><a href=\"#\" class=\"${class_forgot_link}\">Forgot Password?</a></div><button type=\"submit\" class=\"${class_button}\">Login</button></form></div></div>"
    local junk_html_block="<div class=\"${class_junk_wrapper}\">$(generate_junk_html_nodes 0)</div>"

    local core_css="
:root { ${CSS_VAR_PRIMARY}: ${VAR_PRIMARY_COLOR}; ${CSS_VAR_HOVER}: ${VAR_HOVER_COLOR}; ${CSS_VAR_BG}: ${VAR_BG_COLOR}; ${CSS_VAR_CARD_BG}: ${VAR_CARD_COLOR}; ${CSS_VAR_TEXT}: ${VAR_TEXT_COLOR}; ${CSS_VAR_TEXT_LIGHT}: ${VAR_TEXT_LIGHT_COLOR}; ${CSS_VAR_BORDER}: ${VAR_BORDER_COLOR}; ${CSS_VAR_FONT}: ${VAR_FONT_SANS_SERIF}; }
html { font-family: var(${CSS_VAR_FONT}); font-size: 16px; }
body { margin: 0; background-color: var(${CSS_VAR_BG}); display: flex; align-items: center; justify-content: center; min-height: 100vh; }
"
    local component_pool=()
    component_pool+=(".${class_container} { width: 100%; max-width: 450px; padding: 1rem; }")
    component_pool+=(".${class_form_wrapper} { background-color: var(${CSS_VAR_CARD_BG}); padding: 3rem; border-radius: 12px; box-shadow: 0 7px 30px rgba(50, 50, 93, 0.1), 0 3px 8px rgba(0, 0, 0, 0.07); text-align: center; }")
    component_pool+=(".${class_title} { font-size: 1.5rem; font-weight: 600; color: var(${CSS_VAR_TEXT_LIGHT}); margin: 0 0 2.5rem 0; text-transform: uppercase; letter-spacing: 1px; }")
    component_pool+=(".${class_input_email}, .${class_input_pass} { width: 100%; box-sizing: border-box; font-size: 1rem; padding: 0.9rem 1rem 0.9rem 3.2rem; margin-bottom: 1.25rem; border: 1px solid var(${CSS_VAR_BORDER}); border-radius: 8px; background-repeat: no-repeat; background-position: left 1.2rem center; background-size: 20px; transition: all 0.15s ease; }")
    component_pool+=(".${class_input_email}:focus, .${class_input_pass}:focus { outline: none; border-color: var(${CSS_VAR_PRIMARY}); box-shadow: 0 0 0 3px color-mix(in srgb, var(${CSS_VAR_PRIMARY}) 20%, transparent); }")
    component_pool+=(".${class_input_email} { background-image: url('data:image/svg+xml,${encoded_email_icon}'); }")
    component_pool+=(".${class_input_pass} { background-image: url('data:image/svg+xml,${encoded_lock_icon}'); }")
    component_pool+=(".${class_extra_links} { text-align: right; margin-bottom: 1.5rem; }")
    component_pool+=(".${class_forgot_link} { color: var(${CSS_VAR_PRIMARY}); text-decoration: none; font-size: 0.9rem; }")
    component_pool+=(".${class_forgot_link}:hover { text-decoration: underline; }")
    component_pool+=(".${class_button} { width: 100%; box-sizing: border-box; padding: 1rem; font-size: 1rem; font-weight: 600; color: #fff; background-image: linear-gradient(35deg, var(${CSS_VAR_PRIMARY}), var(${CSS_VAR_HOVER})); border: none; border-radius: 8px; cursor: pointer; transition: transform 0.2s, box-shadow 0.2s; box-shadow: 0 4px 15px color-mix(in srgb, var(${CSS_VAR_PRIMARY}) 40%, transparent); }")
    component_pool+=(".${class_button}:hover { transform: translateY(-2px); box-shadow: 0 7px 25px color-mix(in srgb, var(${CSS_VAR_PRIMARY}) 50%, transparent); }")
    component_pool+=(".${class_junk_wrapper} { display: none !important; }")

    local junk_css_rules=$(generate_junk_css $JUNK_CSS_RULE_COUNT)

    echo "${core_css}" >"${css_filename}"
    printf "%s\n%s" "$(printf "%s\n" "${component_pool[@]}")" "$junk_css_rules" | shuf >>"${css_filename}"

    cat <<EOF >"$html_filename"
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Login</title><link rel="stylesheet" href="${css_filename}"></head><body>$(if ((RANDOM % 2 == 0)); then echo "$main_content_html $junk_html_block"; else echo "$junk_html_block $main_content_html"; fi)</body></html>
EOF
}

# Including module: run-cli.sh

run_remnawave_cli() {
    echo

    if ! docker ps --format '{{.Names}}' | grep -q '^remnawave$'; then
        show_error "$(t cli_container_not_running)"
        echo -e "${YELLOW}$(t cli_ensure_panel_running)${NC}"
        echo
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    exec 3>&1 4>&2
    exec >/dev/tty 2>&1

    if docker exec -it -e TERM=xterm-256color remnawave remnawave; then
        echo
        show_success "$(t cli_session_completed)"
    else
        echo
        show_error "$(t cli_session_failed)"
        exec 1>&3 2>&4
        echo
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    exec 1>&3 2>&4

    echo
    echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
    read -r
}

# Including module: enable-bbr.sh

is_bbr_enabled() {
  local cc qd
  if grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf 2>/dev/null &&
    grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf 2>/dev/null; then
    cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    qd=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    [[ $cc == "bbr" && $qd == "fq" ]] && return 0
  fi
  return 1
}

get_bbr_menu_text() {
  if is_bbr_enabled; then
    echo "$(t bbr_disable)"
  else
    echo "$(t bbr_enable)"
  fi
}

apply_qdisc_now() {
  local dev
  if ! command -v tc >/dev/null 2>&1; then
    return 0
  fi
  
  dev=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')
  [[ -n $dev ]] && tc qdisc replace dev "$dev" root fq 2>/dev/null || true
}

load_bbr_module() {
  if ! command -v modprobe >/dev/null 2>&1; then
    return 0
  fi
  
  if lsmod 2>/dev/null | grep -q tcp_bbr; then
    return 0
  fi
  
  modprobe tcp_bbr 2>/dev/null || true
}

enable_bbr() {
  echo -e "\n${BOLD_GREEN}$(t bbr_enable)${NC}\n"

  load_bbr_module

  sed -i -E \
    -e '/^\s*net\.core\.default_qdisc\s*=/d' \
    -e '/^\s*net\.ipv4\.tcp_congestion_control\s*=/d' \
    /etc/sysctl.conf 2>/dev/null || true

  {
    echo "net.core.default_qdisc=fq"
    echo "net.ipv4.tcp_congestion_control=bbr"
  } >>/etc/sysctl.conf

  sysctl -p >/dev/null 2>&1

  apply_qdisc_now

  show_success "$(t success_bbr_enabled)"
  echo -e "\n${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
  read -r
}

disable_bbr() {
  echo -e "\n${BOLD_GREEN}$(t bbr_disable)${NC}\n"

  if grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf 2>/dev/null ||
    grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf 2>/dev/null; then
    show_info "$(t info_removing_bbr_config)"

    sed -i '/net.core.default_qdisc=fq/d' /etc/sysctl.conf 2>/dev/null || true
    sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf 2>/dev/null || true

    sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq_codel >/dev/null 2>&1

    show_success "$(t success_bbr_disabled)"
  else
    show_warning "$(t warning_bbr_not_configured)"
  fi

  echo -e "\n${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
  read -r
}

toggle_bbr() {
  if is_bbr_enabled; then
    disable_bbr
  else
    enable_bbr
  fi
}

# Including module: show-credentials.sh

show_panel_credentials() {
    echo

    local credentials_file="/opt/remnawave/credentials.txt"

    if [ -f "$credentials_file" ]; then
        echo -e "${BOLD_GREEN}$(t credentials_found)${NC}"
        echo

        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*$ ]]; then
                echo
            elif [[ "$line" =~ ^[[:space:]]*#.*$ ]] || [[ "$line" =~ ^[[:space:]]*\[.*\][[:space:]]*$ ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ "$line" =~ .*:.*$ ]]; then
                local key=$(echo "$line" | cut -d':' -f1)
                local value=$(echo "$line" | cut -d':' -f2-)
                echo -e "${ORANGE}$key:${GREEN}$value${NC}"
            else
                echo -e "${NC}$line"
            fi
        done < "$credentials_file"
    else
        echo -e "${BOLD_RED}$(t credentials_not_found)${NC}"
        echo
        echo -e "${YELLOW}$(t credentials_file_location) ${ORANGE}$credentials_file${NC}"
        echo
        echo -e "${YELLOW}$(t credentials_reasons)${NC}"
        echo -e "  • $(t credentials_reason_not_installed)"
        echo -e "  • $(t credentials_reason_incomplete)"
        echo -e "  • $(t credentials_reason_deleted)"
        echo
        echo -e "${YELLOW}$(t credentials_try_install)${NC}"
    fi

    echo
    echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
    read -r
}

# Including module: update.sh


check_images_updated() {
    local compose_dir="$1"
    local result_var="$2"

    cd "$compose_dir"

    local images_list=$(docker compose config --images 2>/dev/null)
    if [ -z "$images_list" ]; then
        eval "$result_var=error"
        return
    fi

    local updates_found=false

    while IFS= read -r image; do
        if [ -n "$image" ]; then
            local output=$(docker pull "$image" 2>&1)
            if echo "$output" | grep -q "Downloaded newer image"; then
                updates_found=true
                break
            fi
        fi
    done <<< "$images_list"

    if [ "$updates_found" = true ]; then
        eval "$result_var=updated"
    else
        eval "$result_var=no_updates"
    fi
}

show_update_warning() {
    local component_type="$1"  # "panel", "node", or "all"

    echo
    echo -e "${YELLOW}$(t update_warning_title)${NC}"
    echo
    echo -e "${YELLOW}$(t update_warning_backup)${NC}"
    echo -e "${YELLOW}$(t update_warning_changelog)${NC}"

    if [[ "$component_type" == "panel" || "$component_type" == "all" ]]; then
        echo -e "${BLUE}$(t update_warning_panel_releases)${NC}"
    fi
    if [[ "$component_type" == "node" || "$component_type" == "all" ]]; then
        echo -e "${BLUE}$(t update_warning_node_releases)${NC}"
    fi

    echo -e "${YELLOW}$(t update_warning_downtime)${NC}"
    echo

    if ! prompt_yes_no "$(t update_warning_confirm)" "$YELLOW"; then
        show_info "$(t update_cancelled)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    return 0
}

update_panel_only() {
    echo

    if [ ! -d /opt/remnawave ]; then
        show_error "$(t update_panel_dir_not_found)"
        show_error "$(t update_install_first)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    if [ ! -f /opt/remnawave/docker-compose.yml ]; then
        show_error "$(t update_compose_not_found)"
        show_error "$(t update_installation_corrupted)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    NODE_EXISTS=false
    if [ -d /opt/remnanode ] && [ -f /opt/remnanode/docker-compose.yml ]; then
        NODE_EXISTS=true
    fi

    if [ "$NODE_EXISTS" = true ]; then
        if ! show_update_warning "all"; then
            return 0
        fi
    else
        if ! show_update_warning "panel"; then
            return 0
        fi
    fi
    
    SUBSCRIPTION_PAGE_EXISTS=false
    if [ -d /opt/remnawave/subscription-page ] && [ -f /opt/remnawave/subscription-page/docker-compose.yml ]; then
        SUBSCRIPTION_PAGE_EXISTS=true
    fi

    local panel_updated=false
    local subscription_updated=false
    local node_updated=false
    local any_updates=false

    local panel_updated=false
    local subscription_updated=false
    local node_updated=false
    local any_updates=false

    show_info "$(t update_checking_images)" "$ORANGE"
    local panel_result=""
    check_images_updated "/opt/remnawave" panel_result &
    local check_pid=$!
    spinner $check_pid "$(t update_checking_images)"
    wait $check_pid

    if [ "$panel_result" = "updated" ]; then
        panel_updated=true
        any_updates=true
    elif [ "$panel_result" = "error" ]; then
        show_error "$(t update_pull_failed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ]; then
        local subscription_result=""
        check_images_updated "/opt/remnawave/subscription-page" subscription_result &
        local check_pid=$!
        spinner $check_pid "$(t update_checking_images)"
        wait $check_pid

        if [ "$subscription_result" = "updated" ]; then
            subscription_updated=true
            any_updates=true
        elif [ "$subscription_result" = "error" ]; then
            show_error "$(t update_pull_failed)"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    if [ "$NODE_EXISTS" = true ]; then
        local node_result=""
        check_images_updated "/opt/remnanode" node_result &
        local check_pid=$!
        spinner $check_pid "$(t update_checking_images)"
        wait $check_pid

        if [ "$node_result" = "updated" ]; then
            node_updated=true
            any_updates=true
        elif [ "$node_result" = "error" ]; then
            show_error "$(t update_pull_failed)"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    if [ "$any_updates" = false ]; then
        show_success "$(t update_no_updates_available)"
        show_info "$(t update_no_restart_needed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    show_info "$(t update_images_updated)"

    show_info "$(t update_starting_services)" "$ORANGE"

    if [ "$panel_updated" = true ]; then
        cd /opt/remnawave && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
        spinner $! "$(t update_starting_services)"
        if [ $? -ne 0 ]; then
            show_error "Failed to recreate panel services"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    if [ "$SUBSCRIPTION_PAGE_EXISTS" = true ] && [ "$subscription_updated" = true ]; then
        cd /opt/remnawave/subscription-page && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
        spinner $! "$(t update_starting_services)"
        if [ $? -ne 0 ]; then
            show_error "Failed to recreate subscription page services"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi

    if [ "$NODE_EXISTS" = true ] && [ "$node_updated" = true ]; then
        cd /opt/remnanode && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
        spinner $! "$(t update_starting_services)"
        if [ $? -ne 0 ]; then
            show_error "Failed to recreate node services"
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 1
        fi
    fi
    
    show_info "$(t update_cleaning_images)" "$ORANGE"
    docker image prune -f >/dev/null 2>&1 &
    spinner $! "$(t update_cleaning_images)"
    
    if [ "$NODE_EXISTS" = true ]; then
        show_success "$(t update_all_success)"
    else
        show_success "$(t update_panel_success)"
    fi
    
    show_info "$(t update_cleanup_complete)"
    
    echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
    read -r
}

update_node_only() {
    echo

    if [ ! -d /opt/remnanode ]; then
        show_error "$(t update_node_dir_not_found)"
        show_error "$(t update_install_first)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    if [ ! -f /opt/remnanode/docker-compose.yml ]; then
        show_error "$(t update_compose_not_found)"
        show_error "$(t update_installation_corrupted)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi

    if ! show_update_warning "node"; then
        return 0
    fi

    show_info "$(t update_checking_images)" "$ORANGE"
    local node_result=""
    check_images_updated "/opt/remnanode" node_result &
    local check_pid=$!
    spinner $check_pid "$(t update_checking_images)"
    wait $check_pid

    if [ "$node_result" = "updated" ]; then
        show_info "$(t update_images_updated)"
    elif [ "$node_result" = "no_updates" ]; then
        show_success "$(t update_no_updates_available)"
        show_info "$(t update_no_restart_needed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    else
        show_error "$(t update_pull_failed)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    show_info "$(t update_starting_services)" "$ORANGE"
    cd /opt/remnanode && docker compose up -d --remove-orphans --force-recreate >/dev/null 2>&1 &
    spinner $! "$(t update_starting_services)"
    if [ $? -ne 0 ]; then
        show_error "Failed to recreate node services"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi
    
    show_info "$(t update_cleaning_images)" "$ORANGE"
    docker image prune -f >/dev/null 2>&1 &
    spinner $! "$(t update_cleaning_images)"
    
    show_success "$(t update_node_success)"
    show_info "$(t update_cleanup_complete)"
    
    echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
    read -r
}

show_update_menu() {
    clear
    echo -e "${BOLD_GREEN}$(t update_menu_title)${NC}"
    echo
    echo -e "${YELLOW}$(t update_menu_panel_only)${NC}"
    echo -e "${GREEN}1.${NC} $(t update_menu_panel_update)"
    echo
    echo -e "${YELLOW}$(t update_menu_node_only)${NC}"
    echo -e "${GREEN}2.${NC} $(t update_menu_node_separate)"
    echo
    echo -e "${GREEN}0.${NC} $(t update_menu_back)"
    echo
    echo -ne "${BOLD_BLUE_MENU}$(t main_menu_select_option) ${NC}"
}

handle_update_menu() {
    while true; do
        show_update_menu
        read choice

        case $choice in
        1)
            update_panel_only
            ;;
        2)
            update_node_only
            ;;
        0)
            return
            ;;
        *)
            clear
            echo -e "${BOLD_RED}$(t error_invalid_choice)${NC}"
            sleep 1
            ;;
        esac
    done
}

# Including module: warp-docker-integration.sh


check_installation_type() {
    if [ -d /opt/remnawave ] && docker ps --format '{{.Names}}' | grep -q '^remnawave$'; then
        if [ -d /opt/remnawave/node ] && docker ps --format '{{.Names}}' | grep -q '^remnanode$'; then
            echo "all-in-one"
        else
            echo "panel-only"
        fi
    elif [ -d /opt/remnanode ] && docker ps --format '{{.Names}}' | grep -q '^remnanode$'; then
        echo "node-only"
    else
        echo "none"
    fi
}

check_panel_installation_docker() {
    if [ ! -d /opt/remnawave ]; then
        show_error "$(t warp_panel_not_found)"
        echo -e "${YELLOW}$(t update_install_first)${NC}"
        echo
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    if ! docker ps --format '{{.Names}}' | grep -q '^remnawave$'; then
        show_error "$(t warp_panel_not_running)"
        echo -e "${YELLOW}$(t cli_ensure_panel_running)${NC}"
        echo
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    if [ ! -f /opt/remnawave/credentials.txt ]; then
        show_error "$(t warp_credentials_not_found)"
        echo
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 1
    fi

    return 0
}

extract_panel_credentials_docker() {
    local credentials_file="/opt/remnawave/credentials.txt"
    
    PANEL_USERNAME=$(grep "REMNAWAVE ADMIN USERNAME:" "$credentials_file" | cut -d':' -f2 | xargs)
    PANEL_PASSWORD=$(grep "REMNAWAVE ADMIN PASSWORD:" "$credentials_file" | cut -d':' -f2 | xargs)
    PANEL_DOMAIN=$(grep "PANEL URL:" "$credentials_file" | cut -d'/' -f3 | cut -d'?' -f1)
    
    if [ -z "$PANEL_USERNAME" ]; then
        PANEL_USERNAME=$(grep "SUPERADMIN USERNAME:" "$credentials_file" | cut -d':' -f2 | xargs)
        PANEL_PASSWORD=$(grep "SUPERADMIN PASSWORD:" "$credentials_file" | cut -d':' -f2 | xargs)
    fi
    
    if [ -z "$PANEL_USERNAME" ] || [ -z "$PANEL_PASSWORD" ] || [ -z "$PANEL_DOMAIN" ]; then
        show_error "$(t warp_failed_auth)"
        return 1
    fi
    
    return 0
}

authenticate_panel_docker() {
    local panel_url="127.0.0.1:3000"
    local api_url="http://${panel_url}/api/auth/login"
    
    local temp_file=$(mktemp)
    local login_data="{\"username\":\"$PANEL_USERNAME\",\"password\":\"$PANEL_PASSWORD\"}"
    
    make_api_request "POST" "$api_url" "" "$PANEL_DOMAIN" "$login_data" >"$temp_file" 2>&1 &
    spinner $! "$(t warp_authenticating_panel)"
    local response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$response" ]; then
        show_error "$(t warp_failed_auth)"
        return 1
    fi
    
    if [[ "$response" == *"accessToken"* ]]; then
        PANEL_TOKEN=$(echo "$response" | jq -r '.response.accessToken')
        if [ -z "$PANEL_TOKEN" ] || [ "$PANEL_TOKEN" = "null" ]; then
            show_error "$(t warp_failed_auth)"
            return 1
        fi
        return 0
    else
        show_error "$(t warp_failed_auth)"
        return 1
    fi
}

get_nodes_list() {
    local panel_url="127.0.0.1:3000"
    local nodes_response=$(get_nodes "$panel_url" "$PANEL_TOKEN" "$PANEL_DOMAIN")
    
    if [ $? -ne 0 ] || [ -z "$nodes_response" ]; then
        show_error "$(t warp_no_nodes_found)"
        return 1
    fi
    
    NODES_JSON=$(echo "$nodes_response" | jq -r '.response // empty')
    if [ -z "$NODES_JSON" ] || [ "$NODES_JSON" = "null" ] || [ "$NODES_JSON" = "[]" ]; then
        show_error "$(t warp_no_nodes_found)"
        return 1
    fi
    
    return 0
}

select_nodes_for_warp() {
    local installation_type="$1"
    local nodes_count=$(echo "$NODES_JSON" | jq '. | length')
    
    if [ "$nodes_count" -eq 0 ]; then
        show_error "$(t warp_no_nodes_found)"
        return 1
    fi
    
    SELECTED_NODES=()
    SELECTED_NODE_ADDRESSES=()
    HAS_LOCAL_NODE=false
    
    if [ "$nodes_count" -eq 1 ]; then
        local node_uuid=$(echo "$NODES_JSON" | jq -r ".[0].uuid")
        local node_address=$(echo "$NODES_JSON" | jq -r ".[0].address")
        local node_name=$(echo "$NODES_JSON" | jq -r ".[0].name")
        
        SELECTED_NODES+=("$node_uuid|$node_name")
        SELECTED_NODE_ADDRESSES+=("$node_address")
        
        if [[ "$node_address" == "172.17.0.1" ]] || [[ "$node_address" == "127.0.0.1" ]] || [[ "$node_address" == "localhost" ]]; then
            HAS_LOCAL_NODE=true
            show_info "$(t warp_single_local_node_detected): $node_name - $node_address"
        else
            show_info "$(t warp_single_remote_node_detected): $node_name - $node_address"
        fi
        
        return 0
    fi
    
    local nodes_array=()
    local i=0
    while [ $i -lt "$nodes_count" ]; do
        local node_name=$(echo "$NODES_JSON" | jq -r ".[$i].name")
        local node_address=$(echo "$NODES_JSON" | jq -r ".[$i].address")
        local node_uuid=$(echo "$NODES_JSON" | jq -r ".[$i].uuid")
        local is_local=""
        
        if [[ "$node_address" == "172.17.0.1" ]] || [[ "$node_address" == "127.0.0.1" ]] || [[ "$node_address" == "localhost" ]]; then
            is_local=" $(t warp_node_local)"
        fi
        
        nodes_array+=("$node_uuid|$node_name - $node_address$is_local")
        ((i++))
    done
    
    echo
    echo -e "${BOLD_BLUE}$(t warp_select_nodes_title)${NC}"
    echo
    echo -e "${BOLD_GREEN}0)${NC} $(t warp_all_nodes)"
    
    i=0
    while [ $i -lt "$nodes_count" ]; do
        local node_info="${nodes_array[$i]}"
        local display_info="${node_info#*|}"
        echo -e "${BOLD_GREEN}$((i+1)))${NC} $display_info"
        ((i++))
    done
    
    echo
    read -p "$(t warp_select_node_prompt)" selection
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 0 ] || [ "$selection" -gt "$nodes_count" ]; then
        show_error "$(t warp_invalid_selection)"
        return 1
    fi
    
    if [ "$selection" -eq 0 ]; then
        i=0
        while [ $i -lt "$nodes_count" ]; do
            local node_uuid=$(echo "$NODES_JSON" | jq -r ".[$i].uuid")
            local node_address=$(echo "$NODES_JSON" | jq -r ".[$i].address")
            local node_name=$(echo "$NODES_JSON" | jq -r ".[$i].name")
            
            SELECTED_NODES+=("$node_uuid|$node_name")
            SELECTED_NODE_ADDRESSES+=("$node_address")
            
            if [[ "$node_address" == "172.17.0.1" ]] || [[ "$node_address" == "127.0.0.1" ]] || [[ "$node_address" == "localhost" ]]; then
                HAS_LOCAL_NODE=true
            fi
            ((i++))
        done
    else
        local node_index=$((selection-1))
        local node_uuid=$(echo "$NODES_JSON" | jq -r ".[$node_index].uuid")
        local node_address=$(echo "$NODES_JSON" | jq -r ".[$node_index].address")
        local node_name=$(echo "$NODES_JSON" | jq -r ".[$node_index].name")
        
        SELECTED_NODES+=("$node_uuid|$node_name")
        SELECTED_NODE_ADDRESSES+=("$node_address")
        
        if [[ "$node_address" == "172.17.0.1" ]] || [[ "$node_address" == "127.0.0.1" ]] || [[ "$node_address" == "localhost" ]]; then
            HAS_LOCAL_NODE=true
        fi
    fi
    
    return 0
}

update_profiles_for_selected_nodes() {
    local panel_url="127.0.0.1:3000"
    local temp_file=$(mktemp)
    
    make_api_request "GET" "http://$panel_url/api/config-profiles" "$PANEL_TOKEN" "$PANEL_DOMAIN" "" >"$temp_file" 2>&1 &
    spinner $! "$(t warp_getting_current_config)"
    local profiles_response=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [ -z "$profiles_response" ]; then
        show_error "$(t warp_failed_get_config)"
        return 1
    fi
    
    local profile_groups=$(
        for node_info in "${SELECTED_NODES[@]}"; do
            local node_uuid="${node_info%%|*}"
            local node_name="${node_info#*|}"
            local node_data=$(echo "$NODES_JSON" | jq -r ".[] | select(.uuid == \"$node_uuid\")")
            local profile_uuid=$(echo "$node_data" | jq -r '.configProfile.activeConfigProfileUuid // empty')
            
            if [ -n "$profile_uuid" ] && [ "$profile_uuid" != "null" ]; then
                echo "$profile_uuid|$node_name"
            fi
        done | sort | jq -R -s -c 'split("\n") | map(select(length > 0) | split("|") | {profile: .[0], node: .[1]}) | group_by(.profile) | map({profile: .[0].profile, nodes: map(.node)})'
    )
    
    local total_profiles=$(echo "$profile_groups" | jq '. | length')
    if [ "$total_profiles" -eq 0 ]; then
        show_error "$(t warp_failed_get_config)"
        return 1
    fi
    
    show_info "$(t warp_found_profiles): $total_profiles"
    
    local profiles_updated=0
    UPDATED_PROFILES_INFO=()
    
    echo "$profile_groups" | jq -c '.[]' | while read -r group; do
        local profile_uuid=$(echo "$group" | jq -r '.profile')
        local node_names=$(echo "$group" | jq -r '.nodes | join(", ")')
        
        local current_config=$(echo "$profiles_response" | jq -r ".response.configProfiles[] | select(.uuid == \"$profile_uuid\") | .config" 2>/dev/null)
        
        if [ -z "$current_config" ] || [ "$current_config" = "null" ]; then
            show_error "$(t warp_failed_get_config) for profile $profile_uuid"
            continue
        fi
        
        local profile_name=$(echo "$profiles_response" | jq -r ".response.configProfiles[] | select(.uuid == \"$profile_uuid\") | .name // \"$profile_uuid\"" 2>/dev/null)
        
        if echo "$current_config" | jq -e '.outbounds[] | select(.tag == "warp-out")' >/dev/null 2>&1; then
            show_warning "$(t warp_already_configured) ($(t warp_profile): $profile_name, $(t warp_nodes_lowercase): $node_names)"
            continue
        fi
        
        local warp_outbound=$(cat <<'EOF'
{
  "tag": "warp-out",
  "protocol": "freedom",
  "settings": {},
  "streamSettings": {
    "sockopt": {
      "interface": "warp",
      "tcpFastOpen": true
    }
  }
}
EOF
        )
        
        local updated_config=$(echo "$current_config" | jq --argjson warp_outbound "$warp_outbound" '.outbounds += [$warp_outbound]')
        
        if [ $? -ne 0 ]; then
            show_error "$(t warp_failed_update_config) for profile $profile_uuid"
            continue
        fi
        
        local warp_routing_rule=$(cat <<'EOF'
{
  "type": "field",
  "domain": [
    "ipinfo.io"
  ],
  "inboundTag": [
    "VLESS"
  ],
  "outboundTag": "warp-out"
}
EOF
        )
        
        updated_config=$(echo "$updated_config" | jq 'if .routing == null then .routing = {} else . end')
        updated_config=$(echo "$updated_config" | jq 'if .routing.rules == null then .routing.rules = [] else . end')
        updated_config=$(echo "$updated_config" | jq --argjson warp_rule "$warp_routing_rule" '.routing.rules += [$warp_rule]')
        
        if [ $? -ne 0 ]; then
            show_error "$(t warp_failed_update_config) for profile $profile_uuid"
            continue
        fi
        
        local update_data=$(jq -n --arg uuid "$profile_uuid" --argjson config "$updated_config" '{
            uuid: $uuid,
            config: $config
        }')
        
        local update_temp=$(mktemp)
        make_api_request "PATCH" "http://$panel_url/api/config-profiles" "$PANEL_TOKEN" "$PANEL_DOMAIN" "$update_data" >"$update_temp" 2>&1 &
        spinner $! "$(t warp_updating_config) ($node_names)"
        local update_response=$(cat "$update_temp")
        rm -f "$update_temp"
        
        if [ -z "$update_response" ]; then
            show_error "$(t warp_failed_update_config) for profile $profile_uuid"
            continue
        fi
        
        if echo "$update_response" | jq -e '.response.uuid' >/dev/null 2>&1; then
            ((profiles_updated++))
            echo "$node_names|$profile_name" >> /tmp/warp_updated_profiles.tmp
            show_success "$(t warp_profile_updated): $node_names"
        else
            show_error "$(t warp_failed_update_config) for profile $profile_uuid"
            echo "$(t api_response):"
            echo "$update_response"
        fi
    done
    
    if [ -f /tmp/warp_updated_profiles.tmp ]; then
        while IFS='|' read -r nodes profile; do
            UPDATED_PROFILES_INFO+=("$nodes ($(t warp_profile): $profile)")
        done < /tmp/warp_updated_profiles.tmp
        rm -f /tmp/warp_updated_profiles.tmp
        
        if [ ${#UPDATED_PROFILES_INFO[@]} -gt 0 ]; then
            return 0
        fi
    fi
    
    return 1
}

install_docker_warp_native() {
    local warp_dir="/opt/docker-warp-native"
    
    mkdir -p "$warp_dir"
    
    show_info "$(t warp_docker_downloading)"
    if ! wget -q "https://raw.githubusercontent.com/xxphantom/docker-warp-native/refs/heads/main/docker-compose.yml" -O "$warp_dir/docker-compose.yml"; then
        show_error "$(t warp_docker_download_failed)"
        return 1
    fi
    
    cd "$warp_dir"
    show_info "$(t warp_docker_starting)"
    
    if ! docker compose up -d; then
        show_error "$(t warp_docker_start_failed)"
        return 1
    fi
    
    echo
    show_info "$(t warp_docker_logs)"
    docker compose logs -f -t --tail=20 &
    local log_pid=$!
    
    sleep 10
    kill $log_pid 2>/dev/null
    
    cd - >/dev/null
    return 0
}

show_warp_config_changes() {
    local updated_profiles=("$@")
    
    clear
    echo -e "${BOLD_GREEN}$(t warp_docker_config_added)${NC}"
    echo
    
    if [ ${#updated_profiles[@]} -gt 0 ]; then
        echo -e "${BOLD_BLUE}$(t warp_affected_nodes_profiles):${NC}"
        echo
        for profile_info in "${updated_profiles[@]}"; do
            echo "  • $profile_info"
        done
        echo
    fi
    
    echo -e "${BOLD_BLUE}$(t warp_docker_outbound_added):${NC}"
    echo
    cat <<'EOF'
{
  "tag": "warp-out",
  "protocol": "freedom",
  "settings": {},
  "streamSettings": {
    "sockopt": {
      "interface": "warp",
      "tcpFastOpen": true
    }
  }
}
EOF
    echo
    echo -e "${BOLD_BLUE}$(t warp_docker_routing_added):${NC}"
    echo
    cat <<'EOF'
{
  "type": "field",
  "domain": [
    "ipinfo.io"
  ],
  "inboundTag": ["VLESS"],
  "outboundTag": "warp-out"
}
EOF
    echo
    echo -e "${YELLOW}$(t warp_docker_edit_domains)${NC}"
}

show_remote_nodes_warning() {
    local has_remote=false
    
    for addr in "${SELECTED_NODE_ADDRESSES[@]}"; do
        if [[ "$addr" != "172.17.0.1" ]] && [[ "$addr" != "127.0.0.1" ]] && [[ "$addr" != "localhost" ]]; then
            has_remote=true
            break
        fi
    done
    
    if [ "$has_remote" = true ]; then
        echo
        echo -e "${BOLD_RED}❗ $(t warp_remote_nodes_warning)${NC}"
        echo
        echo -e "${BLUE}$(t warp_docker_repo_link)${NC}"
        echo
    fi
}

add_warp_docker_integration() {
    clear
    echo -e "${BOLD_GREEN}$(t warp_docker_title)${NC}"
    echo -e "${BLUE}$(t warp_docker_subtitle)${NC}"
    echo
    
    if ! command -v docker &> /dev/null; then
        show_error "$(t warp_docker_no_docker)"
        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
        read -r
        return 0
    fi
    
    local installation_type=$(check_installation_type)
    
    case "$installation_type" in
        "node-only")
            show_info "$(t warp_node_only_detected)"
            echo
            show_info "$(t warp_installing_container_only)"
            
            if ! install_docker_warp_native; then
                echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
                read -r
                return 0
            fi
            
            show_success "$(t warp_container_installed_node_only)"
            echo
            echo -e "${YELLOW}$(t warp_manual_config_needed)${NC}"
            echo -e "${BLUE}$(t warp_docker_repo_link)${NC}"
            echo
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 0
            ;;
            
        "panel-only"|"all-in-one")
            show_info "$(t warp_checking_installation)" "$ORANGE"
            if ! check_panel_installation_docker; then
                return 0
            fi
            
            if ! extract_panel_credentials_docker; then
                echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
                read -r
                return 0
            fi
            
            if ! authenticate_panel_docker; then
                echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
                read -r
                return 0
            fi
            
            if ! get_nodes_list; then
                echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
                read -r
                return 0
            fi
            
            if ! select_nodes_for_warp "$installation_type"; then
                echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
                read -r
                return 0
            fi
            
            show_info "$(t warp_config_will_update)"
            
            if [ "$HAS_LOCAL_NODE" = true ] || [ "$installation_type" = "all-in-one" ]; then
                if [ -d "/opt/docker-warp-native" ] && docker ps --format '{{.Names}}' | grep -q "docker-warp-native"; then
                    show_warning "$(t warp_docker_already_installed)"
                    
                    if prompt_yes_no "$(t warp_docker_reinstall)" "$YELLOW"; then
                        cd /opt/docker-warp-native
                        docker compose down
                        cd - >/dev/null
                        rm -rf /opt/docker-warp-native
                    else
                        show_info "$(t warp_docker_updating_config_only)"
                    fi
                fi
                
                if [ ! -d "/opt/docker-warp-native" ] || ! docker ps --format '{{.Names}}' | grep -q "docker-warp-native"; then
                    if ! install_docker_warp_native; then
                        echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
                        read -r
                        return 0
                    fi
                fi
            fi
            
            show_info "$(t warp_updating_config)" "$ORANGE"
            if ! update_profiles_for_selected_nodes; then
                echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
                read -r
                return 0
            fi
            
            show_warp_config_changes "${UPDATED_PROFILES_INFO[@]}"
            
            show_remote_nodes_warning
            
            show_success "$(t warp_docker_success)"
            echo -e "${GREEN}$(t warp_docker_success_details)${NC}"
            echo -e "${GREEN}$(t warp_docker_config_updated)${NC}"
            echo
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            ;;
            
        *)
            show_error "$(t warp_panel_not_found)"
            echo -e "${YELLOW}$(t update_install_first)${NC}"
            echo
            echo -e "${BOLD_YELLOW}$(t prompt_enter_to_return)${NC}"
            read -r
            return 0
            ;;
    esac
}

# Including module: full-auth.sh


collect_full_auth_config() {
    AUTHP_ADMIN_EMAIL=$(prompt_email "$(t auth_admin_email)")
}

generate_full_auth_secrets() {
    CUSTOM_LOGIN_ROUTE=$(generate_custom_path)
    AUTHP_ADMIN_USER=$(generate_readable_login)
    AUTHP_ADMIN_SECRET=$(generate_secure_password 25)
}

start_caddy_full_auth() {
    if ! start_container "$REMNAWAVE_DIR/caddy" "Caddy"; then
        show_info "$(t services_installation_stopped)" "$BOLD_RED"
        exit 1
    fi
}

save_credentials_full_auth() {
    CREDENTIALS_FILE="$REMNAWAVE_DIR/credentials.txt"
    echo "PANEL URL: https://$PANEL_DOMAIN/$CUSTOM_LOGIN_ROUTE" >>"$CREDENTIALS_FILE"
    echo >>"$CREDENTIALS_FILE"
    echo "REMNAWAVE ADMIN USERNAME: $SUPERADMIN_USERNAME" >>"$CREDENTIALS_FILE"
    echo "REMNAWAVE ADMIN PASSWORD: $SUPERADMIN_PASSWORD" >>"$CREDENTIALS_FILE"
    echo >>"$CREDENTIALS_FILE"
    echo "CADDY AUTH USERNAME: $AUTHP_ADMIN_USER" >>"$CREDENTIALS_FILE"
    echo "CADDY AUTH PASSWORD: $AUTHP_ADMIN_SECRET" >>"$CREDENTIALS_FILE"
    echo "CADDY AUTH EMAIL: $AUTHP_ADMIN_EMAIL" >>"$CREDENTIALS_FILE"
    echo >>"$CREDENTIALS_FILE"

    chmod 600 "$CREDENTIALS_FILE"
}

display_full_auth_results() {
    local installation_type="${1:-panel}"
    local caddy_auth_url="https://$PANEL_DOMAIN/$CUSTOM_LOGIN_ROUTE/auth"

    local max_width=${#caddy_auth_url}
    if [ -n "$USER_SUBSCRIPTION_URL" ] && [ "$installation_type" = "all-in-one" ]; then
        if [ ${#USER_SUBSCRIPTION_URL} -gt $max_width ]; then
            max_width=${#USER_SUBSCRIPTION_URL}
        fi
    fi
    local effective_width=$((max_width + 3))
    local border_line=$(printf '─%.0s' $(seq 1 $effective_width))

    print_text_line() {
        local text="$1"
        local padding=$((effective_width - ${#text} - 1))
        echo -e "\033[1m│ $text$(printf '%*s' $padding)│\033[0m"
    }

    print_empty_line() {
        echo -e "\033[1m│$(printf '%*s' $effective_width)│\033[0m"
    }

    echo -e "\033[1m┌${border_line}┐\033[0m"

    print_text_line "$(t results_auth_portal_page)"
    print_text_line "$caddy_auth_url"
    print_empty_line

    if [ "$installation_type" = "all-in-one" ] && [ -n "$USER_SUBSCRIPTION_URL" ] && [ "$USER_SUBSCRIPTION_URL" != "null" ]; then
        print_text_line "$(t results_user_subscription_url)"
        print_text_line "$USER_SUBSCRIPTION_URL"
        print_empty_line
    fi

    print_text_line "$(t results_caddy_auth_login) $AUTHP_ADMIN_USER"
    print_text_line "$(t results_caddy_auth_password) $AUTHP_ADMIN_SECRET"
    print_empty_line
    print_text_line "$(t results_remnawave_admin_login) $SUPERADMIN_USERNAME"
    print_text_line "$(t results_remnawave_admin_password) $SUPERADMIN_PASSWORD"
    print_empty_line
    echo -e "\033[1m└${border_line}┘\033[0m"

    echo
    show_success "$(t success_credentials_saved) $CREDENTIALS_FILE"
    echo -e "${BOLD_BLUE}$(t info_installation_directory) ${NC}$REMNAWAVE_DIR/"
    echo

    if [ "$installation_type" = "all-in-one" ] && [ -n "$USER_SUBSCRIPTION_URL" ] && [ "$USER_SUBSCRIPTION_URL" != "null" ]; then
        generate_qr_code "$USER_SUBSCRIPTION_URL" "$(t qr_subscription_url)"
        echo
    fi

    cd ~

    echo -e "${BOLD_GREEN}$(t success_installation_complete)${NC}"
    read -r
}

# Including module: cookie-auth.sh
start_caddy_cookie_auth() {
  if ! start_container "$REMNAWAVE_DIR/caddy" "Caddy"; then
    show_info "$(t services_installation_stopped)" "$BOLD_RED"
    exit 1
  fi
}

generate_cookie_auth_secrets() {
  PANEL_SECRET_KEY=$(generate_nonce 64)
}

save_credentials_cookie_auth() {
  CREDENTIALS_FILE="$REMNAWAVE_DIR/credentials.txt"
  echo "PANEL URL: https://$PANEL_DOMAIN?caddy=$PANEL_SECRET_KEY" >>"$CREDENTIALS_FILE"
  echo >>"$CREDENTIALS_FILE"
  echo "REMNAWAVE ADMIN USERNAME: $SUPERADMIN_USERNAME" >>"$CREDENTIALS_FILE"
  echo "REMNAWAVE ADMIN PASSWORD: $SUPERADMIN_PASSWORD" >>"$CREDENTIALS_FILE"

  chmod 600 "$CREDENTIALS_FILE"
}

display_cookie_auth_results() {
  local installation_type="${1:-panel}" # Default to panel if not specified
  local secure_panel_url="https://$PANEL_DOMAIN/auth/login?caddy=$PANEL_SECRET_KEY"

  local max_width=${#secure_panel_url}
  if [ -n "$USER_SUBSCRIPTION_URL" ] && [ "$installation_type" = "all-in-one" ]; then
    if [ ${#USER_SUBSCRIPTION_URL} -gt $max_width ]; then
      max_width=${#USER_SUBSCRIPTION_URL}
    fi
  fi
  local effective_width=$((max_width + 3))
  local border_line=$(printf '─%.0s' $(seq 1 $effective_width))

  print_text_line() {
    local text="$1"
    local padding=$((effective_width - ${#text} - 1))
    echo -e "\033[1m│ $text$(printf '%*s' $padding)│\033[0m"
  }

  print_empty_line() {
    echo -e "\033[1m│$(printf '%*s' $effective_width)│\033[0m"
  }

  echo -e "\033[1m┌${border_line}┐\033[0m"

  print_text_line "$(t results_secure_login_link)"
  print_empty_line
  print_text_line "$secure_panel_url"
  print_empty_line

  if [ "$installation_type" = "all-in-one" ] && [ -n "$USER_SUBSCRIPTION_URL" ] && [ "$USER_SUBSCRIPTION_URL" != "null" ]; then
    print_text_line "$(t results_user_subscription_url)"
    print_text_line "$USER_SUBSCRIPTION_URL"
    print_empty_line
  fi

  print_text_line "$(t results_admin_login) $SUPERADMIN_USERNAME"
  print_text_line "$(t results_admin_password) $SUPERADMIN_PASSWORD"
  print_empty_line
  echo -e "\033[1m└${border_line}┘\033[0m"

  echo
  show_success "$(t success_credentials_saved) $CREDENTIALS_FILE"
  echo -e "${BOLD_BLUE}$(t info_installation_directory) ${NC}$REMNAWAVE_DIR/"
  echo

  if [ "$installation_type" = "all-in-one" ] && [ -n "$USER_SUBSCRIPTION_URL" ] && [ "$USER_SUBSCRIPTION_URL" != "null" ]; then
    generate_qr_code "$USER_SUBSCRIPTION_URL" "$(t qr_subscription_url)"
    echo
  fi

  cd ~

  echo -e "${BOLD_GREEN}$(t success_installation_complete)${NC}"
  read -r
}

# Including module: static-site.sh

create_static_site() {
  local directory="$1"

  mkdir -p "$directory/html"

  (
    cd "$directory/html"
    generate_selfsteal_form
  ) >/dev/null 2>&1 &

  download_pid=$!
  spinner !$download_pid "$(t spinner_downloading_static_files)"
}

# Including module: subscription-page.sh

setup_remnawave-subscription-page() {
    mkdir -p $REMNAWAVE_DIR/subscription-page

    cd $REMNAWAVE_DIR/subscription-page

    cat >docker-compose.yml <<EOF
services:
    remnawave-subscription-page:
        image: remnawave/subscription-page:latest
        container_name: remnawave-subscription-page
        hostname: remnawave-subscription-page
        restart: always
        environment:
            - REMNAWAVE_PANEL_URL=http://remnawave:3000
            - SUBSCRIPTION_PAGE_PORT=3010
            - META_TITLE="Subscription Page Title"
            - META_DESCRIPTION="Subscription Page Description"
        ports:
            - '127.0.0.1:3010:3010'
        networks:
            - remnawave-network

networks:
    remnawave-network:
        driver: bridge
        external: true
EOF

    create_makefile "$REMNAWAVE_DIR/subscription-page"
}

# Including module: vless-config.sh


configure_vless_panel_only() {
    local panel_url="127.0.0.1:3000"
    local config_file="$REMNAWAVE_DIR/config.json"

    NODE_HOST=$(simple_read_domain_or_ip "$(t vless_enter_node_host)" "$SELF_STEAL_DOMAIN")

    local keys_result=$(generate_vless_keys "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ $? -ne 0 ]; then
        return 1
    fi

    local private_key=$(echo "$keys_result" | cut -d':' -f1)

    generate_xray_config "$config_file" "$SELF_STEAL_DOMAIN" "$CADDY_LOCAL_PORT" "$private_key"

    local xray_config=$(cat "$config_file")

    local profiles_response=$(get_config_profiles "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -n "$profiles_response" ]; then
        local default_profile_uuid=$(echo "$profiles_response" | jq -r '.response.configProfiles[0].uuid // empty' 2>/dev/null)
        
        if [ -n "$default_profile_uuid" ] && [ "$default_profile_uuid" != "null" ]; then
            delete_config_profile "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$default_profile_uuid"
        fi
    fi

    local profile_result=$(create_config_profile "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "StealConfig" "$xray_config")
    if [ -z "$profile_result" ]; then
        return 1
    fi

    local profile_uuid=$(echo "$profile_result" | cut -d':' -f1)
    local inbound_uuid=$(echo "$profile_result" | cut -d':' -f2)

    if ! create_node "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$NODE_HOST" "$NODE_PORT" "$profile_uuid" "$inbound_uuid"; then
        return 1
    fi

    if ! create_host "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$profile_uuid" "$inbound_uuid" "$SELF_STEAL_DOMAIN"; then
        return 1
    fi

    local squads_response=$(get_squads "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -z "$squads_response" ]; then
        return 1
    fi

    local squad_uuid=$(echo "$squads_response" | jq -r '.response.internalSquads[0].uuid' 2>/dev/null)
    
    if [ -z "$squad_uuid" ] || [ "$squad_uuid" = "null" ]; then
        echo -e "${BOLD_RED}Error: No squads found${NC}"
        echo "Squads response:"
        echo "$squads_response" | jq '.'
        return 1
    fi

    if ! update_squad "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$squad_uuid" "$inbound_uuid"; then
        return 1
    fi

    if ! create_user "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "remnawave" "$inbound_uuid" "$squad_uuid"; then
        return 1
    fi

    local pubkey=$(get_public_key "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -n "$pubkey" ]; then
        echo
        echo -e "${GREEN}$(t vless_public_key_required)${NC}"
        echo
        echo -e "SSL_CERT=\"$pubkey\""
        echo
    fi
}

# Including module: caddy-cookie-auth.sh

setup_caddy_for_panel() {
	local BACKEND_URL=127.0.0.1:3000
	local SUB_BACKEND_URL=127.0.0.1:3010
	cd $REMNAWAVE_DIR/caddy

	cat >docker-compose.yml <<EOF
services:
  caddy:
    image: caddy:2.9.1
    container_name: caddy-remnawave
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./html:/var/www/html
      - ./logs:/var/log/caddy
      - remnawave-caddy-ssl-data:/data
    environment:
      - CADDY_LOCAL_PORT=$CADDY_LOCAL_PORT
      - SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
      - PANEL_DOMAIN=$PANEL_DOMAIN
      - SUB_DOMAIN=$SUB_DOMAIN
      - BACKEND_URL=$BACKEND_URL
      - SUB_BACKEND_URL=$SUB_BACKEND_URL
      - PANEL_SECRET_KEY=$PANEL_SECRET_KEY
    network_mode: "host"

volumes:
  remnawave-caddy-ssl-data:
    driver: local
    external: false
    name: remnawave-caddy-ssl-data
EOF

	cat >Caddyfile <<"EOF"
{
	admin   off
}

https://{$SELF_STEAL_DOMAIN} {
	root * /var/www/html
	try_files {path} /index.html
	file_server
}

https://{$PANEL_DOMAIN} {
	@has_token_param {
		query caddy={$PANEL_SECRET_KEY}
	}

	handle @has_token_param {
		header +Set-Cookie "caddy={$PANEL_SECRET_KEY}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=31536000"
	}

	@unauthorized {
		not header Cookie *caddy={$PANEL_SECRET_KEY}*
		not query caddy={$PANEL_SECRET_KEY}
	}

	handle @unauthorized {
		root * /var/www/html
		try_files {path} /index.html
		file_server
	}

	reverse_proxy {$BACKEND_URL} {
		header_up X-Real-IP {remote}
		header_up Host {host}
	}
}

https://{$SUB_DOMAIN} {
	handle {
		reverse_proxy {$SUB_BACKEND_URL} {
			header_up X-Real-IP {remote}
			header_up Host {host}
		}
	}
}

:{$CADDY_LOCAL_PORT} {
	tls internal
	respond 204
}

:80 {
	bind 0.0.0.0
	respond 204
}
EOF

	create_makefile "$REMNAWAVE_DIR/caddy"

	create_static_site "$REMNAWAVE_DIR/caddy"
}

# Including module: caddy-full-auth.sh

setup_caddy_panel_only_full_auth() {
    cd $REMNAWAVE_DIR/caddy

    cat >Caddyfile <<"EOF"
{
    admin   off
    auto_https disable_redirects
    order authenticate before respond
    order authorize before respond

    security {
        local identity store localdb {
            realm local
            path /data/.local/caddy/users.json
        }

        authentication portal remnawaveportal {
            crypto default token lifetime {$AUTH_TOKEN_LIFETIME}
            enable identity store localdb
            cookie domain {$REMNAWAVE_PANEL_DOMAIN}
            ui {
                links {
                    "Remnawave" "/dashboard/home" icon "las la-tachometer-alt"
                    "My Identity" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/whoami" icon "las la-user"
                    "API Keys" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/settings/apikeys" icon "las la-key"
                    "MFA" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/settings/mfa" icon "lab la-keycdn"
                }
            }
            transform user {
                match origin local
                require mfa
                action add role authp/admin
            }
        }

        authorization policy panelpolicy {
            set auth url /restricted
            disable auth redirect
            allow roles authp/admin
            with api key auth portal remnawaveportal realm local

            acl rule {
                comment "Accept"
                match role authp/admin
                allow stop log info
            }
            acl rule {
                comment "Deny"
                match any
                deny log warn
            }
        }
    }
}

http://{$REMNAWAVE_PANEL_DOMAIN} {
    redir https://{$REMNAWAVE_PANEL_DOMAIN}{uri} permanent
}

https://{$REMNAWAVE_PANEL_DOMAIN} {

    @login_path {
        path /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE} /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/ /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/auth
    }
    handle @login_path {
        rewrite * /auth
        request_header +X-Forwarded-Prefix /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}
        authenticate with remnawaveportal
    }

    handle_path /restricted* {
        abort
    }

    route /api/* {
        authorize with panelpolicy
        reverse_proxy http://127.0.0.1:3000
    }

    route /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}* {
        authenticate with remnawaveportal
    }

    route /* {
        authorize with panelpolicy
        reverse_proxy http://127.0.0.1:3000
    }

    handle_errors {
        @unauth {
            expression {http.error.status_code} == 401
        }
        handle @unauth {
            respond * 204
        }
    }
}

http://{$CADDY_SUB_DOMAIN} {
    redir https://{$CADDY_SUB_DOMAIN}{uri} permanent
}

https://{$CADDY_SUB_DOMAIN} {
    handle {
        reverse_proxy http://127.0.0.1:3010 {
            header_up X-Real-IP {remote}
            header_up Host {host}
        }
    }
    handle_errors {
        handle {
            respond * 204
        }
    }
}
EOF

    cat >docker-compose.yml <<EOF
services:
    remnawave-caddy:
        image: remnawave/caddy-with-auth:latest
        container_name: 'remnawave-caddy'
        hostname: remnawave-caddy
        restart: always
        environment:
            - AUTH_TOKEN_LIFETIME=3600
            - REMNAWAVE_PANEL_DOMAIN=$PANEL_DOMAIN
            - REMNAWAVE_CUSTOM_LOGIN_ROUTE=$CUSTOM_LOGIN_ROUTE
            - AUTHP_ADMIN_USER=$AUTHP_ADMIN_USER
            - AUTHP_ADMIN_EMAIL=$AUTHP_ADMIN_EMAIL
            - AUTHP_ADMIN_SECRET=$AUTHP_ADMIN_SECRET
            - HTTPS_PORT=$CADDY_LOCAL_PORT
            - CADDY_SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
            - CADDY_SUB_DOMAIN=$SUB_DOMAIN
        volumes:
            - ./Caddyfile:/etc/caddy/Caddyfile
            - ./html:/var/www/html
            - remnawave-caddy-ssl-data:/data
        network_mode: "host"

volumes:
    remnawave-caddy-ssl-data:
        driver: local
        external: false
        name: remnawave-caddy-ssl-data
EOF

    create_makefile "$REMNAWAVE_DIR/caddy"
    create_static_site "$REMNAWAVE_DIR/caddy"
}

# Including module: setup.sh


generate_secrets_panel_only() {
    local auth_type=$1

    generate_secrets
    if [ "$auth_type" = "full" ]; then
        generate_full_auth_secrets
    else
        if [ "$auth_type" = "cookie" ]; then
            generate_cookie_auth_secrets
        fi
    fi
}

collect_selfsteal_domain_for_panel() {
    while true; do
        SELF_STEAL_DOMAIN=$(prompt_domain "$(t domain_selfsteal_prompt)" "$ORANGE" true false true)

        if check_domain_uniqueness "$SELF_STEAL_DOMAIN" "selfsteal" "$PANEL_DOMAIN" "$SUB_DOMAIN"; then
            break
        fi
        show_warning "$(t warning_enter_different_domain) selfsteal."
        echo
    done
}

collect_config_panel_only() {
    local auth_type=$1

    collect_telegram_config
    collect_domain_config
    collect_selfsteal_domain_for_panel

    if ! collect_ports_separate_installation; then
        return 1
    fi

    if [ "$auth_type" = "full" ]; then
        collect_full_auth_config
    fi
}

setup_caddy_panel_only() {
    local auth_type=$1

    if [ "$auth_type" = "cookie" ]; then
        setup_caddy_for_panel "$PANEL_SECRET_KEY"
    else
        if [ "$auth_type" = "full" ]; then
            setup_caddy_panel_only_full_auth
        fi
    fi
}

start_caddy_panel_only() {
    local auth_type=$1

    if [ "$auth_type" = "cookie" ]; then
        start_caddy_cookie_auth
    else
        if [ "$auth_type" = "full" ]; then
            start_caddy_full_auth
        fi
    fi
}

save_and_display_panel_only() {
    local auth_type=$1

    if [ "$auth_type" = "cookie" ]; then
        save_credentials_cookie_auth
        display_cookie_auth_results "panel"
    else
        if [ "$auth_type" = "full" ]; then
            save_credentials_full_auth
            display_full_auth_results "panel"
        fi
    fi
}

install_panel_only() {
    local auth_type=$1

    if [[ "$auth_type" != "cookie" && "$auth_type" != "full" ]]; then
        show_error "$(t panel_invalid_auth_type): $auth_type. $(t panel_auth_type_options)"
        return 1
    fi

    if ! prepare_installation; then
        return 1
    fi

    generate_secrets_panel_only $auth_type

    if ! collect_config_panel_only $auth_type; then
        return 1
    fi

    setup_panel_docker_compose

    setup_panel_environment

    create_makefile "$REMNAWAVE_DIR"

    setup_caddy_panel_only $auth_type
    setup_remnawave-subscription-page

    start_services
    start_caddy_panel_only $auth_type

    register_panel_user
    configure_vless_panel_only

    save_and_display_panel_only $auth_type
}

# Including module: selfsteal.sh


setup_selfsteal() {
    mkdir -p $SELFSTEAL_DIR/html && cd $SELFSTEAL_DIR

    cat >.env <<EOF
SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
CADDY_LOCAL_PORT=$CADDY_LOCAL_PORT
EOF

    cat >Caddyfile <<'EOF'
{
    admin   off
    https_port {$CADDY_LOCAL_PORT}
    default_bind 127.0.0.1
    servers {
        listener_wrappers {
            proxy_protocol {
                allow 127.0.0.1/32
            }
            tls
        }
    }
    auto_https disable_redirects
}

http://{$SELF_STEAL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$SELF_STEAL_DOMAIN}{uri} permanent
}

https://{$SELF_STEAL_DOMAIN} {
    root * /var/www/html
    try_files {path} /index.html
    file_server
}


:{$CADDY_LOCAL_PORT} {
    tls internal
    respond 204
}

:80 {
    bind 0.0.0.0
    respond 204
}
EOF

    cat >docker-compose.yml <<EOF
services:
  caddy:
    image: caddy:2.9.1
    container_name: caddy-selfsteal
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./html:/var/www/html
      - remnawave-caddy-ssl-data:/data
    env_file:
      - .env
    network_mode: "host"

volumes:
    remnawave-caddy-ssl-data:
        driver: local
        external: false
        name: remnawave-caddy-ssl-data
EOF

    create_makefile "$SELFSTEAL_DIR"

    create_static_site "$SELFSTEAL_DIR"

    mkdir -p logs

    if ! start_container "$SELFSTEAL_DIR" "Caddy"; then
        show_info "$(t selfsteal_installation_stopped)" "$BOLD_RED"
        exit 1
    fi

    CADDY_STATUS=$(docker compose ps --services --filter "status=running" | grep -q "caddy" && echo "running" || echo "stopped")

    if [ "$CADDY_STATUS" = "running" ]; then
        echo -e "${LIGHT_GREEN}$(t selfsteal_domain_info) ${BOLD_GREEN}$SELF_STEAL_DOMAIN${NC}"
        echo -e "${LIGHT_GREEN}$(t selfsteal_port_info) ${BOLD_GREEN}$CADDY_LOCAL_PORT${NC}"
        echo -e "${LIGHT_GREEN}$(t selfsteal_directory_info) ${BOLD_GREEN}$SELFSTEAL_DIR${NC}"
        echo
    fi

    unset SELF_STEAL_DOMAIN
    unset CADDY_LOCAL_PORT
}

# Including module: node.sh

create_node_docker_compose() {
    mkdir -p $REMNANODE_DIR && cd $REMNANODE_DIR
    cat >docker-compose.yml <<EOL
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:$REMNAWAVE_NODE_TAG
    env_file:
      - .env
    network_mode: host
    restart: always
EOL
}

collect_node_selfsteal_domain() {
    SELF_STEAL_DOMAIN=$(prompt_domain "$(t node_enter_selfsteal_domain)" "$ORANGE" true false false)
}

check_node_ports() {
    if CADDY_LOCAL_PORT=$(check_required_port "9443"); then
        show_info "$(t config_caddy_port_available)"
    else
        show_error "$(t node_port_9443_in_use)"
        show_error "$(t node_separate_port_9443)"
        show_error "$(t node_free_port_9443)"
        show_error "$(t node_cannot_continue_9443)"
        exit 1
    fi

    if NODE_PORT=$(check_required_port "2222"); then
        show_info "$(t config_node_port_available)"
    else
        show_error "$(t node_port_2222_in_use)"
        show_error "$(t node_separate_port_2222)"
        show_error "$(t node_free_port_2222)"
        show_error "$(t node_cannot_continue_2222)"
        exit 1
    fi
}

collect_node_ssl_certificate() {
    while true; do
        echo -e "${ORANGE}$(t node_enter_ssl_cert) ${NC}"
        CERTIFICATE=""
        while IFS= read -r line; do
            if [ -z "$line" ]; then
                if [ -n "$CERTIFICATE" ]; then
                    break
                fi
            else
                CERTIFICATE="${CERTIFICATE}${line}"
            fi
        done

        if validate_ssl_certificate "$CERTIFICATE"; then
            echo -e "${BOLD_GREEN}$(t node_ssl_cert_valid)${NC}"
            echo
            break
        else
            echo -e "${BOLD_RED}$(t node_ssl_cert_invalid)${NC}"
            echo -e "${YELLOW}$(t node_ssl_cert_expected)${NC}"
            echo
        fi
    done
}

create_node_env_file() {
    echo -e "### APP ###" >.env
    echo -e "APP_PORT=$NODE_PORT" >>.env
    echo -e "$CERTIFICATE" >>.env
}

start_node_and_show_results() {
    if ! start_container "$REMNANODE_DIR" "Remnawave Node"; then
        show_info "$(t services_installation_stopped)" "$BOLD_RED"
        exit 1
    fi

    echo -e "${LIGHT_GREEN}$(t node_port_info) ${BOLD_GREEN}$NODE_PORT${NC}"
    echo -e "${LIGHT_GREEN}$(t node_directory_info) ${BOLD_GREEN}$REMNANODE_DIR${NC}"
    echo
}

collect_panel_ip() {
    while true; do
        PANEL_IP=$(simple_read_domain_or_ip "$(t node_enter_panel_ip)" "" "ip_only")
        if [ -n "$PANEL_IP" ]; then
            break
        fi
    done
}

allow_ufw_node_port_from_panel_ip() {
    echo "$(t node_allow_connections)"
    echo
    ufw allow from "$PANEL_IP" to any port 2222 proto tcp
    echo
    ufw reload >/dev/null 2>&1
}

setup_node() {
    clear

    if ! prepare_installation; then
        return 1
    fi

    create_node_docker_compose

    create_makefile "$REMNANODE_DIR"

    collect_node_selfsteal_domain

    collect_panel_ip

    allow_ufw_node_port_from_panel_ip

    check_node_ports

    collect_node_ssl_certificate

    create_node_env_file

    setup_selfsteal

    start_node_and_show_results

    unset CERTIFICATE
    unset NODE_PORT

    echo -e "\n${BOLD_GREEN}$(t node_press_enter_return)${NC}"
    read -r
}

# Including module: vless-config.sh


configure_vless_all_in_one() {
    local panel_url="127.0.0.1:3000"
    local config_file="$REMNAWAVE_DIR/config.json"
    local node_host="172.17.0.1"  # Docker bridge IP
    
    local keys_result=$(generate_vless_keys "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local private_key=$(echo "$keys_result" | cut -d':' -f1)
    
    generate_xray_config "$config_file" "$SELF_STEAL_DOMAIN" "$CADDY_LOCAL_PORT" "$private_key"
    
    local xray_config=$(cat "$config_file")
    
    local profiles_response=$(get_config_profiles "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -n "$profiles_response" ]; then
        local default_profile_uuid=$(echo "$profiles_response" | jq -r '.response.configProfiles[0].uuid // empty' 2>/dev/null)
        
        if [ -n "$default_profile_uuid" ] && [ "$default_profile_uuid" != "null" ]; then
            delete_config_profile "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$default_profile_uuid"
        fi
    fi
    
    local profile_result=$(create_config_profile "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "StealConfig" "$xray_config")
    if [ -z "$profile_result" ]; then
        return 1
    fi
    
    local profile_uuid=$(echo "$profile_result" | cut -d':' -f1)
    local inbound_uuid=$(echo "$profile_result" | cut -d':' -f2)
    
    if ! create_node "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$node_host" "$NODE_PORT" "$profile_uuid" "$inbound_uuid"; then
        return 1
    fi
    
    if ! create_host "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$profile_uuid" "$inbound_uuid" "$SELF_STEAL_DOMAIN"; then
        return 1
    fi
    
    local squads_response=$(get_squads "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN")
    if [ -z "$squads_response" ]; then
        return 1
    fi
    
    local squad_uuid=$(echo "$squads_response" | jq -r '.response.internalSquads[0].uuid' 2>/dev/null)
    
    if [ -z "$squad_uuid" ] || [ "$squad_uuid" = "null" ]; then
        echo -e "${BOLD_RED}Error: No squads found${NC}"
        echo "Squads response:"
        echo "$squads_response" | jq '.'
        return 1
    fi
    
    if ! update_squad "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "$squad_uuid" "$inbound_uuid"; then
        return 1
    fi

    if ! create_user "$panel_url" "$REG_TOKEN" "$PANEL_DOMAIN" "remnawave" "$inbound_uuid" "$squad_uuid"; then
        return 1
    fi
}



# Including module: setup-node.sh


setup_node_all_in_one() {
  local panel_url=$1
  local token=$2
  local NODE_PORT=$3

  create_dir "$LOCAL_REMNANODE_DIR"

  cd "$LOCAL_REMNANODE_DIR"

  cat >docker-compose.yml <<EOL
services:
  remnanode:
    container_name: remnanode
    hostname: remnanode
    image: remnawave/node:$REMNAWAVE_NODE_TAG
    env_file:
      - .env
    network_mode: host
    restart: always
EOL

  create_makefile "$LOCAL_REMNANODE_DIR"

  local pubkey=$(get_public_key "$panel_url" "$token" "$PANEL_DOMAIN")

  if [ -z "$pubkey" ]; then
    return 1
  fi

  local CERTIFICATE="SSL_CERT=\"$pubkey\""

  echo -e "### APP ###\nAPP_PORT=$NODE_PORT\n$CERTIFICATE" >.env
}

setup_and_start_all_in_one_node() {
  setup_node_all_in_one "127.0.0.1:3000" "$REG_TOKEN" "$NODE_PORT"

  if ! start_container "$LOCAL_REMNANODE_DIR" "Remnawave Node"; then
    show_info "$(t services_installation_stopped)" "$BOLD_RED"
    exit 1
  fi
}

# Including module: caddy-cookie-auth.sh

create_docker_compose_cookie_auth() {
	local BACKEND_URL=127.0.0.1:3000
	local SUB_BACKEND_URL=127.0.0.1:3010

	cat >docker-compose.yml <<EOF
services:
  caddy:
    image: caddy:2.9.1
    container_name: caddy-remnawave
    restart: unless-stopped
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./html:/var/www/html
      - ./logs:/var/log/caddy
      - remnawave-caddy-ssl-data:/data
    environment:
      - CADDY_LOCAL_PORT=$CADDY_LOCAL_PORT
      - SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
      - PANEL_DOMAIN=$PANEL_DOMAIN
      - SUB_DOMAIN=$SUB_DOMAIN
      - BACKEND_URL=$BACKEND_URL
      - SUB_BACKEND_URL=$SUB_BACKEND_URL
      - PANEL_SECRET_KEY=$PANEL_SECRET_KEY
    network_mode: "host"

volumes:
  remnawave-caddy-ssl-data:
    driver: local
    external: false
    name: remnawave-caddy-ssl-data
EOF
}

create_Caddyfile_cookie_auth() {

	cat >Caddyfile <<"EOF"
{
	admin   off
	https_port {$CADDY_LOCAL_PORT}
	default_bind 127.0.0.1
	servers {
		listener_wrappers {
			proxy_protocol {
				allow 127.0.0.1/32
			}
			tls
		}
	}
	auto_https disable_redirects
}

http://{$SELF_STEAL_DOMAIN} {
	bind 0.0.0.0
	redir https://{$SELF_STEAL_DOMAIN}{uri} permanent
}

https://{$SELF_STEAL_DOMAIN} {
	root * /var/www/html
	try_files {path} /index.html
	file_server
}

http://{$PANEL_DOMAIN} {
	bind 0.0.0.0
	redir https://{$PANEL_DOMAIN}{uri} permanent
}

https://{$PANEL_DOMAIN} {
	@has_token_param {
		query caddy={$PANEL_SECRET_KEY}
	}

	handle @has_token_param {
		header +Set-Cookie "caddy={$PANEL_SECRET_KEY}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=2592000"
	}

	@unauthorized {
		not header Cookie *caddy={$PANEL_SECRET_KEY}*
		not query caddy={$PANEL_SECRET_KEY}
	}

	handle @unauthorized {
		root * /var/www/html
		try_files {path} /index.html
		file_server
	}

	reverse_proxy {$BACKEND_URL} {
		header_up X-Real-IP {remote}
		header_up Host {host}
	}
}

http://{$SUB_DOMAIN} {
	bind 0.0.0.0
	redir https://{$SUB_DOMAIN}{uri} permanent
}

https://{$SUB_DOMAIN} {
	handle {
		reverse_proxy {$SUB_BACKEND_URL} {
			header_up X-Real-IP {remote}
			header_up Host {host}
		}
	}
}

:{$CADDY_LOCAL_PORT} {
	tls internal
	respond 204
}

:80 {
	bind 0.0.0.0
	respond 204
}
EOF

}

setup_caddy_all_in_one_cookie_auth() {
	cd $REMNAWAVE_DIR/caddy

	create_docker_compose_cookie_auth

	create_Caddyfile_cookie_auth

	create_makefile "$REMNAWAVE_DIR/caddy"

	create_static_site "$REMNAWAVE_DIR/caddy"
}

# Including module: caddy-full-auth.sh

setup_caddy_all_in_one_full_auth() {
	cd $REMNAWAVE_DIR/caddy

	cat >Caddyfile <<"EOF"
{
    admin   off
    https_port {$HTTPS_PORT}
    default_bind 127.0.0.1
    servers {
        listener_wrappers {
            proxy_protocol {
                allow 127.0.0.1/32
            }
            tls
        }
    }
    auto_https disable_redirects
    order authenticate before respond
    order authorize before respond

    security {
        local identity store localdb {
            realm local
            path /data/.local/caddy/users.json
        }

        authentication portal remnawaveportal {
            crypto default token lifetime {$AUTH_TOKEN_LIFETIME}
            enable identity store localdb
            cookie domain {$REMNAWAVE_PANEL_DOMAIN}
            ui {
                links {
                    "Remnawave" "/dashboard/home" icon "las la-tachometer-alt"
                    "My Identity" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/whoami" icon "las la-user"
                    "API Keys" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/settings/apikeys" icon "las la-key"
                    "MFA" "/{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/settings/mfa" icon "lab la-keycdn"
                }
            }
            transform user {
                match origin local
                require mfa
                action add role authp/admin
            }
        }

        authorization policy panelpolicy {
            set auth url /restricted
            disable auth redirect
            allow roles authp/admin
            with api key auth portal remnawaveportal realm local

            acl rule {
                comment "Accept"
                match role authp/admin
                allow stop log info
            }
            acl rule {
                comment "Deny"
                match any
                deny log warn
            }
        }
    }
}

http://{$REMNAWAVE_PANEL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$REMNAWAVE_PANEL_DOMAIN}{uri} permanent
}

https://{$REMNAWAVE_PANEL_DOMAIN} {

    @login_path {
        path /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE} /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/ /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}/auth
    }
    handle @login_path {
        rewrite * /auth
        request_header +X-Forwarded-Prefix /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}
        authenticate with remnawaveportal
    }

    handle_path /restricted* {
        abort
    }

    route /api/* {
        authorize with panelpolicy
        reverse_proxy http://127.0.0.1:3000
    }

    route /{$REMNAWAVE_CUSTOM_LOGIN_ROUTE}* {
        authenticate with remnawaveportal
    }

    route /* {
        authorize with panelpolicy
        reverse_proxy http://127.0.0.1:3000
    }

    handle_errors {
        @unauth {
            expression {http.error.status_code} == 401
        }
        handle @unauth {
            respond * 204
        }
    }
}

http://{$CADDY_SELF_STEAL_DOMAIN} {
    bind 0.0.0.0
    redir https://{$CADDY_SELF_STEAL_DOMAIN}{uri} permanent
}

https://{$CADDY_SELF_STEAL_DOMAIN} {
    root * /var/www/html
    try_files {path} /index.html
    file_server
}

http://{$CADDY_SUB_DOMAIN} {
    bind 0.0.0.0
    redir https://{$CADDY_SUB_DOMAIN}{uri} permanent
}

https://{$CADDY_SUB_DOMAIN} {
    handle {
        reverse_proxy http://127.0.0.1:3010 {
            header_up X-Real-IP {remote}
            header_up Host {host}
        }
    }
    handle_errors {
        handle {
            respond * 204
        }
    }
}

:{$HTTPS_PORT} {
    tls internal
    respond 204
}

:80 {
    bind 0.0.0.0
    respond 204
}
EOF

	cat >docker-compose.yml <<EOF
services:
    remnawave-caddy:
        image: remnawave/caddy-with-auth:latest
        container_name: 'remnawave-caddy'
        hostname: remnawave-caddy
        restart: always
        environment:
            - AUTH_TOKEN_LIFETIME=3600
            - REMNAWAVE_PANEL_DOMAIN=$PANEL_DOMAIN
            - REMNAWAVE_CUSTOM_LOGIN_ROUTE=$CUSTOM_LOGIN_ROUTE
            - AUTHP_ADMIN_USER=$AUTHP_ADMIN_USER
            - AUTHP_ADMIN_EMAIL=$AUTHP_ADMIN_EMAIL
            - AUTHP_ADMIN_SECRET=$AUTHP_ADMIN_SECRET
            - HTTPS_PORT=$CADDY_LOCAL_PORT
            - CADDY_SELF_STEAL_DOMAIN=$SELF_STEAL_DOMAIN
            - CADDY_SUB_DOMAIN=$SUB_DOMAIN
        volumes:
            - ./Caddyfile:/etc/caddy/Caddyfile
            - ./html:/var/www/html
            - remnawave-caddy-ssl-data:/data
        network_mode: "host"

volumes:
    remnawave-caddy-ssl-data:
        driver: local
        external: false
        name: remnawave-caddy-ssl-data
EOF

    create_makefile "$REMNAWAVE_DIR/caddy"
    create_static_site "$REMNAWAVE_DIR/caddy"
}

# Including module: setup.sh


generate_secrets_all_in_one() {
    local auth_type=$1

    generate_secrets
    if [ "$auth_type" = "full" ]; then
        generate_full_auth_secrets
    else
        if [ "$auth_type" = "cookie" ]; then
            generate_cookie_auth_secrets
        fi
    fi
}

setup_caddy_all_in_one() {
    local auth_type=$1

    if [ "$auth_type" = "full" ]; then
        setup_caddy_all_in_one_full_auth
    else
        if [ "$auth_type" = "cookie" ]; then
            setup_caddy_all_in_one_cookie_auth
        fi
    fi
}

start_caddy_all_in_one() {
    local auth_type=$1

    if [ "$auth_type" = "full" ]; then
        start_caddy_full_auth
    else
        if [ "$auth_type" = "cookie" ]; then
            start_caddy_cookie_auth
        fi
    fi

}

save_credentials_all_in_one() {
    local auth_type=$1

    if [ "$auth_type" = "full" ]; then
        save_credentials_full_auth
    else
        if [ "$auth_type" = "cookie" ]; then
            save_credentials_cookie_auth
        fi
    fi
}

display_results_all_in_one() {
    local auth_type=$1

    if [ "$auth_type" = "full" ]; then
        display_full_auth_results "all-in-one"
    else
        if [ "$auth_type" = "cookie" ]; then
            display_cookie_auth_results "all-in-one"
        fi
    fi
}

collect_selfsteal_domain_for_all_in_one() {
    while true; do
        SELF_STEAL_DOMAIN=$(prompt_domain "$(t domain_selfsteal_prompt)" "$ORANGE" true false false)

        if check_domain_uniqueness "$SELF_STEAL_DOMAIN" "selfsteal" "$PANEL_DOMAIN" "$SUB_DOMAIN"; then
            break
        fi
        show_warning "$(t warning_enter_different_domain) selfsteal."
        echo
    done
}

install_remnawave_all_in_one() {
    local auth_type=$1

    if ! prepare_installation "qrencode"; then
        return 1
    fi

    generate_secrets_all_in_one $auth_type

    collect_telegram_config
    collect_domain_config
    collect_selfsteal_domain_for_all_in_one

    if [ "$auth_type" = "full" ]; then
        collect_full_auth_config
    fi

    collect_ports_all_in_one

    allow_ufw_node_port_from_panel

    setup_panel_docker_compose

    setup_panel_environment

    create_makefile "$REMNAWAVE_DIR"

    setup_caddy_all_in_one $auth_type

    setup_remnawave-subscription-page

    start_services

    start_caddy_all_in_one $auth_type

    register_panel_user
    configure_vless_all_in_one

    setup_and_start_all_in_one_node

    save_credentials_all_in_one $auth_type

    display_results_all_in_one $auth_type
}


if [ "$(id -u)" -ne 0 ]; then
    echo "$(t error_root_required)"
    exit 1
fi

clear


show_main_menu() {
    clear
    echo -e "${BOLD_GREEN}$(t main_menu_title)${VERSION}${NC}"
    echo -e "${GREEN}$(t main_menu_script_branch)${NC} ${BLUE}$INSTALLER_BRANCH${NC} | ${GREEN}$(t main_menu_panel_branch)${NC} ${BLUE}$REMNAWAVE_BRANCH${NC}"
    echo
    echo -e "${GREEN}1.${NC} $(t main_menu_install_components)"
    echo
    echo -e "${GREEN}2.${NC} $(t main_menu_update_components)"
    echo -e "${GREEN}3.${NC} $(t main_menu_restart_panel)"
    echo -e "${GREEN}4.${NC} $(t main_menu_remove_panel)"
    echo -e "${GREEN}5.${NC} $(t main_menu_rescue_cli)"
    echo -e "${GREEN}6.${NC} $(t main_menu_show_credentials)"
    echo
    echo -e "${GREEN}7.${NC} $(get_bbr_menu_text)"
    echo -e "${GREEN}8.${NC} $(t main_menu_warp_integration)"
    echo
    echo -e "${GREEN}0.${NC} $(t main_menu_exit)"
    echo
    echo -ne "${BOLD_BLUE_MENU}$(t main_menu_select_option) ${NC}"
}

show_installation_menu() {
    clear
    echo -e "${BOLD_GREEN}$(t install_menu_title)${NC}"
    echo
    echo -e "${YELLOW}$(t install_menu_panel_only)${NC}"
    echo -e "${GREEN}1.${NC} $(t install_menu_panel_full_security)"
    echo -e "${GREEN}2.${NC} $(t install_menu_panel_simple_security)"
    echo
    echo -e "${YELLOW}$(t install_menu_node_only)${NC}"
    echo -e "${GREEN}3.${NC} $(t install_menu_node_separate)"
    echo
    echo -e "${YELLOW}$(t install_menu_all_in_one)${NC}"
    echo -e "${GREEN}4.${NC} $(t install_menu_panel_node_full)"
    echo -e "${GREEN}5.${NC} $(t install_menu_panel_node_simple)"
    echo
    echo -e "${GREEN}0.${NC} $(t install_menu_back)"
    echo
    echo -ne "${BOLD_BLUE_MENU}$(t main_menu_select_option) ${NC}"
}

handle_installation_menu() {
    while true; do
        show_installation_menu
        read choice

        case $choice in
        1)
            install_panel_only "full"
            ;;
        2)
            install_panel_only "cookie"
            ;;
        3)
            setup_node
            ;;
        4)
            install_remnawave_all_in_one "full"
            ;;
        5)
            install_remnawave_all_in_one "cookie"
            ;;
        0)
            return
            ;;
        *)
            clear
            echo -e "${BOLD_RED}$(t error_invalid_choice)${NC}"
            sleep 1
            ;;
        esac
    done
}

main() {
    while true; do
        show_main_menu
        read choice

        case $choice in
        1)
            handle_installation_menu
            ;;
        2)
            handle_update_menu
            ;;
        3)
            restart_panel
            ;;
        4)
            remove_previous_installation true
            ;;
        5)
            run_remnawave_cli
            ;;
        6)
            show_panel_credentials
            ;;
        7)
            toggle_bbr
            ;;
        8)
            add_warp_docker_integration
            ;;
        0)
            echo "$(t exiting)"
            break
            ;;
        *)
            clear
            echo -e "${BOLD_RED}$(t error_invalid_choice)${NC}"
            sleep 1
            ;;
        esac
    done
}

main
