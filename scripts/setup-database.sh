#!/bin/bash
# Database Setup Script for Event Manager VPS Deployment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Default values
DB_NAME="eventmanager"
DB_USER="eventmanager"
DB_PASSWORD=""
DB_HOST="localhost"
DB_PORT="5432"
POSTGRES_VERSION="16"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --name|-n)
      DB_NAME="$2"
      shift 2
      ;;
    --user|-u)
      DB_USER="$2"
      shift 2
      ;;
    --password|-p)
      DB_PASSWORD="$2"
      shift 2
      ;;
    --host|-h)
      DB_HOST="$2"
      shift 2
      ;;
    --port)
      DB_PORT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --name, -n       Database name (default: eventmanager)"
      echo "  --user, -u       Database user (default: eventmanager)"
      echo "  --password, -p   Database password"
      echo "  --host, -h       Database host (default: localhost)"
      echo "  --port          Database port (default: 5432)"
      echo "  --help          Show this help"
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "🗄️ Setting up PostgreSQL database for Event Manager..."

# Generate password if not provided
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    print_warning "Generated random password: $DB_PASSWORD"
fi

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    print_error "PostgreSQL is not installed"
    echo "Install with: sudo apt install postgresql postgresql-contrib"
    exit 1
fi

# Check if PostgreSQL service is running
if ! systemctl is-active --quiet postgresql; then
    print_warning "Starting PostgreSQL service..."
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
fi

print_status "PostgreSQL service is running"

# Create database and user
print_info "Creating database and user..."
sudo -u postgres psql << EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '$DB_USER') THEN
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;

-- Create database if not exists
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;

-- Enable UUID extension
\c $DB_NAME
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create connection test
\c $DB_NAME $DB_USER
SELECT 'Database connection successful' as status;
EOF

if [ $? -eq 0 ]; then
    print_status "Database setup completed successfully"
else
    print_error "Database setup failed"
    exit 1
fi

# Create DATABASE_URL
DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"

# Output connection details
echo ""
print_status "Database Configuration:"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo ""
print_status "Add this to your .env file:"
echo "DATABASE_URL=\"$DATABASE_URL\""
echo ""

# Test connection
print_info "Testing database connection..."
if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
    print_status "Database connection test passed"
else
    print_error "Database connection test failed"
    exit 1
fi

# Configure PostgreSQL for production
print_info "Configuring PostgreSQL for production..."
POSTGRES_CONF="/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
PG_HBA_CONF="/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"

if [ -f "$POSTGRES_CONF" ]; then
    sudo cp "$POSTGRES_CONF" "$POSTGRES_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Optimize for production
    sudo tee -a "$POSTGRES_CONF" << EOF

# Event Manager Production Optimizations
# Added by setup-database.sh

# Connection Settings
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_min_messages = warning
log_min_error_statement = error
log_min_duration_statement = 1000

# Security
ssl = on
password_encryption = scram-sha-256
EOF

    print_status "PostgreSQL configured for production"
    
    # Restart PostgreSQL to apply changes
    sudo systemctl restart postgresql
    print_status "PostgreSQL restarted"
else
    print_warning "Could not find PostgreSQL configuration file"
fi

# Create backup script
print_info "Creating database backup script..."
cat > backup-database.sh << EOF
#!/bin/bash
# Database Backup Script for Event Manager

BACKUP_DIR="/var/backups/event-manager"
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="\$BACKUP_DIR/eventmanager_backup_\$DATE.sql"

# Create backup directory
mkdir -p \$BACKUP_DIR

# Create backup
PGPASSWORD="$DB_PASSWORD" pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME > \$BACKUP_FILE

# Compress backup
gzip \$BACKUP_FILE

echo "✅ Database backup created: \$BACKUP_FILE.gz"

# Keep only last 7 backups
find \$BACKUP_DIR -name "*.gz" -type f -mtime +7 -delete
EOF

chmod +x backup-database.sh
print_status "Backup script created: backup-database.sh"

# Create restore script
cat > restore-database.sh << EOF
#!/bin/bash
# Database Restore Script for Event Manager

if [ -z "\$1" ]; then
    echo "Usage: \$0 <backup-file.sql.gz>"
    exit 1
fi

BACKUP_FILE="\$1"

if [ ! -f "\$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: \$BACKUP_FILE"
    exit 1
fi

echo "⚠️ This will DROP and recreate the database!"
echo "Database: $DB_NAME"
echo "Backup: \$BACKUP_FILE"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "\$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Drop and recreate database
sudo -u postgres psql << EOSQL
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME OWNER $DB_USER;
EOSQL

# Restore from backup
if [[ "\$BACKUP_FILE" == *.gz ]]; then
    gunzip -c "\$BACKUP_FILE" | PGPASSWORD="$DB_PASSWORD" psql -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME
else
    PGPASSWORD="$DB_PASSWORD" psql -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_NAME < "\$BACKUP_FILE"
fi

echo "✅ Database restored successfully"
EOF

chmod +x restore-database.sh
print_status "Restore script created: restore-database.sh"

echo ""
print_status "Database setup completed!"
echo ""
print_info "Next steps:"
echo "  1. Add DATABASE_URL to your .env file"
echo "  2. Run database migrations: npm run db:push"
echo "  3. Set up regular backups with: ./backup-database.sh"
echo ""
print_info "Files created:"
echo "  📂 backup-database.sh - Daily backup script"
echo "  📂 restore-database.sh - Database restore script"

exit 0