#!/bin/bash
# Deployment Validation Script for Event Manager

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️ $1${NC}"; }

# Configuration
SERVER_IP="${1:-localhost}"
DOMAIN="${2:-$SERVER_IP}"
PORT="${3:-5000}"
USE_HTTPS="${4:-false}"

if [ "$USE_HTTPS" = "true" ]; then
    PROTOCOL="https"
    DEFAULT_PORT="443"
else
    PROTOCOL="http"
    DEFAULT_PORT="80"
fi

BASE_URL="$PROTOCOL://$DOMAIN"
if [ "$PORT" != "80" ] && [ "$PORT" != "443" ]; then
    BASE_URL="$BASE_URL:$PORT"
fi

echo "🔍 Validating Event Manager deployment..."
print_info "Target: $BASE_URL"
print_info "Server: $SERVER_IP"
echo ""

ERRORS=0
WARNINGS=0

# Test function
test_endpoint() {
    local endpoint="$1"
    local expected_status="$2"
    local description="$3"
    local timeout="${4:-10}"
    
    echo -n "Testing $description... "
    
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s -w "%{http_code}" -o /tmp/test_response --max-time "$timeout" "$BASE_URL$endpoint" || echo "000")
        
        if [ "$response" = "$expected_status" ]; then
            echo -e "${GREEN}✅ OK ($response)${NC}"
            return 0
        else
            echo -e "${RED}❌ FAIL (got $response, expected $expected_status)${NC}"
            if [ -f /tmp/test_response ]; then
                echo "Response body:"
                cat /tmp/test_response | head -3
                echo ""
            fi
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ SKIP (curl not available)${NC}"
        ((WARNINGS++))
        return 2
    fi
}

# System checks
echo "🖥️ System Validation:"

# Check if server is reachable
if ping -c 1 -W 5 "$SERVER_IP" >/dev/null 2>&1; then
    print_status "Server is reachable"
else
    print_error "Server is not reachable"
    ((ERRORS++))
fi

# Check if port is open
if command -v nc >/dev/null 2>&1; then
    if nc -z -w5 "$SERVER_IP" "$PORT" >/dev/null 2>&1; then
        print_status "Port $PORT is open"
    else
        print_error "Port $PORT is not accessible"
        ((ERRORS++))
    fi
else
    print_warning "netcat not available - cannot test port connectivity"
    ((WARNINGS++))
fi

echo ""

# Application checks
echo "🚀 Application Validation:"

# Health check
if test_endpoint "/api/health" "200" "Health check"; then
    print_status "Application is healthy"
else
    print_error "Application health check failed"
    ((ERRORS++))
fi

# Login page
if test_endpoint "/api/login" "200" "Login page"; then
    print_status "Login endpoint accessible"
else
    print_error "Login endpoint failed"
    ((ERRORS++))
fi

# API authentication (should return 401)
if test_endpoint "/api/auth/user" "401" "API authentication"; then
    print_status "API authentication working"
else
    print_warning "API authentication response unexpected"
    ((WARNINGS++))
fi

# Static files
if test_endpoint "/" "200" "Main application page"; then
    print_status "Main application loads"
else
    print_error "Main application failed to load"
    ((ERRORS++))
fi

echo ""

# Security checks
echo "🔐 Security Validation:"

# Check HTTPS redirect (if domain provided)
if [ "$DOMAIN" != "$SERVER_IP" ] && [ "$USE_HTTPS" != "true" ]; then
    print_info "Testing HTTPS availability..."
    if curl -s --max-time 5 "https://$DOMAIN" >/dev/null 2>&1; then
        print_status "HTTPS is available"
        print_warning "Consider using HTTPS in production"
        ((WARNINGS++))
    else
        print_warning "HTTPS not available - ensure SSL certificate is configured"
        ((WARNINGS++))
    fi
fi

# Check security headers
print_info "Checking security headers..."
headers_response=$(curl -s -I "$BASE_URL" || echo "")

if echo "$headers_response" | grep -qi "x-frame-options"; then
    print_status "X-Frame-Options header present"
else
    print_warning "X-Frame-Options header missing"
    ((WARNINGS++))
fi

if echo "$headers_response" | grep -qi "x-content-type-options"; then
    print_status "X-Content-Type-Options header present"
else
    print_warning "X-Content-Type-Options header missing"
    ((WARNINGS++))
fi

echo ""

# Performance checks
echo "📊 Performance Validation:"

# Response time check
print_info "Testing response times..."
response_time=$(curl -o /dev/null -s -w "%{time_total}" "$BASE_URL/api/health" || echo "0")
response_time_ms=$(echo "$response_time * 1000" | bc -l 2>/dev/null || echo "$response_time")

if [ "$(echo "$response_time < 2" | bc -l 2>/dev/null)" = "1" ]; then
    print_status "Response time: ${response_time}s (good)"
elif [ "$(echo "$response_time < 5" | bc -l 2>/dev/null)" = "1" ]; then
    print_warning "Response time: ${response_time}s (acceptable)"
    ((WARNINGS++))
else
    print_error "Response time: ${response_time}s (slow)"
    ((ERRORS++))
fi

echo ""

# Database checks (if on same server)
if [ "$SERVER_IP" = "localhost" ] || [ "$SERVER_IP" = "127.0.0.1" ]; then
    echo "🗄️ Database Validation:"
    
    # Check PostgreSQL service
    if systemctl is-active --quiet postgresql 2>/dev/null; then
        print_status "PostgreSQL service is running"
    else
        print_error "PostgreSQL service is not running"
        ((ERRORS++))
    fi
    
    # Check database connectivity
    if sudo -u postgres psql -c "SELECT 1" >/dev/null 2>&1; then
        print_status "Database connection successful"
    else
        print_error "Database connection failed"
        ((ERRORS++))
    fi
    
    echo ""
fi

# Service checks (if on same server)
if [ "$SERVER_IP" = "localhost" ] || [ "$SERVER_IP" = "127.0.0.1" ]; then
    echo "⚙️ Service Validation:"
    
    # Check Event Manager service
    if systemctl is-active --quiet event-manager 2>/dev/null; then
        print_status "Event Manager service is running"
    else
        print_error "Event Manager service is not running"
        ((ERRORS++))
    fi
    
    # Check Nginx service
    if systemctl is-active --quiet nginx 2>/dev/null; then
        print_status "Nginx service is running"
    else
        print_warning "Nginx service is not running (direct access mode)"
        ((WARNINGS++))
    fi
    
    echo ""
fi

# Summary
echo "📋 Validation Summary:"
echo "==================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_status "All checks passed! 🎉"
    print_info "Your Event Manager deployment is working perfectly."
elif [ $ERRORS -eq 0 ]; then
    print_warning "$WARNINGS warning(s) found"
    print_info "Your Event Manager is working but has some recommendations."
else
    print_error "$ERRORS error(s) and $WARNINGS warning(s) found"
    print_info "Please fix the errors before going live."
fi

echo ""
print_info "Application URL: $BASE_URL"
print_info "Health Check: $BASE_URL/api/health"
print_info "Admin Panel: $BASE_URL/admin (after login)"
echo ""

if [ $ERRORS -gt 0 ]; then
    print_info "Troubleshooting tips:"
    echo "  • Check logs: journalctl -u event-manager -f"
    echo "  • Verify config: cat /var/www/event-manager/.env"
    echo "  • Test database: sudo -u eventmanager psql \$DATABASE_URL -c 'SELECT 1;'"
    echo "  • Restart service: systemctl restart event-manager"
fi

# Cleanup
rm -f /tmp/test_response

exit $ERRORS