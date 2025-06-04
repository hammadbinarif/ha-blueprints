# 🔔 Doorbell & Camera Utilities for Home Assistant

This repository provides Home Assistant automation blueprints and complementary shell scripts, designed to enhance your doorbell camera setup. It integrates AI analysis (via Google Gemini) for doorbell snapshots and includes automated cleanup of old camera files. 

![Demo](/demo/doorbell_notfications_demo.gif)

---

## ✨ Features

* **Doorbell Snapshot & Gemini Description Blueprint:**
    * Automatically captures a snapshot from your doorbell camera when a person is detected or the doorbell is pressed.
    * Sends the snapshot to Google Gemini for AI analysis and description generation.
    * Stores the image path, Gemini's description, and a timestamp in a JSON file, ideal for use with the [Photo Carousel Card](https://github.com/hammadbinarif/photo-carousel-card).
    * Optionally triggers a follow-up notification automation.

* **Doorbell Notification Blueprint:**
    * A dedicated blueprint to create automations that send rich notifications (e.g., to your mobile app) with the doorbell snapshot and Gemini's description.
    * Designed to be triggered by the "Doorbell Snapshot & Gemini Description Blueprint."

* **Clean Old Camera Snapshots Automation:**
    * Automatically deletes old camera snapshots from a specified directory to manage disk space.
    * Configured to run on a time pattern (e.g., daily).

---

## ⚙️ Prerequisites

Before you begin, ensure you have the following set up in your Home Assistant:

1.  **Google Generative AI Conversation Integration:**
    * Install and configure the `Google Generative AI Conversation` integration in Home Assistant. This is required for the AI analysis feature of the blueprint.
    * You will need to obtain an API key for Google Gemini.

2.  **`jq` (JSON processor):**
    * The `update_doorbell_events.sh` script relies on `jq` for JSON manipulation.
    * You need to install `jq` on your Home Assistant server's operating system.
        * **Home Assistant OS/Supervised (via SSH Add-on):**
            ```bash
            apk add jq # For Alpine Linux based OS (HA OS, Supervised)
            ```
        * **Home Assistant Container (Docker):** You might need to build a custom container image that includes `jq`, or execute `apk add jq` inside the container if you have shell access.
        * **Home Assistant Core (on Debian/Ubuntu):**
            ```bash
            sudo apt-get update && sudo apt-get install jq
            ```

---

## 📦 Installation

This repository contains:
* Three **Blueprints** (for doorbell snapshot/AI analysis and notifications and for old photos cleanup).
* **Shell Scripts** (for updating the JSON and managing directories).

### 🛠️ Step 1: Manual Setup for Shell Scripts and Directories (REQUIRED!)

The blueprints and automation rely on specific shell commands and directories. These **MUST be set up manually** on your Home Assistant server.

1.  **Create Script and Data Directories:**
    Connect to your Home Assistant server via SSH (e.g., using the SSH & Web Terminal add-on) and run these commands:
    ```bash
    mkdir -p /config/scripts/
    mkdir -p /config/www/camera_snapshots/
    mkdir -p /config/www/doorbell/
    ```

