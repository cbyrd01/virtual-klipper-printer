#!/usr/bin/env bash

#=======================================================================#
# Copyright (C) 2022 mainsail-crew <https://github.com/mainsail-crew>   #
# Author: Dominik Willner <th33xitus@gmail.com>                         #
#                                                                       #
# This file is part of virtual-klipper-printer                          #
# https://github.com/mainsail-crew/virtual-klipper-printer              #
#                                                                       #
# This file may be distributed under the terms of the GNU GPLv3 license #
#=======================================================================#

set -e

REQUIRED_FOLDERS=(
  "${HOME}/printer_data"
  "${HOME}/printer_data/config"
  "${HOME}/printer_data/logs"
  "${HOME}/printer_data/gcodes"
  "${HOME}/printer_data/webcam_images"
  "${HOME}/printer_data/timelapse"
  "${HOME}/printer_data/database"
)

function status_msg() {
  echo "###[$(date +%T)]: ${1}"
}

######
# Test if all requierd folders exist if not create them and
# test for correct ownership of all required folders
###
function check_folder_perms_and_create() {
  status_msg "Check folders permissions ..."
  for folder in "${REQUIRED_FOLDERS[@]}"; do

    if [ ! -d "$folder" ]; then
        mkdir "$folder"
    fi

    if [[ $(stat -c "%U" "${folder}") != "printer" ]]; then
      status_msg "chown for user: 'printer' on folder: ${folder}"
      sudo chown printer:printer "${folder}"
    fi
  done
  status_msg "OK!"
}

######
# Copy example configs if ~/printer_data/config is empty
###
function copy_example_configs() {
  if [[ ! "$(ls -A "${HOME}/printer_data/config")" ]]; then
    status_msg "Directory ${HOME}/printer_data/config is empty!"
    status_msg "Copy example configs ..."
    cp -R ~/example-configs/* ~/printer_data/config
    status_msg "OK!"
  fi
}

######
# Copy dummy images if ~/webcam_images is empty
###
function copy_dummy_images() {
  if [[ ! "$(ls -A "${HOME}/printer_data/webcam_images")" ]]; then
    status_msg "Directory ${HOME}/printer_data/webcam_images is empty!"
    status_msg "Copy dummy images ..."
    cp -R ~/mjpg_streamer_images/*.jpg ~/printer_data/webcam_images
    status_msg "OK!"
  fi
}

######
# Link moonraker-timelapse component to moonraker components
###
function link_timelapse() {
  local component_source="${HOME}/moonraker-timelapse/component/timelapse.py"
  local component_target="${HOME}/moonraker/moonraker/components/timelapse.py"
  local macro_source="${HOME}/moonraker-timelapse/klipper_macro/timelapse.cfg"
  local macro_target="${HOME}/printer_data/config/addons/timelapse.cfg"

  if [[ -f ${component_source} && ! -h ${component_target} ]]; then
    status_msg "Linking moonraker-timelapse component ..."
    ln -sf "${component_source}" "${component_target}"
    status_msg "OK!"
  fi

  if [[ -f ${macro_source} && ! -h ${macro_target} ]]; then
    status_msg "Linking timelapse.cfg ..."
    ln -sf "${macro_source}" "${macro_target}"
    status_msg "OK!"
  fi
}

######
# Setup Mainsail based on INCLUDE_MAINSAIL environment variable
###
function setup_mainsail() {
  case "${INCLUDE_MAINSAIL:-none}" in
    "release")
      status_msg "Setting up Mainsail (release mode) ..."
      if [[ -d "${HOME}/mainsail-release" && "$(ls -A "${HOME}/mainsail-release")" ]]; then
        rm -rf "${HOME}/mainsail" 2>/dev/null || true
        cp -r "${HOME}/mainsail-release" "${HOME}/mainsail"
        setup_nginx
        status_msg "Mainsail (release) setup complete!"
      else
        status_msg "Warning: Mainsail release files not found, skipping..."
      fi
      ;;
    "dev")
      status_msg "Setting up Mainsail (development mode) ..."
      if [[ -d "/home/printer/mainsail-dev-local" && "$(ls -A "/home/printer/mainsail-dev-local")" ]]; then
        # Use mounted local development directory
        rm -rf "${HOME}/mainsail" 2>/dev/null || true
        # Check if it's a built Mainsail (has dist directory) or source
        if [[ -d "/home/printer/mainsail-dev-local/dist" && "$(ls -A "/home/printer/mainsail-dev-local/dist")" ]]; then
          status_msg "Found Mainsail dist directory, using built files..."
          ln -sf "/home/printer/mainsail-dev-local/dist" "${HOME}/mainsail"
        else
          status_msg "Using local Mainsail directory directly..."
          ln -sf "/home/printer/mainsail-dev-local" "${HOME}/mainsail"
        fi
        setup_nginx
        status_msg "Mainsail (local dev) setup complete!"
      elif [[ -d "${HOME}/mainsail-dev" && "$(ls -A "${HOME}/mainsail-dev")" ]]; then
        # Use built Mainsail from container build
        rm -rf "${HOME}/mainsail" 2>/dev/null || true
        cp -r "${HOME}/mainsail-dev" "${HOME}/mainsail"
        setup_nginx
        status_msg "Mainsail (dev build) setup complete!"
      else
        status_msg "Warning: Mainsail development files not found, skipping..."
      fi
      ;;
    "none"|*)
      status_msg "Mainsail integration disabled"
      ;;
  esac
}

######
# Setup nginx configuration and enable the service
###
function setup_nginx() {
  status_msg "Configuring nginx for Mainsail ..."
  cp "${HOME}/config/nginx.conf" "${HOME}/nginx.conf"
  # Enable nginx in supervisord
  sudo sed -i 's/autostart=false/autostart=true/' /etc/supervisor/supervisord.conf
  status_msg "Nginx configured!"
}

#===================================================#
#===================================================#

[[ ! -e /bin/systemctl ]] && sudo -S ln -s /bin/true /bin/systemctl

check_folder_perms_and_create
copy_example_configs
copy_dummy_images
link_timelapse
setup_mainsail

sudo -S rm /bin/systemctl
sudo -S ln -s /bin/service_control /bin/systemctl

cd ~ && status_msg "Everything is ready! Starting ..."
/usr/bin/supervisord
