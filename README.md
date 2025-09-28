# 🏝️ Event Manager - Maldives Tourism Management System

[![Deploy to VPS](https://img.shields.io/badge/Deploy%20to%20VPS-Ready-brightgreen)](DEPLOYMENT-GUIDE.md)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue)](docker-compose.yml)
[![Cross Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)](#-installation-guide)
[![Production Ready](https://img.shields.io/badge/Production-Ready-success)](PRODUCTION-CHECKLIST.md)

Professional Event Management System designed specifically for Maldives tourism operations. Manage bookings, track equipment, coordinate island activities, and enhance guest experiences with real-time analytics and seamless operations.

**🚀 Now VPS-deployable! Complete independence from Replit with enterprise-grade hosting capabilities.**

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [🏗️ Architecture](#️-architecture)
- [💻 Installation Guide](#-installation-guide)
  - [Windows Installation](#windows-installation)
  - [macOS Installation](#macos-installation)
  - [Linux Installation](#linux-installation)
- [🚀 Deployment Options](#-deployment-options)
  - [Quick VPS Deployment](#quick-vps-deployment)
  - [Docker Deployment](#docker-deployment)
  - [Traditional Deployment](#traditional-deployment)
- [⚙️ Configuration](#️-configuration)
- [🔧 Development](#-development)
- [🔐 Security](#-security)
- [📊 Performance](#-performance)
- [📚 Documentation](#-documentation)
- [🆘 Troubleshooting](#-troubleshooting)

---

## ✨ Features

### 🎯 Core Tourism Management
- **Island Check-ins**: Track guest activities across multiple resort islands
- **Equipment Management**: Monitor diving gear, water sports equipment, and facilities
- **Real-time Chat**: WebSocket-powered guest communication system
- **Event Coordination**: Manage excursions, dining, and entertainment events
- **Analytics Dashboard**: Real-time operational insights and guest satisfaction metrics

### 🔒 Authentication & Security
- **JWT Authentication**: Secure token-based login system
- **Role-based Access**: Member, Coordinator, and Admin permission levels
- **Session Management**: Persistent sessions with PostgreSQL storage
- **Password Security**: bcrypt hashing with salt for user passwords

### 📱 Modern Web Application
- **Responsive Design**: Works perfectly on desktop, tablet, and mobile
- **Real-time Updates**: Live data synchronization across all devices
- **Offline Support**: Continues working with limited connectivity
- **Progressive Web App**: Install directly on devices for app-like experience

### 🏗️ VPS-Ready Infrastructure
- **Docker Support**: Complete containerization with orchestration
- **Auto-scaling**: Handles peak tourism seasons automatically
- **SSL/HTTPS**: Let's Encrypt integration for secure connections
- **Health Monitoring**: Built-in health checks and performance monitoring
- **Backup System**: Automated database and file backups

---

## 🏗️ Architecture

### Technology Stack
```
Frontend:  React 18 + TypeScript + Vite + TailwindCSS + Radix UI
Backend:   Node.js + Express + TypeScript + JWT Authentication
Database:  PostgreSQL (supports Neon serverless and standard PostgreSQL)
Storage:   Configurable (Local files, AWS S3, or other cloud providers)
Deploy:    Docker + Nginx + Let's Encrypt + Systemd
```

### System Requirements
```
Minimum:   2GB RAM, 10GB storage, 1 CPU core
Recommended: 4GB RAM, 50GB SSD, 2 CPU cores
Production:  8GB RAM, 100GB SSD, 4 CPU cores, SSL certificate
```

---

## 💻 Installation Guide

### Prerequisites (All Platforms)
- **Node.js 20+** (LTS recommended)
- **PostgreSQL 13+** (or use managed PostgreSQL like Neon)
- **Git** for version control

### Windows Installation

#### Option 1: Using Package Managers (Recommended)
```powershell
# Install with Chocolatey
choco install nodejs postgresql git

# Or install with Scoop
scoop install nodejs postgresql git

# Or install with winget
winget install OpenJS.NodeJS PostgreSQL.PostgreSQL Git.Git
```

#### Option 2: Manual Installation
1. **Install Node.js**
   - Download from [nodejs.org](https://nodejs.org/)
   - Choose "Windows Installer (.msi)" - LTS version
   - Run installer with default settings

2. **Install PostgreSQL**
   - Download from [postgresql.org/download/windows](https://www.postgresql.org/download/windows/)
   - Run installer, remember your password
   - Add PostgreSQL to PATH when prompted

3. **Install Git**
   - Download from [git-scm.com](https://git-scm.com/download/win)
   - Install with default settings

#### Setup Event Manager
```powershell
# Clone repository
git clone https://github.com/your-username/event-manager.git
cd event-manager

# Install dependencies
npm install

# Configure environment
copy production.env.template .env
# Edit .env with your settings using notepad or VS Code

# Setup database
.\scripts\setup-database.sh

# Start development server
npm run dev
```

### macOS Installation

#### Option 1: Using Homebrew (Recommended)
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install node postgresql git

# Start PostgreSQL service
brew services start postgresql
```

#### Option 2: Using MacPorts
```bash
# Install dependencies
sudo port install nodejs20 postgresql16-server git

# Initialize and start PostgreSQL
sudo -u postgres initdb -D /opt/local/var/db/postgresql16/defaultdb
sudo port load postgresql16-server
```

#### Option 3: Manual Installation
1. **Install Node.js**
   - Download from [nodejs.org](https://nodejs.org/)
   - Choose "macOS Installer (.pkg)" - LTS version

2. **Install PostgreSQL**
   - Download Postgres.app from [postgresapp.com](https://postgresapp.com/)
   - Or use the official installer from [postgresql.org](https://www.postgresql.org/download/macosx/)

3. **Install Git** (usually pre-installed)
   ```bash
   git --version  # Check if installed
   # If not installed, download from git-scm.com
   ```

#### Setup Event Manager
```bash
# Clone repository
git clone https://github.com/your-username/event-manager.git
cd event-manager

# Install dependencies
npm install

# Configure environment
cp production.env.template .env
# Edit .env with your preferred editor

# Setup database
./scripts/setup-database.sh

# Start development server
npm run dev
```

### Linux Installation

#### Ubuntu/Debian
```bash
# Update package list
sudo apt update

# Install Node.js (via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Git (usually pre-installed)
sudo apt install -y git

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### CentOS/RHEL/Fedora
```bash
# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs  # or yum install for older versions

# Install PostgreSQL
sudo dnf install -y postgresql postgresql-server postgresql-contrib

# Initialize and start PostgreSQL
sudo postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Install Git
sudo dnf install -y git
```

#### Arch Linux
```bash
# Install dependencies
sudo pacman -S nodejs npm postgresql git

# Initialize PostgreSQL
sudo -u postgres initdb -D /var/lib/postgres/data

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### Setup Event Manager (All Linux Distributions)
```bash
# Clone repository
git clone https://github.com/your-username/event-manager.git
cd event-manager

# Install dependencies
npm install

# Configure environment
cp production.env.template .env
# Edit .env with your preferred editor (nano, vim, code)

# Setup database
./scripts/setup-database.sh

# Start development server
npm run dev
```

---

## 🚀 Deployment Options

### Quick VPS Deployment
**One-command deployment to your VPS:**

```bash
# Deploy to any VPS (Ubuntu/Debian/CentOS)
./scripts/deploy-to-vps.sh --server YOUR_VPS_IP --domain your-domain.com --email your-email@domain.com
```

This script automatically:
- ✅ Installs all dependencies (Node.js, PostgreSQL, Nginx)
- ✅ Configures SSL certificate with Let's Encrypt
- ✅ Sets up systemd services
- ✅ Creates database and user
- ✅ Deploys and starts the application
- ✅ Configures Nginx reverse proxy
- ✅ Sets up monitoring and logging

### Docker Deployment

#### Simple Docker Setup
```bash
# Quick start with Docker
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

#### Production Docker Setup
```bash
# Production deployment with SSL and monitoring
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Includes:
# - Nginx reverse proxy with SSL
# - PostgreSQL with persistent storage
# - Application with health checks
# - Log aggregation and monitoring
```

#### Docker on Different Platforms

**Windows (PowerShell):**
```powershell
# Install Docker Desktop
winget install Docker.DockerDesktop

# Start application
docker compose up -d
```

**macOS:**
```bash
# Install Docker Desktop
brew install --cask docker

# Start application
docker compose up -d
```

**Linux:**
```bash
# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Start application
docker compose up -d
```

### Traditional Deployment

#### Manual VPS Setup
```bash
# 1. Build application
./scripts/build-production.sh

# 2. Configure environment
cp production.env.template .env
# Edit .env with production settings

# 3. Setup database
./scripts/setup-database.sh --name eventmanager --user eventmanager

# 4. Install system service
sudo cp event-manager.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable event-manager
sudo systemctl start event-manager

# 5. Configure Nginx
sudo cp nginx-event-manager.conf /etc/nginx/sites-available/event-manager
sudo ln -s /etc/nginx/sites-available/event-manager /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# 6. Setup SSL
sudo certbot --nginx -d your-domain.com
```

---

## ⚙️ Configuration

### Environment Variables

Create `.env` file from template:

**Windows (PowerShell):**
```powershell
copy production.env.template .env
```

**macOS/Linux:**
```bash
cp production.env.template .env
```

**Required Configuration:**
```bash
# Application
NODE_ENV=production
PORT=5000

# Database (choose one)
# Option 1: Local PostgreSQL
DATABASE_URL=postgresql://eventmanager:password@localhost:5432/eventmanager

# Option 2: Neon (managed PostgreSQL)
DATABASE_URL=postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/eventmanager

# Security (generate with: openssl rand -hex 32)
JWT_SECRET=your-32-character-secret-here
SESSION_SECRET=your-32-character-session-secret

# File Storage
STORAGE_TYPE=local
STORAGE_UPLOAD_DIR=./uploads

# Optional: AWS S3 Storage
# STORAGE_TYPE=s3
# AWS_REGION=us-east-1
# AWS_ACCESS_KEY_ID=your-key
# AWS_SECRET_ACCESS_KEY=your-secret
# AWS_S3_BUCKET=your-bucket
```

### Platform-Specific Configuration

#### Windows Paths
```bash
# Use Windows-style paths in .env
STORAGE_UPLOAD_DIR=C:\event-manager\uploads
LOG_DIR=C:\event-manager\logs
```

#### macOS/Linux Paths
```bash
# Use Unix-style paths in .env
STORAGE_UPLOAD_DIR=/var/www/event-manager/uploads
LOG_DIR=/var/log/event-manager
```

---

## 🔧 Development

### Development Setup (All Platforms)

```bash
# Install dependencies
npm install

# Start development server (with hot reload)
npm run dev

# Run TypeScript checks
npm run check

# Build for production
npm run build

# Start production server
npm run start
```

### Available Scripts

```json
{
  "dev": "Development server with hot reload",
  "build": "Production build with optimizations", 
  "start": "Start production server",
  "check": "TypeScript type checking",
  "db:push": "Sync database schema",
  "health": "Health check endpoint test",
  "clean": "Clean build artifacts"
}
```

### Platform-Specific Development

#### Windows Development
```powershell
# Use PowerShell or Command Prompt
npm run dev

# For Git Bash users
npm run dev
```

#### macOS/Linux Development
```bash
# Standard terminal
npm run dev

# With custom port
PORT=3000 npm run dev
```

### IDE Setup

**VS Code (Recommended)**
```bash
# Install recommended extensions
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension bradlc.vscode-tailwindcss
code --install-extension ms-vscode.vscode-json

# Open project
code .
```

**Other IDEs**
- **WebStorm**: Import as Node.js project
- **Sublime Text**: Use TypeScript and TailwindCSS packages
- **Vim/Neovim**: Use coc.nvim with TypeScript support

---

## 🔐 Security

### Security Features
- 🔒 **JWT Authentication**: Secure token-based authentication
- 🛡️ **CORS Protection**: Cross-origin request security
- 🔐 **Password Hashing**: bcrypt with salt for user passwords
- 📝 **Request Validation**: Zod schema validation for all inputs
- ⚡ **Rate Limiting**: API rate limiting to prevent abuse
- 🌐 **HTTPS/SSL**: Let's Encrypt integration
- 🔒 **Security Headers**: XSS protection, content type validation

### Security Checklist
- [ ] Strong JWT and session secrets configured (32+ characters)
- [ ] Database user with minimal required privileges
- [ ] Firewall configured (allow only ports 22, 80, 443)
- [ ] SSL certificate installed and auto-renewing
- [ ] Regular system security updates scheduled
- [ ] File upload restrictions configured
- [ ] Database backups encrypted and tested
- [ ] Environment variables secured (not in version control)

---

## 📊 Performance

### Performance Features
- ⚡ **Code Splitting**: Automatic vendor/UI/utils chunk splitting
- 🗜️ **Asset Compression**: Gzip compression for all static files
- 📦 **Bundle Optimization**: Tree shaking and minification
- 🚀 **CDN Ready**: Static assets optimized for CDN deployment
- 💾 **Database Optimization**: Connection pooling and query optimization
- 🔄 **Caching**: Multi-level caching (Nginx, Redis, browser)

### Platform Optimization

#### Windows
```powershell
# Enable long path support for npm
git config --system core.longpaths true

# Use Windows Build Tools if needed
npm install --global windows-build-tools
```

#### macOS
```bash
# Use latest Xcode command line tools
xcode-select --install

# Optimize npm for macOS
npm config set registry https://registry.npmjs.org/
```

#### Linux
```bash
# Optimize for production
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
```

---

## 📚 Documentation

### Complete Documentation Set
- 📖 **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)** - Complete VPS deployment guide
- 🔄 **[VPS-MIGRATION.md](VPS-MIGRATION.md)** - Migration from Replit
- 🐳 **[DOCKER-README.md](DOCKER-README.md)** - Docker deployment guide
- ✅ **[PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md)** - Pre-deployment checklist
- 🔧 **[API-DOCS.md](API-DOCS.md)** - API endpoint documentation

### Quick Reference

#### Health Check
```bash
curl http://localhost:5000/api/health
```

#### Database Connection Test
```bash
# Test connection
npm run db:push

# View database
psql $DATABASE_URL
```

#### Log Monitoring
```bash
# Application logs
journalctl -u event-manager -f

# Nginx logs (if using)
tail -f /var/log/nginx/access.log
```

---

## 🆘 Troubleshooting

### Common Issues & Solutions

#### 🔧 Installation Issues

**Node.js Version Problems**
```bash
# Check version
node --version  # Should be 20+

# Windows: Use nvm-windows
nvm install 20
nvm use 20

# macOS: Use nvm or homebrew
brew install node@20
brew link node@20

# Linux: Use nvm or package manager
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
```

**PostgreSQL Connection Issues**
```bash
# Test PostgreSQL connection
psql -U postgres -c "SELECT version();"

# Reset PostgreSQL password (if forgot)
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'newpassword';"

# Start PostgreSQL service
# Windows: net start postgresql-x64-16
# macOS: brew services start postgresql
# Linux: sudo systemctl start postgresql
```

**Permission Denied on Scripts**
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Windows: Run as Administrator if needed
# Right-click PowerShell -> "Run as Administrator"
```

#### 🚀 Deployment Issues

**Port Already in Use**
```bash
# Find process using port 5000
# Windows: netstat -ano | findstr :5000
# macOS/Linux: lsof -i :5000

# Kill process
# Windows: taskkill /PID [PID] /F
# macOS/Linux: kill -9 [PID]

# Or use different port
PORT=3000 npm run dev
```

**Docker Issues**
```bash
# Docker not running
# Windows/macOS: Start Docker Desktop
# Linux: sudo systemctl start docker

# Permission denied
sudo usermod -aG docker $USER
# Then logout and login again

# Clear Docker cache
docker system prune -f
```

**Database Migration Issues**
```bash
# Force push schema changes
npm run db:push --force

# Reset database (WARNING: destroys data)
dropdb eventmanager
createdb eventmanager
npm run db:push
```

#### 🌐 Production Issues

**SSL Certificate Problems**
```bash
# Renew Let's Encrypt certificate
sudo certbot renew

# Test SSL configuration
curl -I https://your-domain.com

# Check certificate expiry
openssl s_client -connect your-domain.com:443 | openssl x509 -noout -dates
```

**Performance Issues**
```bash
# Check system resources
# Windows: Task Manager or Get-Process
# macOS: Activity Monitor or top
# Linux: htop or top

# Monitor database connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# Check disk space
# Windows: Get-PSDrive
# macOS/Linux: df -h
```

### Platform-Specific Troubleshooting

#### Windows
```powershell
# Check Windows services
Get-Service -Name "*postgres*"

# View Windows Event Logs
Get-EventLog -LogName Application -Source "Event Manager"

# Network connectivity
Test-NetConnection -ComputerName your-domain.com -Port 443
```

#### macOS
```bash
# Check macOS services
brew services list | grep postgres

# View system logs
log show --predicate 'subsystem contains "event-manager"'

# Network connectivity
nc -zv your-domain.com 443
```

#### Linux
```bash
# Check systemd services
systemctl status postgresql event-manager nginx

# View system logs
journalctl -u event-manager --since "1 hour ago"

# Network connectivity
netstat -tlnp | grep :5000
```

### Getting Help

**Diagnostic Commands**
```bash
# Run deployment validation
./scripts/validate-deployment.sh localhost

# Check application health
curl -f http://localhost:5000/api/health

# Verify database connection
npm run check
```

**Support Channels**
- 📧 **GitHub Issues**: [Create an issue](https://github.com/your-username/event-manager/issues)
- 📚 **Documentation**: Check all .md files in repository
- 🔍 **Search Logs**: Use validation scripts for detailed diagnostics

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

```bash
# Fork and clone
git clone https://github.com/your-username/event-manager.git

# Create feature branch
git checkout -b feature/amazing-feature

# Commit changes
git commit -m 'Add amazing feature'

# Push and create PR
git push origin feature/amazing-feature
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🌟 Acknowledgments

- Built for the beautiful Maldives tourism industry 🏝️
- Powered by modern web technologies
- Designed for scalability and reliability
- Community-driven development

---

**🎉 Ready to transform your Maldives tourism operations!**

[![Get Started](https://img.shields.io/badge/Get%20Started-Now-brightgreen?style=for-the-badge)](DEPLOYMENT-GUIDE.md)

---

*Event Manager - Professional tourism management made simple, secure, and scalable.*