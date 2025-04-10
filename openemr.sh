#!/bin/bash
# OpenEMR Installation Script with Custom MySQL Configuration

# 0. MySQL Root Password Configuration
read -p "Set MySQL root password: " -s mysql_root_pass
echo
echo "mysql-server mysql-server/root_password password $mysql_root_pass" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $mysql_root_pass" | sudo debconf-set-selections

# 1. System Update & Dependency Installation
sudo apt-get update
sudo apt-get install -y \
    apache2 \
    mysql-server \
    php5 \
    php5-mysql \
    php5-gd \
    php5-xml \
    php5-curl \
    unzip

# 2. Configure MySQL 
mysql -u root -p"$mysql_root_pass" -e "SET GLOBAL sql_mode = '';"
sudo service mysql restart

# 3. Download OpenEMR (Example for v5.0.0)
wget https://downloads.sourceforge.net/openemr/openemr-5.0.0.tar.gz
tar -pxvzf openemr-5.0.0.tar.gz

# 4. Move Files to Web Directory
sudo mv openemr-5.0.0 /var/www/openemr
sudo chown -R www-data:www-data /var/www/openemr

# 5. Configure Permissions 
cd /var/www/openemr
sudo find . -type f -exec chmod 644 {} \;
sudo find . -type d -exec chmod 755 {} \;
sudo chmod 666 library/sqlconf.php interface/globals.php
sudo chmod 600 acl_setup.php acl_upgrade.php setup.php

# 6. Apache Configuration
echo "Alias /openemr /var/www/openemr
<Directory /var/www/openemr>
    AllowOverride FileInfo
    Require all granted
</Directory>" | sudo tee /etc/apache2/conf-available/openemr.conf

sudo a2enconf openemr
sudo service apache2 reload

# 7. Database User Configuration
read -p "Enter MySQL username for OpenEMR [openemr_user]: " openemr_db_user
openemr_db_user=${openemr_db_user:-openemr_user}

read -p "Set password for $openemr_db_user: " -s openemr_db_pass
echo

mysql -u root -p"$mysql_root_pass" -e "CREATE DATABASE openemr;"
mysql -u root -p"$mysql_root_pass" -e "CREATE USER '$openemr_db_user'@'localhost' IDENTIFIED BY '$openemr_db_pass';"
mysql -u root -p"$mysql_root_pass" -e "GRANT ALL PRIVILEGES ON openemr.* TO '$openemr_db_user'@'localhost';"
mysql -u root -p"$mysql_root_pass" -e "FLUSH PRIVILEGES;"

# 8. Web Configuration Instructions
clear
echo "=== WEB CONFIGURATION REQUIRED ==="
echo "1. Open in your browser: http://$(hostname -I | awk '{print $1}')/openemr/setup.php"
echo "2. Use these database credentials:"
echo "   - Database Host: localhost"
echo "   - Database Name: openemr"
echo "   - Database User: $openemr_db_user"
echo "   - Database Password: [your chosen password]"
echo "3. Complete all steps in the web interface"
echo -e "\nPress Enter after completing web configuration to finalize installation..."

# 9. Wait for user completion
read -p $'\nPress Enter when web configuration is complete...' dummy_input

# 10. Post-Install Security
sudo chmod 600 /var/www/openemr/setup.php
sudo rm -rf /var/www/openemr/setup

echo "Installation complete! Security measures applied."
