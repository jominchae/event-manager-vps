#!/bin/bash
# Complete VPS Deployment Script for Event Manager
# Usage: ./deploy-to-vps.sh [server-ip] [domain] [email]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }

# Default values
SERVER_IP=""
DOMAIN=""
EMAIL=""
SSH_USER="root"
APP_USER="eventmanager"
APP_DIR="/var/www/event-manager"
POSTGRES_VERSION="16"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --server|-s)
      SERVER_IP="$2"
      shift 2
      ;;
    --domain|-d)
      DOMAIN="$2"
      shift 2
      ;;
    --email|-e)
      EMAIL="$2"
      shift 2
      ;;
    --user|-u)
      SSH_USER="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 --server SERVER_IP --domain DOMAIN --email EMAIL [options]"
      echo "Options:"
      echo "  --server, -s     Server IP address"
      echo "  --domain, -d     Domain name"
      echo "  --email, -e      Email for Let's Encrypt"
      echo "  --user, -u       SSH user (default: root)"
      echo "  --help, -h       Show this help"
      exit 0
      ;;
    *)
      if [ -z "$SERVER_IP" ]; then
        SERVER_IP="$1"
      elif [ -z "$DOMAIN" ]; then
        DOMAIN="$1"
      elif [ -z "$EMAIL" ]; then
        EMAIL="$1"
      fi
      shift
      ;;
  esac
done

# Validate required parameters
if [ -z "$SERVER_IP" ] || [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    print_error "Missing required parameters"
    echo "Usage: $0 --server SERVER_IP --domain DOMAIN --email EMAIL"
    echo "Or: $0 SERVER_IP DOMAIN EMAIL"
    echo "Run with --help for more options"
    exit 1
fi

echo "🚀 Deploying Event Manager to VPS..."
print_info "Server: $SERVER_IP"
print_info "Domain: $DOMAIN"
print_info "Email: $EMAIL"
print_info "SSH User: $SSH_USER"
echo ""

# Test SSH connection
print_info "Testing SSH connection..."
if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no $SSH_USER@$SERVER_IP "echo 'SSH connection successful'"; then
    print_status "SSH connection established"
else
    print_error "Cannot connect to $SERVER_IP as $SSH_USER"
    print_info "Make sure you have SSH key access to the server"
    exit 1
fi

# Check if build exists
if [ ! -f "dist/server/index.js" ]; then
    print_warning "Production build not found. Building now..."
    if ./scripts/build-production.sh; then
        print_status "Build completed"
    else
        print_error "Build failed"
        exit 1
    fi
fi

# Create deployment package
print_info "Creating deployment package..."
rm -rf deploy-package
mkdir -p deploy-package
cp -r dist/* deploy-package/
cp production.env.template deploy-package/.env.template
cp -r scripts deploy-package/
cp *.service deploy-package/ 2>/dev/null || true
cp nginx-*.conf deploy-package/ 2>/dev/null || true
cp *-logrotate deploy-package/ 2>/dev/null || true
cp PRODUCTION-CHECKLIST.md deploy-package/ 2>/dev/null || true

# Create deployment script for server
cat > deploy-package/server-setup.sh << 'EOF'
#!/bin/bash
set -e

# Server setup script (runs on VPS)
echo "🔧 Setting up Event Manager on VPS..."

# Update system
apt update && apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PostgreSQL
apt install -y postgresql postgresql-contrib

# Install Nginx
apt install -y nginx

# Install Certbot for Let's Encrypt
apt install -y certbot python3-certbot-nginx

# Create application user
if ! id "$APP_USER" &>/dev/null; then
    useradd -r -s /bin/false -d $APP_DIR $APP_USER
    echo "✅ Created user: $APP_USER"
fi

# Create directories
mkdir -p $APP_DIR/{uploads/public,uploads/private}
chown -R $APP_USER:$APP_USER $APP_DIR
chmod 755 $APP_DIR
chmod -R 750 $APP_DIR/uploads

# Setup PostgreSQL
sudo -u postgres createuser --interactive eventmanager || true
sudo -u postgres createdb eventmanager -O eventmanager || true

echo "✅ VPS setup completed"
EOF

chmod +x deploy-package/server-setup.sh

print_status "Deployment package created"

# Upload files to server
print_info "Uploading files to server..."
ssh $SSH_USER@$SERVER_IP "mkdir -p /tmp/event-manager-deploy"
scp -r deploy-package/* $SSH_USER@$SERVER_IP:/tmp/event-manager-deploy/

# Run server setup
print_info "Running server setup..."
ssh $SSH_USER@$SERVER_IP "cd /tmp/event-manager-deploy && chmod +x server-setup.sh && ./server-setup.sh"

# Deploy application
print_info "Deploying application..."
ssh $SSH_USER@$SERVER_IP << EOF
set -e

# Copy application files
cp -r /tmp/event-manager-deploy/* $APP_DIR/
chown -R $APP_USER:$APP_USER $APP_DIR

# Setup environment
if [ ! -f "$APP_DIR/.env" ]; then
    cp $APP_DIR/.env.template $APP_DIR/.env
    echo "⚠️ Please configure $APP_DIR/.env with your settings"
fi

# Install systemd service
if [ -f "$APP_DIR/event-manager.service" ]; then
    cp $APP_DIR/event-manager.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable event-manager
fi

# Install nginx config
if [ -f "$APP_DIR/nginx-event-manager.conf" ]; then
    cp $APP_DIR/nginx-event-manager.conf /etc/nginx/sites-available/event-manager
    sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/event-manager
    ln -sf /etc/nginx/sites-available/event-manager /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
fi

# Install logrotate
if [ -f "$APP_DIR/event-manager-logrotate" ]; then
    cp $APP_DIR/event-manager-logrotate /etc/logrotate.d/event-manager
fi

# Create cache directories
mkdir -p /var/cache/nginx/event_manager
chown -R www-data:www-data /var/cache/nginx

echo "✅ Application deployed successfully"
EOF

# Setup SSL certificate
print_info "Setting up SSL certificate..."
ssh $SSH_USER@$SERVER_IP "certbot --nginx -d $DOMAIN --email $EMAIL --agree-tos --non-interactive || echo 'SSL setup failed - configure manually'"

# Start services
print_info "Starting services..."
ssh $SSH_USER@$SERVER_IP << EOF
# Set database password (you'll need to do this interactively)
echo "Please set password for PostgreSQL user 'eventmanager':"
sudo -u postgres psql -c "ALTER USER eventmanager PASSWORD 'your-secure-password';"

# Start application
systemctl start event-manager
systemctl status event-manager --no-pager
EOF

# Health check
print_info "Performing health check..."
sleep 10
if curl -f http://$DOMAIN/api/health > /dev/null 2>&1; then
    print_status "Health check passed!"
else
    print_warning "Health check failed - check application logs"
fi

# Cleanup
rm -rf deploy-package

print_status "Deployment completed!"
echo ""
print_info "🌐 Your Event Manager is available at: https://$DOMAIN"
print_info "🔧 Check status: ssh $SSH_USER@$SERVER_IP 'systemctl status event-manager'"
print_info "📋 View logs: ssh $SSH_USER@$SERVER_IP 'journalctl -u event-manager -f'"
echo ""
print_warning "IMPORTANT: Configure the following manually:"
echo "  1. Edit $APP_DIR/.env with your database password and secrets"
echo "  2. Restart the service: systemctl restart event-manager"
echo "  3. Test all functionality on your domain"
echo ""
print_info "For manual configuration, see: PRODUCTION-CHECKLIST.md"

exit 0