2.  **Download Shell Script:**
    Download the `update_doorbell_events.sh` script from this repository:
    * [Download `update_doorbell_events.sh`](https://raw.githubusercontent.com/hammadbinarif/ha-blueprints/main/scripts/update_doorbell_events.sh) (Right-click and "Save Link As..." or copy raw content)
    Place this downloaded file into the `/config/scripts/` directory you created.

3.  **Make Script Executable:**
    In your SSH terminal, make the script executable:
    ```bash
    chmod +x /config/scripts/update_doorbell_events.sh
    ```

4.  **Configure `shell_command`s in `configuration.yaml`:**
    Add the following to your Home Assistant `configuration.yaml` file. If you already have a `shell_command:` section, just add the entries under it.

    ```yaml
    # configuration.yaml
    shell_command:
      # Command to delete snapshots older than 30 days
      clean_camera_snapshots: "find /config/www/camera_snapshots/ -type f -mtime +30 -delete"
      # Command to create the camera snapshots directory (blueprint uses this)
      create_camera_snapshots_dir: "mkdir -p /config/www/camera_snapshots"
      # Command to create the doorbell JSON directory
      create_doorbell_dir: "mkdir -p /config/www/doorbell"
      # Command to update the doorbell events JSON file
      update_doorbell_events_json: >
        /config/scripts/update_doorbell_events.sh "{{ img_path_for_card }}" "{{ description_clean }}" "{{ timestamp_iso }}" "{{ max_items_to_store | default(100) }}"
    ```

5.  **Restart Home Assistant:**
    Go to **Settings** > **System** > **Restart Home Assistant** to apply the `configuration.yaml` changes.

### 🛠️ Step 2: Installation for Home Assistant Blueprints (Recommended)

### 🔔 Doorbell Gemini Notification
Sends a notification using image + AI-generated description.

[![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fhammadbinarif%2Fha-blueprints%2Fblob%2Fmain%2Fdoorbell_notification.yaml)

### 📸 Doorbell Event AI Analysis
Automatically captures a snapshot, analyzes it with Gemini AI, and stores results and optionally sends a notification.

[![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fhammadbinarif%2Fha-blueprints%2Fblob%2Fmain%2Fdoorbell_ai_analysis.yaml)

### 📸 Clean Old Camera Snapshots
This automation runs daily to clean older images. This ensures your snapshot directory doesn't grow indefinitely.

[![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fhammadbinarif%2Fha-blueprints%2Fblob%2Fmain%2Fclean_old_camera_snapshots.yaml)

---

## 🚀 Usage


### 1. Doorbell Notification Blueprint

This blueprint helps you create an automation to send notifications with the doorbell snapshot and description. It's designed to be triggered by the "Doorbell Snapshot & Gemini Description Blueprint".

1.  Go to **Settings** > **Automations & Scenes** > **Scripts**.
2.  Find the "Doorbell Gemeni Notification" and click **"Create Script"**.
3.  **Configure the inputs:**
    * **Notification Service:** Select the mobile app device to send notifications to (e.g., `notify.mobile_app_your_phone`).
    * **Notification Title:** Customize the title of the notification (e.g., `Doorbell Alert!`).
4.  Give your automation a name (e.g., `Doorbell Mobile Notification`) and save it. **Remember this name, as you'll select it in the next blueprint.**

### 2. Doorbell Snapshot & Gemini Description Blueprint

This blueprint creates an automation that captures, analyzes, and logs doorbell events.

1.  Go to **Settings** > **Automations & Scenes** > **Blueprints**.
2.  Find the "Doorbell Snapshot & Gemini Description" blueprint and click **"Create Automation"**.
3.  **Configure the inputs:**
    * **Person Detection Binary Sensor:** Select your camera's person detection entity (e.g., `binary_sensor.reolink_video_doorbell_wifi_person`).
    * **Doorbell Press Binary Sensor:** Select your doorbell's visitor/button press entity (e.g., `binary_sensor.reolink_video_doorbell_wifi_visitor`).
    * **Camera Entity:** Select the camera entity for snapshots (e.g., `camera.reolink_video_doorbell_wifi_fluent`).
    * **Shell Command - Update JSON:** Select `shell_command.update_doorbell_events_json`.
    * **Shell Command - Create Snapshot Directory:** Select `shell_command.create_camera_snapshots_dir`.
    * **Snapshot Folder (Absolute Path):** Keep the default `/config/www/camera_snapshots` or specify your custom path (must be allowed in `allowlist_external_dirs`).
    * **Max Doorbell Events to Store:** (Optional) Set the maximum number of entries in `doorbell_events.json`. Default is 100.
    * **Call Notification Script?:** (Optional) Enable if you want to trigger another script for notifications.
    * **Notification Script (optional):** **Select the script you create from the "Doorbell Gemeni Notification" here.** (e.g., `script.doorbell_mobile_notification`). This script should accept `description` and `image_path` variables.
    * **AI Prompt:** Customize the prompt sent to Gemini for image analysis.

4.  Give your automation a name and save it.

### 3. Clean Old Camera Snapshots Automation

This automation ensures your snapshot directory doesn't grow indefinitely.

1.  Go to **Settings** > **Automations & Scenes** > **Blueprints**.
2.  Find the "Clean Old Camera Snapshots" blueprint and click **"Create Automation"**.
3.  **Review and Enable:**
    * By default, it's configured to run daily at 3 AM.
    * It calls the `shell_command.clean_camera_snapshots` which deletes `.jpg` files older than 30 days from `/config/www/camera_snapshots/`.
    * You can modify the trigger time or the `find` command in `configuration.yaml` if you need different retention periods or paths.

---

## 🤝 Integration with Photo Carousel Card

This blueprint and the generated `doorbell_events.json` file work perfectly with the **Photo Carousel Card**. You can install the card via HACS from:

* **[Photo Carousel Card GitHub Repository](https://github.com/hammadbinarif/photo-carousel-card)**

[![Open your Home Assistant instance and open a repository inside the Home Assistant Community Store.](https://my.home-assistant.io/badges/hacs_repository.svg)](https://my.home-assistant.io/redirect/hacs_repository/?repository=photo-carousel-card&category=plugin&owner=hammadbinarif)

Once installed, configure the Photo Carousel Card to use your generated JSON file:

```yaml
type: custom:photo-carousel-card
title: Doorbell Events
description_file_path: /local/doorbell/doorbell_events.json # This path maps to /config/www/doorbell/doorbell_events.json
autoplay: 10000
reload_interval_minutes: 1
max_items_to_show: 15
max_days_to_show: 7 # Filter photos based on the timestamp generated by the blueprint
# Add any other styling options as desired
```

## ❓ Troubleshooting

* **Automation fails with "No access to path" error:**
    * Ensure `/config/www/camera_snapshots` (and any other custom paths used) are explicitly listed under `homeassistant: allowlist_external_dirs:` in your `configuration.yaml`.
    * Restart Home Assistant after modifying `configuration.yaml`.
    * Verify the `camera.snapshot` service call in the automation trace to see the exact path it's trying to write to.
* **`update_doorbell_events.sh` script fails:**
    * Ensure `jq` is installed on your Home Assistant server.
    * Verify the script path in `shell_command.update_doorbell_events_json` is correct (`/config/scripts/update_doorbell_events.sh`).
    * Check script permissions: `chmod +x /config/scripts/update_doorbell_events.sh`.
    * Look for errors in your Home Assistant logs (**Settings** > **System** > **Logs**) related to `shell_command` or the script's output.
---

## 🙌 Contributing

PRs, issues, and suggestions are welcome! Feel free to open an issue on GitHub for any bugs or feature requests.

---

## 📃 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
