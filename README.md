# Redmine GeoTracker Plugin

## Description
A comprehensive geolocation tracking system for Redmine that enables spatial tracking, workflow management, and advanced analytics. This plugin automatically captures and manages location data across all Redmine entities.

## Author
Carlos Arbelaez
Version: 1.0.0-alpha

## Server Requirements (Ubuntu 24.04)

### System Requirements
- CPU: 2+ cores recommended
- RAM: 4GB minimum, 8GB recommended
- Storage: 20GB minimum for system and logs

### Software Requirements
- Ruby 3.0 or higher
- Rails 7.0 or higher
- PostgreSQL 14+ with PostGIS extension
- Node.js 18+ (for asset compilation)
- Nginx (as reverse proxy)
- Redis (for background jobs)
- ImageMagick (for image processing)

## Installation Instructions

### 1. System Updates and Basic Tools
```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install basic dependencies
sudo apt install -y build-essential git curl libpq-dev \
    imagemagick libmagickwand-dev nginx redis-server
```

### 2. Install Ruby using rbenv
```bash
# Install rbenv and dependencies
sudo apt install -y libssl-dev zlib1g-dev
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install ruby-build
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Install Ruby
rbenv install 3.0.6
rbenv global 3.0.6
```

### 3. Install PostgreSQL and PostGIS
```bash
# Add PostgreSQL repository
sudo apt install -y postgresql-14 postgresql-contrib postgis postgresql-14-postgis-3

# Create database user and enable PostGIS
sudo -u postgres psql -c "CREATE USER redmine WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "CREATE DATABASE redmine_production OWNER redmine;"
sudo -u postgres psql -d redmine_production -c "CREATE EXTENSION postgis;"
```

### 4. Install Node.js
```bash
# Install Node.js using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

### 5. Install Redmine
```bash
# Clone Redmine
cd /opt
sudo git clone https://github.com/redmine/redmine.git
cd redmine
sudo git checkout 5.0-stable

# Install dependencies
sudo gem install bundler
bundle install --without development test

# Configure database
sudo cp config/database.yml.example config/database.yml
# Edit database.yml with your PostgreSQL credentials
```

### 6. Install GeoTracker Plugin
```bash
# Clone plugin
cd /opt/redmine/plugins
sudo git clone https://github.com/carlos0424/redmine_geotracker.git
cd redmine_geotracker

# Install plugin dependencies
bundle install
```

### 7. Configure Nginx
```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/redmine

# Add this configuration:
server {
    listen 80;
    server_name your_domain.com;

    root /opt/redmine/public;
    
    passenger_enabled on;
    passenger_min_instances 2;

    client_max_body_size 10M;

    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
    }
}

# Enable the site
sudo ln -s /etc/nginx/sites-available/redmine /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 8. Final Setup
```bash
# Generate secret token
cd /opt/redmine
bundle exec rake generate_secret_token

# Run migrations
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake redmine:plugins:migrate

# Compile assets
RAILS_ENV=production bundle exec rake assets:precompile

# Set permissions
sudo chown -R www-data:www-data /opt/redmine
sudo chmod -R 755 /opt/redmine

# Restart services
sudo systemctl restart nginx
```

## Post-Installation

### Security Recommendations
1. Configure firewall (UFW)
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

2. Set up SSL with Let's Encrypt
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your_domain.com
```

### Maintenance Commands

#### Backup Database
```bash
pg_dump -U redmine redmine_production > backup.sql
```

#### Update Plugin
```bash
cd /opt/redmine/plugins/redmine_geotracker
git pull
RAILS_ENV=production bundle exec rake redmine:plugins:migrate
```

#### Check Logs
```bash
tail -f /opt/redmine/log/production.log
```

## Support
For bugs and feature requests, please use the GitHub issues system:
https://github.com/carlos0424/redmine_geotracker/issues

## License
This plugin is licensed under the GPL v2 license.
