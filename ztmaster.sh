#!/bin/bash

# --- ANSI Color Codes for Rich Output ---
RED='\033[0;31m'
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;95m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
CHECK="✅"
CROSS="❌"


# --- Dynamic Output Functions ---

# Function to show a spinner for long-running commands
spinner() {
    local command_to_run="$1"
    local message="$2"
    local pid
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    echo -ne "${YELLOW} • ${message}... ${NC}"

    # Run the command in the background and capture its PID
    eval "$command_to_run" &> /tmp/spinner.log &
    pid=$!

    # Animate the spinner
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        echo -ne "\r${YELLOW} • ${message}... ${spin:$i:1}${NC}"
        sleep 0.1
    done

    # Wait for the command to finish and get its exit code
    wait $pid
    local exit_code=$?

    # Print the final status
    if [ $exit_code -eq 0 ]; then
        echo -e "\r${GREEN}${CHECK} ${message}... Done.${NC}   "
    else
        echo -e "\r${RED}${CROSS} ${message}... Failed.${NC}  "
        echo -e "${RED}Error details can be found in /tmp/spinner.log${NC}"
        exit 1
    fi
}


# --- Function to check for root privileges ---
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}${BOLD}ERROR:${NC} This script must be run with root privileges. Please use sudo."
    exit 1
fi

# --- Store the initial directory ---
SCRIPT_DIR=$(pwd)

# --- Welcome Banner ---
clear
echo -e "${BLUE}${BOLD}"
cat << "EOF"
   ▄▄▄▄▄▄▄▄
   ▀▀▀▀▀███
       ██▀    ▄████▄    ██▄████   ▄████▄
     ▄██▀    ██▄▄▄▄██   ██▀      ██▀  ▀██
    ▄██      ██▀▀▀▀▀▀   ██       ██    ██
   ███▄▄▄▄▄  ▀██▄▄▄▄█   ██       ▀██▄▄██▀
   ▀▀▀▀▀▀▀▀    ▀▀▀▀▀    ▀▀         ▀▀▀▀

   ▄▄▄  ▄▄▄
   ███  ███                        ██
   ████████   ▄█████▄  ▄▄█████▄  ███████    ▄████▄    ██▄████
   ██ ██ ██   ▀ ▄▄▄██  ██▄▄▄▄ ▀    ██      ██▄▄▄▄██   ██▀
   ██ ▀▀ ██  ▄██▀▀▀██   ▀▀▀▀██▄    ██      ██▀▀▀▀▀▀   ██
   ██    ██  ██▄▄▄███  █▄▄▄▄▄██    ██▄▄▄   ▀██▄▄▄▄█   ██
   ▀▀    ▀▀   ▀▀▀▀ ▀▀   ▀▀▀▀▀▀      ▀▀▀▀     ▀▀▀▀▀    ▀▀
EOF
echo -e "${NC}"
echo -e "${GREEN}${BOLD}  Zero-UI & Moon Server Stack Installer${NC}"
echo -e "${YELLOW}  https://github.com/imotb${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# --- Main Menu ---
echo -e "${PURPLE}Please select an option:${NC}"
echo -e " ${GREEN}1)${NC} Install Zero-UI Server Stack"
echo -e " ${GREEN}2)${NC} Install and Configure a Zerotier Moon Server"
echo -e " ${GREEN}3)${NC} Restart Zero-UI Services (Containers)"
echo -e " ${GREEN}4)${NC} Exit"
read -p "Enter your choice (1-4): " option

