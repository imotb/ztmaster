# 🌑 Zero-UI & Moon Server Stack Installer
Self-hosted Zerotier controller + beautiful Web-UI + optional Moon Server relay in < 5 min.

[![Docker](https://img.shields.io/badge/Docker-20.10+-2496ED?logo=docker)](https://www.docker.com/) [![Traefik](https://img.shields.io/badge/Reverse%20Proxy-Traefik-24a1c1?logo=traefikproxy)](https://traefik.io/) [![SSL](https://img.shields.io/badge/SSL-LetsEncrypt-003A70?logo=lets-encrypt)](https://letsencrypt.org/) [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📦 About

A powerful, all-in-one bash script to effortlessly deploy a Zero-UI User Portal (for managing Zerotier networks) alongside a Traefik reverse proxy and an optional monitoring stack, or to configure a Zerotier Moon server for improved latency and reliability.
Designed for system administrators and DevOps enthusiasts, this script automates complex setups with an intuitive interface, rich terminal output, and robust error handling.

---

## ✨ Features

- **🌐 Zero-UI Stack Deployment:** Fully automated installation of the official Zero-UI container and its Zerotier controller.
- **🔒 Automatic SSL:** Integrated Traefik with Let's Encrypt for automatic HTTPS on all your domains.
- **📊 Monitoring Options:** Choose your preferred monitoring tool: Netdata, cAdvisor, or Dozzle.
- **🌙 Moon Server Setup:** Easily configure a Zerotier Moon server on any VPS to act as a stable relay for your network.
- **🔐 Secure by Default:** Generates strong, random passwords for all web interfaces and securely extracts the Zerotier controller token.
- **🎨 Rich User Interface:** Beautiful ANSI-colored output with spinners and status indicators for a clear installation experience.
- **🤝 Docker-Powered:** Everything runs in isolated Docker containers for easy management and cleanup.

---

## 🧩 Prerequisites

Before you begin, ensure you have:

- A fresh Ubuntu/Debian-based server (Recommended: **Ubuntu 22.04 LTS**).
- **Root** or `sudo` privileges.
- A domain name (or **subdomains**) pointed to your server's IP address **for the web interfaces** (e.g., traefik.yourdomain.com, zerotier.yourdomain.com).
- Your server's public static IP address (For Moon).
- Ports 80 & 443 open.

---

## 🚀 Quick Start

#### Download & run the script:
```bash
wget -O zero-ui-installer.sh https://raw.githubusercontent.com/imotb/ztmaster/main/ztmaster.sh
chmod +x zero-ui-installer.sh
./zero-ui-installer.sh
```

#### Follow the intuitive menu:
- Choose `1` to install the full Zero-UI stack.
- Choose `2` to set up a Zerotier Moon server.

---

## ⚙️ Detailed Usage

### Option 1: Install Zero-UI Server Stack
This option sets up a complete production-ready stack:

1. **Traefik:** Reverse proxy and load balancer with a secure dashboard.
2. **Zerotier Controller:** The brain of your software-defined network.
3. **Zero-UI:** A beautiful web UI for managing your Zerotier networks and members.
4. **(Optional) A Monitoring Tool:** Keep an eye on your server's health.

The script will guide you through entering your email for SSL certificates, choosing a monitoring tool, and setting domains. It handles everything else, including:

- Installing Docker and dependencies.
- Generating secure random passwords.
- Extracting the Zerotier controller token securely.
- Creating and launching the `docker-compose.yml` file.

#### Post-Installation:
A summary file (zero_ui_summary.txt) is created with all your access URLs and credentials. **Save this information immediately!**


### Option 2: Install and Configure a Zerotier Moon Server

A Moon provides a stable, user-defined anchor point for your Zerotier network, improving connectivity and reducing latency between clients, especially in regions where connection to Zerotier's public planetary roots might be unstable.

The script will:
- Install the Zerotier-One client.
- Generate a Moon configuration file (`moon.json`) bound to your server's public IP.
- Sign the configuration and place it in the correct directory.
- Restart the Zerotier service.

#### Post-Installation:
A detailed summary file (`moon_server_summary.txt`) is created with your Moon ID and clear, copy-paste instructions on how to join other clients (and your Zero-UI controller) to this Moon.


### Option 3: Restart Services
Quickly restart all Docker containers defined in the `/opt/zero-ui-stack/docker-compose.yml` file. Useful if you've made changes or need to reboot services.

---

## 🏗️ Project Structure

```bash
/opt/zero-ui-stack/
├── docker-compose.yml  # The main compose file defining all services
├── zero_ui_summary.txt # Your access details and passwords (IMPORTANT!)
│
└── (Docker Volumes)
    ├── traefik-letsencrypt/ # SSL certificates
    ├── traefik-logs/        # Traefik access logs
    ├── zero-ui-data/        # Zero-UI application data
    └── zerotier-data/       # Zerotier controller data and identity
```

---

## 🛠 Management & Commands

- **View Logs:** `docker compose logs` (inside `/opt/zero-ui-stack`)
- **Restart Services:** Use `Option 3` in the script or run `docker compose restart`.
- **Update Containers:** `docker compose pull && docker compose up -d`
- **Backup:** Backup the `/opt/zero-ui-stack` directory and all Docker volumes.

---

## ⚠️ Important Notes & Security

- **🔐 Passwords:** The script generates strong passwords. They are displayed only once on the screen and **saved in the summary text file.** Please store them securely.
- **🌐 Cloudflare:** It is **highly recommended** to place your Traefik and Zero-UI domains behind Cloudflare proxy (the orange cloud) to hide your server's IP and add an **extra layer of security and DDoS protection.**
- **🌙 Moon Firewall:** If you set up a Moon, ensure your server's firewall **allows UDP traffic on port 9993.**
- **Permissions:** This script must be run as `root`.

---

## 📜 License
This project is licensed under the [MIT License](https://raw.githubusercontent.com/imotb/ztmaster/refs/heads/main/LICENSE).


## 🙏 Acknowledgments
- [Zero-UI](https://github.com/styliteag/zero-ui-userportal) by @styliteag
- [Zerotier](https://www.zerotier.com) for the amazing software-defined networking
- [Traefik](https://traefik.io) for the awesome reverse proxy and load balancer





