#!/bin/bash

# Log file
LOG_FILE="/var/log/moodle_install_$(date +%Y%m%d_%H%M%S).log"

# Redirect all output to log file and stdout
exec > >(tee -a "$LOG_FILE") 2>&1

# Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root"
    exit 1
fi

# Ensure DOMAIN is passed via environment variable
if [ -z "$DOMAIN" ]; then
    echo "ERROR: Domain name (DOMAIN) is not provided!"
    exit 1
fi

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Function to check command success
check_status() {
    if [ $? -ne 0 ]; then
        echo "ERROR: $1 failed"
        exit 1
    fi
}

echo "Starting unattended Moodle installation for $DOMAIN..."
echo "Timestamp: $(date)"

# Step 1: Update system packages (Non-interactive)
echo "Updating system packages..."
apt update -y
check_status "System update"
apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
check_status "System upgrade"

# Step 2: Install PHP 8.3 and required dependencies (Non-interactive)
echo "Installing PHP 8.3 and required dependencies..."
apt install -y software-properties-common
check_status "Install software-properties-common"
add-apt-repository ppa:ondrej/php -y
check_status "Add PHP repository"
apt update -y
check_status "Update after adding PHP repository"
apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
    php8.3 php8.3-cli php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-curl php8.3-tokenizer \
    php8.3-xmlrpc php8.3-soap php8.3-zip php8.3-gd php8.3-xml php8.3-intl apache2 libapache2-mod-php8.3
check_status "PHP and Apache installation"

# Step 3: Configure php.ini for PHP 8.3
echo "Configuring PHP settings for PHP 8.3..."
sed -i 's/;max_input_vars = 1000/max_input_vars = 5000/' /etc/php/8.3/apache2/php.ini
check_status "PHP configuration"

# Step 4: Download and setup Moodle (Non-interactive)
echo "Downloading and installing Moodle..."
wget -q https://packaging.moodle.org/stable403/moodle-4.3.2.tgz
check_status "Moodle download"
tar xzf moodle-4.3.2.tgz
check_status "Moodle extraction"
mkdir -p /var/www/$DOMAIN
mv moodle /var/www/$DOMAIN/moodle-app
mkdir /var/www/$DOMAIN/moodle-data
check_status "Moodle directory setup"

# Set permissions
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/$DOMAIN
chmod -R 755 /var/www/$DOMAIN
check_status "Permission setup"

# Step 5: Configure Apache Virtual Host (Non-interactive)
echo "Configuring Apache virtual host..."
cat > /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/$DOMAIN/moodle-app
    <Directory /var/www/$DOMAIN/moodle-app>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /var/log/apache2/${DOMAIN}_error.log
    CustomLog /var/log/apache2/${DOMAIN}_access.log combined
</VirtualHost>
EOF
check_status "Virtual host configuration"

# Enable Apache modules and site (Non-interactive)
echo "Enabling Apache modules and restarting service..."
a2dissite 000-default -q
a2enmod rewrite -q
a2ensite $DOMAIN -q
systemctl restart apache2
check_status "Apache configuration"

# Configure firewall (Non-interactive)
echo "Configuring firewall..."
ufw allow http 
ufw allow https 
ufw allow ssh
#ufw -f enable
check_status "Firewall configuration"

echo "Moodle installation completed successfully!"
echo "Timestamp: $(date)"
echo "Log file: $LOG_FILE"
echo "Please browse to http://$DOMAIN to complete the web-based installation"
