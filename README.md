Overview

DevOpsFetch is a powerful tool designed for system administrators and DevOps engineers to retrieve and monitor system information,
including active ports, user logins, Nginx configurations, Docker images, and container statuses. The tool also includes a continuous
monitoring mode using systemd for seamless logging and monitoring.

Installation and Configuration
Prerequisites
Ensure the following are installed on your system:

nginx
docker.io
jq

Installation
Clone the Repository:
git clone https://github.com/Ayodele-Omolayo/devopsfetch.git
cd devopsfetch
Run the Installation Script:
sudo ./install.sh

Usage
The devopsfetch script provides various options to retrieve system information. Use the following command to run the script:
./devopsfetch.sh [OPTIONS]

Options
-p, --port [PORT_NUMBER]: Display all active ports or detailed information about a specific port.
Example:
./devopsfetch.sh -p
./devopsfetch.sh -p 80

-d, --docker [CONTAINER_NAME]: List all Docker images and containers or details for a specific container.
Example:
./devopsfetch.sh -d
.//devopsfetch.sh -d my_container

-n, --nginx [DOMAIN]: Display all Nginx domains, proxies, configuration files, and their ports, or detailed configuration for a specific domain.
Example:
./devopsfetch.sh -n
./devopsfetch.sh -n example.com

-u, --users [USERNAME]: List all users and their last login times or detailed information about a specific user.
Example:
./devopsfetch.sh -u
./devopsfetch.sh -u johndoe

-t, --time [START_TIME] [END_TIME]: Display activities within a specified time range.
Example:
./devopsfetch.sh -t "2024-07-01" "2024-07-02"

-h, --help: Display the help message with usage instructions.
Example:
./devopsfetch/devopsfetch.sh -h


Logging Mechanism
DevOpsFetch utilizes systemd for continuous monitoring and logging of activities. The log file is located at /var/log/devopsfetch.log.

Viewing Logs
To view the logs, you can use the journalctl command. Here are some useful commands:
View All Logs for the Service:
sudo journalctl -u devopsfetch.service
View the Last 10 Lines of the Log:
sudo journalctl -u devopsfetch.service -n 10
Follow the Log Output in Real Time:
sudo journalctl -u devopsfetch.service -f

Conclusion

DevOpsFetch is a versatile tool for retrieving and monitoring various aspects of your system. With its comprehensive logging 
and easy-to-use command-line interface, it simplifies the process of system administration and monitoring.



