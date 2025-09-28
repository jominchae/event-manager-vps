# VPS Migration Guide - Removing Replit Dependencies

This guide covers migrating Event Manager from Replit to VPS by removing Replit-specific dependencies.

## 🔍 Identified Replit Dependencies

### Package Dependencies to Remove
```json
// In package.json devDependencies:
"@replit/vite-plugin-cartographer": "^0.3.0",
"@replit/vite-plugin-runtime-error-modal": "^0.0.3"
```

### Configuration Files to Update

#### 1. vite.config.ts
**Current (Replit-specific):**
```typescript
import runtimeErrorOverlay from "@replit/vite-plugin-runtime-error-modal";
// Conditional loading of cartographer plugin based on REPL_ID
```

**VPS-Ready Replacement:**
- Remove Replit plugin imports
- Remove `process.env.REPL_ID` conditional checks
- Add production build optimizations

#### 2. client/index.html
**Current (Replit-specific):**
```html
<script type="text/javascript" src="https://replit.com/public/js/replit-dev-banner.js"></script>
```

**VPS-Ready Replacement:**
- Remove Replit development banner script
- Add proper SEO meta tags
- Add Open Graph tags

### Code References
- **server/routes.ts**: `.replit` in skip lists (safe to keep)
- **server/auth.ts**: Comments referencing Replit auth (documentation only)

## 🚀 Migration Process

### Automatic Migration
Use the automated script for quick migration:

```bash
# Run the automatic Replit dependency removal
./scripts/remove-replit-deps.sh

# This will:
# 1. Backup current files
# 2. Replace package.json with VPS version
# 3. Update vite.config.ts
# 4. Update index.html
# 5. Reinstall dependencies
# 6. Test build
```

### Manual Migration
If you prefer manual control:

#### Step 1: Update Package Dependencies
```bash
# Remove Replit-specific packages
npm uninstall @replit/vite-plugin-cartographer @replit/vite-plugin-runtime-error-modal

# Copy VPS-ready package.json
cp vps-package.json package.json
npm install
```

#### Step 2: Update Vite Configuration
```bash
# Replace vite config with VPS version
cp vps-vite.config.ts vite.config.ts
```

#### Step 3: Update HTML Template
```bash
# Replace index.html with VPS version
cp vps-index.html client/index.html
```

#### Step 4: Verify Changes
```bash
# Test development build
npm run dev

# Test production build
npm run build

# Validate with deployment validator
./scripts/validate-deployment.sh
```

## ✅ Migration Verification

After migration, verify the following:

### Build Process
- [ ] `npm run dev` starts without errors
- [ ] `npm run build` completes successfully
- [ ] No Replit-related error messages
- [ ] All application features work

### Dependencies
- [ ] No `@replit/` packages in package.json
- [ ] No imports from Replit packages in code
- [ ] Build artifacts created properly

### Configuration
- [ ] vite.config.ts has no Replit plugins
- [ ] index.html has no Replit banner script
- [ ] Environment variables updated for VPS

## 🔧 New VPS-Ready Features

### Enhanced package.json Scripts
```json
{
  "build:clean": "rm -rf dist",
  "build:check": "tsc --noEmit && echo '✅ TypeScript check passed'",
  "build:client": "vite build && echo '✅ Client built successfully'",
  "build:server": "esbuild server/index.ts --platform=node --packages=external --bundle --format=esm --outdir=dist/server --outfile=dist/server/index.js",
  "build:verify": "node -e \"/* verification logic */\"",
  "start:prod": "npm run db:migrate && npm run start",
  "health": "curl -f http://localhost:5000/api/health || exit 1"
}
```

### Production-Optimized Vite Config
```typescript
export default defineConfig({
  plugins: [react()], // Clean, no Replit plugins
  build: {
    target: 'esnext',
    minify: 'esbuild',
    sourcemap: process.env.NODE_ENV !== 'production',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          ui: ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
          utils: ['clsx', 'tailwind-merge', 'date-fns'],
        },
      },
    },
  },
});
```

### SEO-Optimized HTML
```html
<head>
  <meta name="description" content="Professional event management system..." />
  <meta property="og:type" content="website" />
  <meta property="og:title" content="Event Manager - Maldives Tourism" />
  <!-- No Replit banner script -->
</head>
```

## 🔄 Rollback Process

If migration issues occur, restore from backups:

```bash
# Automatic rollback (if using the script)
cp package.json.replit-backup package.json
cp vite.config.ts.replit-backup vite.config.ts
cp client/index.html.replit-backup client/index.html

# Reinstall original dependencies
rm -rf node_modules package-lock.json
npm install
```

## 📋 Post-Migration Checklist

### Functionality Testing
- [ ] User authentication works
- [ ] Database connections established
- [ ] File uploads working
- [ ] Real-time chat functional
- [ ] Admin panel accessible
- [ ] Island check-ins working
- [ ] Equipment tracking operational

### Performance Testing
- [ ] Build time acceptable
- [ ] Bundle size optimized
- [ ] Page load speeds good
- [ ] API response times normal

### Security Testing
- [ ] JWT authentication working
- [ ] Session management secure
- [ ] File upload restrictions working
- [ ] CORS configured properly

### Deployment Testing
- [ ] Production build works
- [ ] Docker build successful
- [ ] VPS deployment scripts ready
- [ ] Health checks passing

## 🚀 Next Steps

After successful migration:

1. **Deploy to VPS**: Use deployment scripts from DEPLOYMENT-GUIDE.md
2. **Monitor Performance**: Set up monitoring and logging
3. **Configure SSL**: Set up Let's Encrypt certificates
4. **Backup Strategy**: Implement regular database backups
5. **Update DNS**: Point domain to VPS
6. **Go Live**: Switch traffic to VPS deployment

## ⚠️ Important Notes

- **Preserve Functionality**: All Event Manager features remain intact
- **No Data Loss**: Migration only affects dependencies, not data
- **Backwards Compatible**: Can revert to Replit if needed
- **Production Ready**: VPS version includes production optimizations
- **Security Enhanced**: Removes development-only Replit integrations

Your Event Manager is now completely independent of Replit and ready for professional VPS hosting! 🎉