case $option in
    1)
        # --- Zero-UI Installation ---
        echo -e "\n${BLUE}--- Starting Zero-UI Stack Installation ---${NC}"

        # 1. Install prerequisites
        echo -e "\n${CYAN}${BOLD}=> Step 1: Installing Prerequisites${NC}"
        spinner "apt-get update" "Updating package lists"
        spinner "apt-get install -y curl git apache2-utils net-tools" "Installing required utilities"
        spinner "curl -fsSL https://get.docker.com | sh" "Installing Docker"
        mkdir -p /opt/zero-ui-stack && cd /opt/zero-ui-stack || exit
        echo -e "${GREEN}${CHECK} Prerequisites installed successfully.${NC}"

        # 2. Get user inputs
        echo -e "\n${CYAN}${BOLD}=> Step 2: Gathering Information${NC}"
        read -p " • Enter your email (for SSL certificate): " email
        echo -e " • Select a monitoring tool:"
        echo -e "   ${GREEN}1)${NC} Netdata"
        echo -e "   ${GREEN}2)${NC} cAdvisor"
        echo -e "   ${GREEN}3)${NC} Dozzle"
        read -p "   Your choice (1, 2, or 3): " monitor_choice
        read -p " • Enter Traefik domain (e.g., traefik.example.com): " traefik_domain
        read -p " • Enter Zero-UI domain (e.g., zeroui.example.com): " zero_ui_domain

        # 3. Generate credentials
        echo -e "\n${CYAN}${BOLD}=> Step 3: Generating Secure Credentials${NC}"
        traefik_password=$(openssl rand -base64 16)
        zero_ui_password=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16) # 16-char alphanumeric
        htpasswd_line=$(htpasswd -nb admin "$traefik_password" | sed -e 's/\$/\$\$/g')
        echo -e "${GREEN} ${CHECK} Secure password for ${BOLD}Traefik${NC}${GREEN} has been generated.${NC}"
        echo -e "${GREEN} ${CHECK} Secure password for ${BOLD}Zero-UI${NC}${GREEN} has been generated.${NC}"
        echo -e "${YELLOW}   Please save these passwords securely!${NC}"

        # 4. Extract Zerotier token
        echo -e "\n${CYAN}${BOLD}=> Step 4: Extracting Zerotier Controller Token${NC}"
        cat > /tmp/zerotier-temp.yml <<EOF
services:
  zerotier-controller:
    image: zyclonite/zerotier:1.10.2
    container_name: zt-temp
    volumes:
      - zt-data-temp:/var/lib/zerotier-one
volumes:
  zt-data-temp:
EOF
        spinner "docker compose -f /tmp/zerotier-temp.yml up -d" "Starting temporary container"
        echo -ne "${YELLOW} • Waiting for token generation... ${NC}"; sleep 2; echo -ne "."; sleep 2; echo -ne "."; sleep 2; echo -e ".${NC}"
        token=$(docker exec zt-temp cat /var/lib/zerotier-one/authtoken.secret)
        spinner "docker compose -f /tmp/zerotier-temp.yml down --volumes" "Cleaning up temporary container"
        rm /tmp/zerotier-temp.yml
        echo -e "${GREEN}${CHECK} Token extracted successfully.${NC}"

        # 5. Create final docker-compose.yml
        echo -e "\n${CYAN}${BOLD}=> Step 5: Creating the final docker-compose.yml file${NC}"
        cat > docker-compose.yml <<EOF
