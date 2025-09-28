#!/bin/bash
# Production Build Script for Event Manager VPS Deployment

set -e # Exit on any error

echo "🚀 Starting Event Manager production build..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Cleanup previous build
echo "🧹 Cleaning previous build..."
rm -rf dist
mkdir -p dist/server dist/public
print_status "Cleaned build directory"

# TypeScript type checking
echo "🔍 Running TypeScript checks..."
if npx tsc --noEmit; then
    print_status "TypeScript checks passed"
else
    print_error "TypeScript checks failed"
    exit 1
fi

# Build client (frontend)
echo "🏗️ Building client application..."
if npm run build > build-client.log 2>&1; then
    print_status "Client built successfully"
    # Move client build to correct location
    if [ -d "dist/public" ] && [ "$(ls -A dist/public)" ]; then
        print_status "Client files ready in dist/public"
    else
        print_error "Client build output not found"
        exit 1
    fi
else
    print_error "Client build failed - check build-client.log"
    exit 1
fi

# Build server
echo "🔧 Building server application..."
if npx esbuild server/index.ts \
    --platform=node \
    --packages=external \
    --bundle \
    --format=esm \
    --outdir=dist/server \
    --outfile=dist/server/index.js \
    --sourcemap; then
    print_status "Server built successfully"
else
    print_error "Server build failed"
    exit 1
fi

# Copy necessary files
echo "📁 Copying production assets..."
cp -r shared dist/ 2>/dev/null || print_warning "No shared directory to copy"
cp package.json dist/
cp .env.example dist/ 2>/dev/null || print_warning "No .env.example to copy"

# Create production start script
cat > dist/start.js << 'EOF'
// Production startup script
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Load package.json to verify build
try {
    const packageJson = JSON.parse(readFileSync(join(__dirname, 'package.json'), 'utf8'));
    console.log(`🚀 Starting ${packageJson.name} v${packageJson.version} in production mode`);
} catch (e) {
    console.log('🚀 Starting Event Manager in production mode');
}

// Set production environment
process.env.NODE_ENV = 'production';

// Start the server
import('./server/index.js');
EOF

print_status "Production assets copied"

# Create deployment info
cat > dist/build-info.json << EOF
{
    "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "nodeVersion": "$(node --version)",
    "platform": "$(uname -s)",
    "architecture": "$(uname -m)",
    "buildHash": "$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
}
EOF

# Verify build
echo "🔍 Verifying build..."
if [ -f "dist/server/index.js" ]; then
    print_status "Server bundle created"
else
    print_error "Server bundle missing"
    exit 1
fi

if [ -f "dist/public/index.html" ]; then
    print_status "Client bundle created"
else
    print_error "Client bundle missing"
    exit 1
fi

# Calculate bundle sizes
SERVER_SIZE=$(du -h dist/server/index.js | cut -f1)
CLIENT_SIZE=$(du -sh dist/public | cut -f1)

print_status "Build completed successfully!"
echo ""
echo "📊 Build Summary:"
echo "  Server bundle: $SERVER_SIZE"
echo "  Client bundle: $CLIENT_SIZE"
echo "  Build time: $(date)"
echo ""
echo "🚀 To start in production:"
echo "  cd dist && NODE_ENV=production node start.js"
echo ""
echo "🐳 Or use Docker:"
echo "  docker build -t event-manager ."
echo "  docker run -p 5000:5000 event-manager"

# Cleanup logs
rm -f build-client.log

exit 0