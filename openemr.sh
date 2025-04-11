#!/bin/bash

set -e

# ----- Generate random DB credentials -----
DB_NAME="openemr_$(head /dev/urandom | tr -dc a-z0-9 | head -c 6)"
DB_USER="user_$(head /dev/urandom | tr -dc a-z0-9 | head -c 6)"
DB_PASS="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)"

# ----- Other constants -----
OPENEMR_VERSION="7.0.3"
INSTALL_DIR="/var/www/html"
BACKUP_DIR="/root/openemr_backup_$(date +%F_%T)"
APACHE_USER="www-data"

echo "[+] Checking for existing OpenEMR install..."

if [ -d "$INSTALL_DIR/interface" ]; then
    echo "[!] Existing OpenEMR installation found in $INSTALL_DIR."

    read -p "Do you want to backup and remove it? [y/N] " confirm
    if echo "$confirm" | grep -iq "^y$"; then
        echo "[+] Backing up current OpenEMR..."
        mkdir -p "$BACKUP_DIR"
        cp -a "$INSTALL_DIR" "$BACKUP_DIR/"
        echo "[+] Removing existing OpenEMR..."
        rm -rf "$INSTALL_DIR"/*
    else
        echo "[!] Aborting installation."
        exit 1
    fi
else
    echo "[+] No existing OpenEMR installation found."
fi

echo "[+] Installing required packages..."
apt update
apt install -y apache2 mariadb-server php libapache2-mod-php \
php-mysql php-gd php-cli php-curl php-mbstring php-xml php-zip php-soap unzip wget curl tar

echo "[+] Downloading OpenEMR $OPENEMR_VERSION..."
cd /tmp
wget -O openemr-${OPENEMR_VERSION}.tar.gz "https://sourceforge.net/projects/openemr/files/OpenEMR%20Current/${OPENEMR_VERSION}/openemr-${OPENEMR_VERSION}.tar.gz/download"

echo "[+] Extracting OpenEMR..."
tar -xzf openemr-${OPENEMR_VERSION}.tar.gz

echo "[+] Moving files to $INSTALL_DIR..."
rm -rf "${INSTALL_DIR:?}/"*
mv openemr-${OPENEMR_VERSION}/* "$INSTALL_DIR"

echo "[+] Setting file permissions..."
chown -R "$APACHE_USER":"$APACHE_USER" "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"

echo "[+] Creating OpenEMR database and user..."
mysql -u root <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
DROP USER IF EXISTS '$DB_USER'@'localhost';
CREATE DATABASE $DB_NAME CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[+] Restarting Apache and MariaDB..."
systemctl restart apache2
systemctl restart mariadb

# Save credentials to file
CRED_FILE="/root/openemr_db_credentials_$(date +%F_%H-%M-%S).txt"
cat <<EOF > "$CRED_FILE"
OpenEMR MySQL Credentials
-------------------------
Database Name: $DB_NAME
Username:      $DB_USER
Password:      $DB_PASS
EOF

echo "[✓] OpenEMR $OPENEMR_VERSION is installed."
echo
echo "➡ Open your browser and go to: http://<your-server-ip>/"
echo "➡ Follow the web installer and use the following database credentials:"
echo "   - DB Name: $DB_NAME"
echo "   - DB User: $DB_USER"
echo "   - DB Pass: $DB_PASS"
echo
echo "📝 These have also been saved to: $CRED_FILE"
echo "⚠️ After installation, remember to delete or secure the setup directory!"

# Wait for web config completion
read -p "Press Enter after you have finished the OpenEMR web configuration..."

# Delete the OpenEMR setup directory for security
echo "[+] Deleting the OpenEMR setup directory..."
rm -rf "$INSTALL_DIR/setup"

# SSL setup options
echo "[+] Do you want to configure SSL for OpenEMR?"
echo "1. Use Let’s Encrypt SSL"
echo "2. Use your own SSL certificate"
echo "3. Skip SSL setup"

read -p "Please enter 1, 2, or 3: " ssl_choice

if [ "$ssl_choice" -eq 1 ]; then
    # Install Let's Encrypt (Certbot)
    echo "[+] Installing Let’s Encrypt (Certbot)..."
    apt install -y certbot python3-certbot-apache

    echo "[+] Obtaining SSL certificate for your domain..."
    certbot --apache -d your-domain.com --non-interactive --agree-tos -m your-email@example.com

    echo "[✓] SSL setup completed with Let’s Encrypt!"
elif [ "$ssl_choice" -eq 2 ]; then
    # User's own SSL setup
    echo "[+] Please upload your SSL certificate files to the server."
    echo " - SSL Certificate: /etc/ssl/certs/your_cert.crt"
    echo " - Private Key: /etc/ssl/private/your_private.key"
    echo " - CA Bundle: /etc/ssl/certs/your_ca_bundle.crt"

    echo "[+] Configure Apache for your own SSL..."
    # Modify Apache configuration for SSL (user's own certificates)
    cat <<EOF > /etc/apache2/sites-available/000-default-ssl.conf
<VirtualHost *:443>
    ServerAdmin webmaster@your-domain.com
    DocumentRoot /var/www/html
    ServerName your-domain.com

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/your_cert.crt
    SSLCertificateKeyFile /etc/ssl/private/your_private.key
    SSLCertificateChainFile /etc/ssl/certs/your_ca_bundle.crt

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>

</VirtualHost>
EOF

    echo "[+] Enabling SSL site and restarting Apache..."
    a2enmod ssl
    a2ensite 000-default-ssl.conf
    systemctl restart apache2

    echo "[✓] SSL configured with your own certificates."
elif [ "$ssl_choice" -eq 3 ]; then
    echo "[+] Skipping SSL setup."
else
    echo "[!] Invalid choice. Skipping SSL setup."
fi
