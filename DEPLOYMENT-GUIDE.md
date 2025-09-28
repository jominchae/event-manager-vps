# Event Manager VPS Deployment Guide

Complete guide for deploying Event Manager from Replit to your own VPS.

## 🚀 Quick Deployment

For a one-command deployment to your VPS:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy to VPS (replace with your details)
./scripts/deploy-to-vps.sh --server YOUR_SERVER_IP --domain your-domain.com --email your-email@domain.com
```

## 📋 Manual Deployment Steps

### 1. Prepare Local Environment

```bash
# 1. Build the application
./scripts/build-production.sh

# 2. Generate production configurations  
./scripts/optimize-production.sh

# 3. Prepare deployment package
tar -czf event-manager-vps.tar.gz dist/ scripts/ *.service nginx-*.conf production.env.template PRODUCTION-CHECKLIST.md
```

### 2. Server Prerequisites

Your VPS should have:
- **OS**: Ubuntu 20.04+ or Debian 11+ (recommended)
- **Memory**: Minimum 1GB RAM, 2GB+ recommended
- **Storage**: 10GB+ available space
- **Network**: Port 80, 443, and 5000 accessible

### 3. Install Dependencies on VPS

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Nginx & SSL support
sudo apt install -y nginx certbot python3-certbot-nginx

# Install other utilities
sudo apt install -y curl wget unzip git htop
```

### 4. Database Setup

Use the automated database setup script:

```bash
# On your VPS
./scripts/setup-database.sh --name eventmanager --user eventmanager --password YOUR_SECURE_PASSWORD
```

Or manually:

```bash
sudo -u postgres createuser --interactive eventmanager
sudo -u postgres createdb eventmanager -O eventmanager
sudo -u postgres psql -c "ALTER USER eventmanager PASSWORD 'YOUR_SECURE_PASSWORD';"
```

### 5. Application Deployment

```bash
# 1. Create application directory
sudo mkdir -p /var/www/event-manager
sudo useradd -r -s /bin/false eventmanager
sudo chown eventmanager:eventmanager /var/www/event-manager

# 2. Extract application
sudo tar -xzf event-manager-vps.tar.gz -C /var/www/event-manager

# 3. Configure environment
sudo cp /var/www/event-manager/production.env.template /var/www/event-manager/.env
sudo nano /var/www/event-manager/.env  # Edit configuration

# 4. Set permissions
sudo chown -R eventmanager:eventmanager /var/www/event-manager
sudo chmod +x /var/www/event-manager/scripts/*.sh
```

### 6. System Service Setup

```bash
# Install systemd service
sudo cp /var/www/event-manager/event-manager.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable event-manager
sudo systemctl start event-manager

# Check status
sudo systemctl status event-manager
```

### 7. Nginx Configuration

```bash
# Install nginx configuration
sudo cp /var/www/event-manager/nginx-event-manager.conf /etc/nginx/sites-available/event-manager

# Update domain name
sudo sed -i 's/your-domain.com/YOUR_ACTUAL_DOMAIN/g' /etc/nginx/sites-available/event-manager

# Enable site
sudo ln -s /etc/nginx/sites-available/event-manager /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 8. SSL Certificate

```bash
# Get Let's Encrypt certificate
sudo certbot --nginx -d YOUR_DOMAIN --email YOUR_EMAIL --agree-tos --non-interactive

# Test auto-renewal
sudo certbot renew --dry-run
```

## 🔧 Environment Configuration

### Required Environment Variables

Copy `production.env.template` to `.env` and configure:

```env
# Essential settings
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://eventmanager:PASSWORD@localhost:5432/eventmanager

# Security (generate with: openssl rand -hex 32)
JWT_SECRET=your-32-character-secret
SESSION_SECRET=your-32-character-secret

# File storage
STORAGE_TYPE=local
STORAGE_UPLOAD_DIR=/var/www/event-manager/uploads

# GitHub integration (optional)
GITHUB_TOKEN=your-github-token
```

### Security Best Practices

1. **Generate Strong Secrets**:
   ```bash
   # Generate JWT secret
   openssl rand -hex 32
   
   # Generate session secret  
   openssl rand -hex 32
   ```

2. **Database Security**:
   ```bash
   # Use strong database password
   openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
   ```

3. **File Permissions**:
   ```bash
   sudo chmod 600 /var/www/event-manager/.env
   sudo chown eventmanager:eventmanager /var/www/event-manager/.env
   ```

## 🔄 Updates and Maintenance

### Updating the Application

```bash
# On local machine after making changes
./scripts/update-deployment.sh --server YOUR_SERVER_IP
```

### Database Backups

```bash
# Automatic backup (run daily)
/var/www/event-manager/backup-database.sh

# Manual backup
pg_dump -h localhost -U eventmanager eventmanager > backup.sql
```

### Monitoring

```bash
# Check application status
sudo systemctl status event-manager

# View logs
sudo journalctl -u event-manager -f

# Health check
curl http://localhost:5000/api/health
```

### Log Management

```bash
# View application logs
sudo journalctl -u event-manager --since "1 hour ago"

# View nginx access logs
sudo tail -f /var/log/nginx/access.log

# View nginx error logs
sudo tail -f /var/log/nginx/error.log
```

## 🔧 Troubleshooting

### Application Won't Start

1. Check logs: `sudo journalctl -u event-manager -n 50`
2. Verify environment: `sudo -u eventmanager cat /var/www/event-manager/.env`
3. Test database: `sudo -u eventmanager psql $DATABASE_URL -c "SELECT 1;"`

### Database Connection Issues

```bash
# Test database connectivity
sudo -u postgres psql -l
sudo -u eventmanager psql -d eventmanager -c "SELECT version();"

# Check PostgreSQL status
sudo systemctl status postgresql
```

### Nginx Issues

```bash
# Test nginx configuration
sudo nginx -t

# Check nginx status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log
```

### SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Renew certificate manually
sudo certbot renew

# Check renewal timer
sudo systemctl status certbot.timer
```

## 📊 Performance Optimization

### Database Performance

```sql
-- Create indexes for better performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_checkins_user_id ON checkins(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_checkins_created_at ON checkins(created_at);
```

### Nginx Optimization

Already included in the generated nginx configuration:
- Gzip compression
- Static file caching
- Rate limiting
- Proxy caching
- Security headers

### Application Monitoring

```bash
# Monitor system resources
htop

# Monitor database connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity WHERE datname = 'eventmanager';"

# Monitor disk usage
df -h
du -sh /var/www/event-manager/*
```

## 🔐 Security Checklist

- [ ] Strong database passwords
- [ ] JWT/Session secrets configured
- [ ] SSL certificate installed
- [ ] Firewall configured (UFW)
- [ ] Regular security updates
- [ ] Non-root application user
- [ ] File permissions secured
- [ ] Rate limiting enabled
- [ ] Security headers configured
- [ ] Database access restricted
- [ ] Regular backups scheduled

## 📞 Support

For issues with the Event Manager application:

1. Check logs: `sudo journalctl -u event-manager -n 100`
2. Verify configuration: Review `.env` file
3. Test connectivity: Use health check endpoint
4. Check resources: Monitor CPU, memory, disk usage

## 🔄 Migration from Replit

If migrating from an existing Replit deployment:

1. **Export Data**: Use Replit's database export feature
2. **Import Data**: Restore to your VPS PostgreSQL
3. **File Transfer**: Download and upload any uploaded files
4. **Domain Setup**: Update DNS to point to your VPS
5. **Testing**: Verify all functionality works

Your Event Manager application is now running independently on your VPS! 🎉