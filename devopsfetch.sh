#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: devopsfetch [Options]"
  echo "Options:"
  echo "  -p, --port [port_number]       Display active ports or detailed information about a specific port"
  echo "  -d, --docker [container_name]  List Docker images and containers or provide details about a specific container"
  echo "  -n, --nginx [domain]           Display Nginx domains and their ports or detailed configuration for a specific domain"
  echo "  -u, --users [username]         List users and their last login times or detailed information about a specific user"
  echo "  -t, --time [start_time] [end_time]        Display activities within a specified time range"
  echo "  -h, --help                     Display this help message"
}

# Function to print border
print_border() {
    local width=$1
    printf "+"
    for ((i = 0; i < $width; i++)); do
        printf "-"
    done
    printf "+\n"
}

# Function to print row
print_row() {
    local width=$1
    shift
    printf "|"
    for cell in "$@"; do
        printf " %-*s |" $width "$cell"
    done
    printf "\n"
}

# Function to print header
print_header() {
    local width=$1
    shift
    local header=("$@")
    print_border $((width * ${#header[@]} + ${#header[@]} + 1))
    print_row $width "${header[@]}"
    print_border $((width * ${#header[@]} + ${#header[@]} + 1))
}

# Function to print footer
print_footer() {
    local width=$1
    local cols=$2
    print_border $((width * cols + cols + 1))
}

# Function to get port information
port_info() {
    if [ -z "$1" ]; then
        echo -e "Active Ports, Services, and Processes:\n"
        local cols=("SERVICE" "PORT" "STATE" "PID")
        local col_width=20
        print_header $col_width "${cols[@]}"
        sudo lsof -i -P -n | grep LISTEN | awk -v width=$col_width '{split($9,a,":"); printf "| %-*s | %-*s | %-*s | %-*s |\n", width, $1, width, a[length(a)], width, $10, width, $2 "/" $1}'
        print_footer $col_width ${#cols[@]}
    else
        echo -e "Information for Port $1:\n"
        local cols=("PROTOCOL" "PORT" "STATE" "PROGRAM")
        local col_width=20
        print_header $col_width "${cols[@]}"
        sudo lsof -i :$1 -sTCP:LISTEN -n -P | awk -v width=$col_width '{split($9,a,":"); printf "| %-*s | %-*s | %-*s | %-*s |\n", width, "TCP", width, a[length(a)], width, "LISTEN", width, $1}'
        print_footer $col_width ${#cols[@]}
    fi
}

# Function to get Docker information
docker_info() {
    if [ -z "$1" ]; then
        echo -e "Docker Images and Containers:\n"
        echo -e "Key: \e[32mIn Use\e[0m | \e[31mNot In Use\e[0m\n"
        local cols=("IMAGE" "CONTAINER")
        local col_width=30
        print_header $col_width "${cols[@]}"
        docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
            if docker ps -a --filter ancestor="$image" --format "{{.Names}}" | grep -q .; then
                color="\e[32m"  # Green
            else
                color="\e[31m"  # Red
            fi
            container=$(docker ps -a --filter ancestor="$image" --format "{{.Names}}")
            printf "| ${color}%-*s\e[0m | ${color}%-*s\e[0m |\n" $col_width "$image" $col_width "$container"
        done
        print_footer $col_width ${#cols[@]}
    else
        echo -e "Details for Docker Container $1:\n"
        docker inspect "$1" | jq '.'
    fi
}

# Function to get Nginx information
nginx_info() {
    if [ -z "$1" ]; then
        echo -e "Nginx Domains, Proxies, and Configuration Files:\n"
        local cols=("Server Domain" "Proxy" "Configuration File")
        local col_width=40
        print_header $col_width "${cols[@]}"
        for conf in /etc/nginx/sites-available/*; do
            domains=""
            port=""
            proxy=""
            while read -r line; do
                if [[ $line =~ server_name ]]; then
                    domains=$(echo $line | awk '{for (i=2; i<=NF; i++) print $i}' | tr -d ';')
                elif [[ $line =~ listen ]]; then
                    port=$(echo $line | awk '{print $2}' | tr -d ';')
                elif [[ $line =~ proxy_pass ]]; then
                    proxy=$(echo $line | awk '{print $2}' | tr -d ';')
                fi

                if [[ $line == *"}"* ]]; then
                    if [ -n "$domains" ] && [ -n "$port" ]; then
                        for domain in $domains; do
                            printf "| %-*s | %-*s | %-*s |\n" $col_width "$domain:$port" $col_width "$proxy" $col_width "$conf"
                        done
                    fi
                    domains=""
                    port=""
                    proxy=""
                fi
            done < "$conf"
        done
        print_footer $col_width ${#cols[@]}
    else
        echo -e "Configuration for Nginx Domain $1:\n"
        domain=$(echo "$1" | awk -F: '{print $1}')
        port=$(echo "$1" | awk -F: '{print $2}')
        conf_file=""
        for conf in /etc/nginx/sites-available/*; do
            if grep -q "server_name.*$domain" "$conf" && grep -q "listen.*$port" "$conf"; then
                conf_file="$conf"
                break
            fi
        done
        if [ -f "$conf_file" ]; then
            cat "$conf_file"
        else
            echo "No configuration file found for domain $1"
        fi
    fi
}

# Function to get user information
user_info() {
    if [ -z "$1" ]; then
        echo -e "Users and Last Login Times:\n"
        local cols=("USERNAME" "LAST LOGIN")
        local col_width=30
        print_header $col_width "${cols[@]}"
        last | sed -e '$d' -e '$d' | awk -v width=$col_width '{printf "| %-*s | %-*s |\n", width, $1, width, $4" "$5" "$6" "$7" "$8" "$9}'
        print_footer $col_width ${#cols[@]}
    else
        echo -e "Details for User $1:\n"
        last "$1"
    fi
}

# Function to get time range information for specific dates
display_activities() {
    local start_time="$1"
    local end_time="$2"

    if [ -z "$end_time" ]; then
        end_time="$start_time"
    fi

    if [[ "$start_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        start_time="${start_time} 00:00:00"
    fi

    if [[ "$end_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        end_time="${end_time} 23:59:59"
    fi

    echo -e "Displaying System Logs from $start_time to $end_time:\n"

    logs=$(sudo journalctl --since "$start_time" --until "$end_time")

    echo -e "Filtered Logs:\n"
    echo "$logs"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            shift
            port_info "$1"
            shift
            ;;
        -d|--docker)
            shift
            docker_info "$1"
            shift
            ;;
        -n|--nginx)
            shift
            nginx_info "$1"
            shift
            ;;
        -u|--users)
            shift
            user_info "$1"
            shift
            ;;
        -t|--time)
            shift
            start_time="$1"
            shift
            end_time="$1"
            shift
            display_activities "$start_time" "$end_time"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done