services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--api.insecure=false"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=$email"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
      - "--accesslog=true"
      - "--accesslog.filepath=/var/log/traefik/access.log"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "traefik-letsencrypt:/letsencrypt"
      - "traefik-logs:/var/log/traefik"
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(\`$traefik_domain\`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=myresolver"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.middlewares=auth-traefik"
      - "traefik.http.middlewares.auth-traefik.basicauth.users=$htpasswd_line"

  zerotier-controller:
    image: zyclonite/zerotier:1.10.2
    container_name: zerotier-controller
    restart: unless-stopped
    entrypoint: >
      /bin/sh -c "
      /usr/sbin/zerotier-one -d && 
      sleep 5 && 
      echo '{\"settings\":{\"primaryPort\":9993,\"portMappingEnabled\":true,\"softwareUpdate\":\"disable\",\"allowManagementFrom\":[\"0.0.0.0/0\"],\"allowTcpFallbackRelay\":true}}' > /var/lib/zerotier-one/local.conf && 
      kill -HUP \$\$(cat /var/lib/zerotier-one/zerotier-one.pid) && 
      tail -f /dev/null
      "
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    volumes:
      - "zerotier-data:/var/lib/zerotier-one"
    ports:
      - "9993:9993/udp"
      - "9993:9993/tcp"
    networks:
      - traefik-network
    labels:
      - "traefik.enable=false"

  zero-ui:
    image: ghcr.io/styliteag/zero-ui-userportal:latest
    container_name: zero-ui
    restart: unless-stopped
    depends_on:
      - zerotier-controller
    environment:
      - ZU_DEFAULT_USERNAME=admin
      - ZU_DEFAULT_PASSWORD=$zero_ui_password
      - ZU_CONTROLLER_ENDPOINT=http://zerotier-controller:9993/
      - ZU_CONTROLLER_TOKEN=$token
    expose:
      - "80"
    volumes:
      - "zero-ui-data:/app/data"
      - "zerotier-data:/var/lib/zerotier-one:ro"
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.zero-ui.rule=Host(\`$zero_ui_domain\`)"
      - "traefik.http.routers.zero-ui.entrypoints=websecure"
      - "traefik.http.routers.zero-ui.tls.certresolver=myresolver"
      - "traefik.http.services.zero-ui.loadbalancer.server.port=80"
EOF
        # Add monitoring service
        case $monitor_choice in
            1)
                read -p " • Enter Netdata domain (e.g., netdata.example.com): " monitor_domain
                cat >> docker-compose.yml <<EOF

  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    restart: unless-stopped
    volumes:
      - "/proc:/host/proc:ro"
      - "/sys:/host/sys:ro"
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.netdata.rule=Host(\`$monitor_domain\`)"
      - "traefik.http.routers.netdata.entrypoints=websecure"
      - "traefik.http.routers.netdata.tls.certresolver=myresolver"
      - "traefik.http.services.netdata.loadbalancer.server.port=19999"
      - "traefik.http.routers.netdata.middlewares=auth-traefik"
EOF
                ;;
            2)
                read -p " • Enter cAdvisor domain (e.g., cadvisor.example.com): " monitor_domain
                cat >> docker-compose.yml <<EOF

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.cadvisor.rule=Host(\`$monitor_domain\`)"
      - "traefik.http.routers.cadvisor.entrypoints=websecure"
      - "traefik.http.routers.cadvisor.tls.certresolver=myresolver"
      - "traefik.http.services.cadvisor.loadbalancer.server.port=8080"
      - "traefik.http.routers.cadvisor.middlewares=auth-traefik"
EOF
                ;;
            3)
                read -p " • Enter Dozzle domain (e.g., dozzle.example.com): " monitor_domain
                cat >> docker-compose.yml <<EOF

  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    restart: unless-stopped
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dozzle.rule=Host(\`$monitor_domain\`)"
      - "traefik.http.routers.dozzle.entrypoints=websecure"
      - "traefik.http.routers.dozzle.tls.certresolver=myresolver"
      - "traefik.http.services.dozzle.loadbalancer.server.port=8080"
      - "traefik.http.routers.dozzle.middlewares=auth-traefik"
EOF
                ;;
        esac
        # Final part of docker-compose
        cat >> docker-compose.yml <<EOF

volumes:
  traefik-logs:
    driver: local
  zero-ui-data:
    driver: local
  zerotier-data:
    driver: local
  traefik-letsencrypt:
    driver: local

networks:
  traefik-network:
    driver: bridge
EOF
        echo -e "${GREEN}${CHECK} docker-compose.yml file created successfully.${NC}"

        # 6. Start services
        echo -e "\n${CYAN}${BOLD}=> Step 6: Starting Services...${NC}"
        spinner "docker compose up -d" "Launching all services"

        # 7. Final summary
        {
            echo -e "\n${BLUE}================== Installation Successful ==================${NC}"
            echo -e "Your services are now accessible at the following URLs:"
            echo -e "\n  ${PURPLE}Traefik Dashboard & Monitoring:${NC}"
            echo -e "    ${BOLD}Traefik URL:${NC} https://$traefik_domain"
            if [ -n "$monitor_domain" ]; then
                echo -e "    ${BOLD}Monitoring URL:${NC} https://$monitor_domain"
            fi
            echo -e "    ${BOLD}Username:${NC} admin"
            echo -e "    ${BOLD}Password:${NC} ${YELLOW}$traefik_password${NC}"
            echo -e "\n  ${PURPLE}Zero-UI Dashboard:${NC}"
            echo -e "    ${BOLD}URL:${NC} https://$zero_ui_domain"
            echo -e "    ${BOLD}Username:${NC} admin"
            echo -e "    ${BOLD}Password:${NC} ${YELLOW}$zero_ui_password${NC}"
            echo -e "\n${BOLD}${RED}NOTE: It is recommended to protect your panel URLs with Cloudflare CDN.${NC}"
            echo -e "${BLUE}===========================================================${NC}"
        } | tee "${SCRIPT_DIR}/zero_ui_summary.txt"
        
        echo -e "\n${GREEN}${CHECK} Summary saved to ${SCRIPT_DIR}/zero_ui_summary.txt${NC}"
        ;;
    2)
        # --- Moon Server Installation ---
        echo -e "\n${BLUE}--- Starting Zerotier Moon Server Installation ---${NC}"
        read -p " • Please enter this server's public IP address: " public_ip

        echo -e "\n${CYAN}${BOLD} => Step 1: Installing Zerotier${NC}"
        spinner "curl -s https://install.zerotier.com | bash" "Installing Zerotier service"

        echo -e "\n${CYAN}${BOLD}=> Step 2: Generating Moon Configuration${NC}"
        cd /var/lib/zerotier-one || exit
        zerotier-idtool initmoon identity.public > moon.json
        sed -i "s/\"stableEndpoints\": \[\]/\"stableEndpoints\": [\"$public_ip\/9993\"]/" moon.json
        zerotier-idtool genmoon moon.json >/dev/null 2>&1
        mkdir -p moons.d
        mv ./*.moon moons.d/
        echo -e "${GREEN}${CHECK} Moon file created and signed with your IP.${NC}"

        echo -e "\n${CYAN}${BOLD}=> Step 3: Restarting Service${NC}"
        spinner "systemctl restart zerotier-one" "Restarting Zerotier service"

        moon_id=$(basename /var/lib/zerotier-one/moons.d/*.moon .moon)
        moon_path="/var/lib/zerotier-one/moons.d/${moon_id}.moon"

        # Capture the summary to both the screen and a file
        {
            echo -e "\n${BLUE}============= Moon Server Setup Complete =============${NC}"
            echo -e "Your Moon ID is: ${YELLOW}${BOLD}${moon_id}${NC}"
            echo -e "\n${PURPLE}ACTION REQUIRED: Add this Moon to your clients and controller${NC}"
            echo -e "\n  ${BOLD}1. Copy the .moon file from this server:${NC}"
            echo -e "     Run this command on your CLIENT/CONTROLLER machine:"
            echo -e "     ${GREEN}scp root@${public_ip}:${moon_path} ./${NC}"
            
            echo -e "\n  ${BOLD}2. To add to your Zero-UI Controller container (on the main server):${NC}"
            echo -e "     After copying the file with scp, run these commands on the CONTROLLER server:"
            echo -e "     ${GREEN}sudo cp ./${moon_id}.moon /var/lib/docker/volumes/zero-ui-stack_zerotier-data/_data/moons.d/${NC}"
            echo -e "     (If the above directory doesn't exist, create it: sudo mkdir -p /var/lib/docker/volumes/zero-ui-stack_zerotier-data/_data/moons.d/)"
            echo -e "     Then, force the controller to join the moon with this command:"
            echo -e "     ${GREEN}docker exec zerotier-controller zerotier-cli orbit ${moon_id} ${moon_id}${NC}"

            echo -e "\n  ${BOLD}3. To add to a regular Linux client:${NC}"
            echo -e "     ${GREEN}sudo mkdir -p /var/lib/zerotier-one/moons.d/${NC}"
            echo -e "     ${GREEN}sudo mv ./${moon_id}.moon /var/lib/zerotier-one/moons.d/${NC}"
            echo -e "     ${GREEN}sudo systemctl restart zerotier-one${NC}"

            echo -e "\n  ${BOLD}4. Verify the connection (on client or controller):${NC}"
            echo -e "     ${GREEN}sudo zerotier-cli listmoons${NC} # On a regular client"
            echo -e "     ${GREEN}docker exec zerotier-controller zerotier-cli listmoons${NC} # On the controller"
            echo -e "${BLUE}======================================================${NC}"
        } | tee "${SCRIPT_DIR}/moon_server_summary.txt"

        echo -e "\n${GREEN}${CHECK} Summary saved to ${SCRIPT_DIR}/moon_server_summary.txt${NC}"
        ;;
    3)
        # --- Restart Zero-UI Services ---
        echo -e "\n${BLUE}--- Restarting Zero-UI Services ---${NC}"
        if [ -f "/opt/zero-ui-stack/docker-compose.yml" ]; then
            cd /opt/zero-ui-stack || exit
            spinner "docker compose restart" "Restarting all services"
        else
            echo -e "${RED}${CROSS} Zero-UI stack not found. Please install it first using option 1.${NC}"
        fi
        ;;
    4)
        echo -e "${YELLOW}Exiting script.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}${BOLD}ERROR:${NC} Invalid option. Please choose a number between 1 and 4."
        exit 1
        ;;
esac

echo -e "\n${GREEN}${BOLD}${CHECK}Script execution finished.${NC}"
exit 0