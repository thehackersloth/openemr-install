Markdown

# OpenEMR Installation Script with SSL Configuration

This script automates the installation of **OpenEMR 7.0.3** on a **Debian 12** server, sets up the necessary database, and configures SSL for secure access. It also allows you to choose between **Let’s Encrypt SSL**, your own SSL certificates, or skip SSL setup altogether.

### Features:
- Automatically installs required packages (Apache, MariaDB, PHP, etc.).
- Downloads and extracts OpenEMR 7.0.3.
- Creates a unique database and user with random credentials for OpenEMR.
- Guides the user through SSL configuration:
  - **Let’s Encrypt SSL** installation (with Certbot).
  - **Custom SSL** certificate setup.
  - Option to **skip SSL** setup.
- Cleans up the installation by deleting the `/setup` directory after web configuration.

---

## Prerequisites:
- **Debian 12** (or any compatible Debian-based OS).
- **Root privileges** to run the script.
- **A fully qualified domain name (FQDN)** for SSL setup, if you choose Let’s Encrypt or custom SSL.

---

## Installation

### 1. Download the Script:
You can download the installation script from the repository or copy it from below.

### 2. Set Up Your Server:
Ensure your server is up to date and has the required dependencies:
```bash
sudo apt update && sudo apt upgrade -y
```
3. Run the Installation Script:
Download the script (you can copy-paste the script from below, or if it's available on GitHub, clone the repository).

Make the script executable:

```Bash

chmod +x install_openemr.sh
```
Execute the script:

```Bash

sudo ./install_openemr.sh
```
The script will do the following:

Check for any existing OpenEMR installation and offer to backup and remove it.
Install required packages (Apache, MariaDB, PHP).
Download OpenEMR 7.0.3 and extract it into /var/www/html.
Create a random database and user for OpenEMR with the appropriate privileges.
Save the database credentials to a file for future reference.
Prompt the user to complete the OpenEMR web configuration by visiting http://<your-server-ip>/ in a browser.
After web configuration, ask the user if they want to configure SSL:
Use Let’s Encrypt: Installs Certbot and obtains an SSL certificate.
Use Custom SSL: Allows the user to upload their SSL certificates.
Skip SSL: Skips SSL setup.
4. Access OpenEMR:
Once the installation completes, open your browser and navigate to http://<your-server-ip>/ to continue the OpenEMR setup.

Example:

http://your-server-ip/
SSL Configuration Options:
After completing the web configuration, the script will ask whether you want to configure SSL for secure HTTPS access:

Let’s Encrypt SSL:
If you choose to use Let’s Encrypt, the script will install Certbot and automatically obtain a free SSL certificate for your domain. Certbot will configure Apache to use the SSL certificate for HTTPS.

Custom SSL:
If you already have an SSL certificate, the script will prompt you to upload your certificate files:

SSL Certificate: /etc/ssl/certs/your_cert.crt
Private Key: /etc/ssl/private/your_private.key
CA Bundle (if needed): /etc/ssl/certs/your_ca_bundle.crt The script will then configure Apache to use your custom SSL certificates.
Skip SSL:
If you prefer to skip SSL configuration, you can choose to do so. OpenEMR will be accessible over HTTP.

Example Output:
Here’s an example of how the script interacts with the user:

CSS

[+] Checking for existing OpenEMR install...
[+] Installing required packages...
[+] Downloading OpenEMR 7.0.3...
[+] Extracting OpenEMR...
[+] Moving files to /var/www/html...
[+] Setting file permissions...
[+] Creating OpenEMR database and user...
[+] Restarting Apache and MariaDB...
[✓] OpenEMR 7.0.3 is installed.

➡ Open your browser and go to: http://<your-server-ip>/
➡ Follow the web installer and use the following database credentials:
    - DB Name: openemr_randomname
    - DB User: user_randomname
    - DB Pass: randompassword

📝 These have also been saved to: /root/openemr_db_credentials_2025-04-11_14-30-45.txt

Press Enter after you have finished the OpenEMR web configuration...
After you press Enter, the script will proceed with SSL configuration options.

Deleting Setup Files:
For security, after the installation is complete, the script will automatically delete the /setup directory to prevent any unauthorized reconfiguration of OpenEMR.

Notes:
Database Credentials: The script generates a random database name, username, and password for OpenEMR. These are saved to a file for your reference (/root/openemr_db_credentials_<timestamp>.txt).
Security: The script will clean up the installation by removing unnecessary files (like the /setup directory) once the OpenEMR installation is completed.
SSL Certificates: If you opt to use your own SSL, be sure to upload the correct files to your server in the specified paths.
Troubleshooting:
If you encounter issues with the installation, check the following:

Web Server: Ensure that Apache is running and that the OpenEMR directory is properly accessible.
```Bash

systemctl status apache2
MySQL: Ensure that MariaDB is running and the database was created successfully.
```
```Bash

systemctl status mariadb
```
PHP: Ensure that all required PHP modules are installed.
License: This script is open-source and free to use. Modify and distribute it according to your needs.
This script is open-source and free to use. Modify and distribute it according to your needs.
