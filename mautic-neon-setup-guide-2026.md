# Neon PostgreSQL + Mautic Setup Guide (2026)

## Table of Contents
1. [Neon Free Tier Overview](#neon-free-tier-overview)
2. [Capacity Planning](#capacity-planning)
3. [Creating a Neon Project](#creating-a-neon-project)
4. [Connection String Setup](#connection-string-setup)
5. [Testing the Connection](#testing-the-connection)
6. [Mautic Configuration](#mautic-configuration)
7. [Optimization Tips](#optimization-tips)
8. [Monitoring & Scaling](#monitoring--scaling)

---

## Neon Free Tier Overview

### Storage & Compute Limits (2026)

| Resource | Free Tier | Launch Tier | Scale Tier |
|----------|-----------|-------------|-----------|
| **Storage** | 0.5 GB per project | Pay per GB ($0.35/GB-month) | Pay per GB ($0.35/GB-month) |
| **Compute** | 100 CU-hours/month | Pay per CU-hour ($0.106) | Pay per CU-hour ($0.222) |
| **Max Compute Size** | Up to 2 CU (8 GB RAM) | Up to 16 CU (64 GB) | Up to 56 CU (224 GB) |
| **Projects** | 100 maximum | Unlimited | Unlimited |
| **Branches/Project** | 10 branches | 10 branches | Unlimited |

### Connection & Query Limits

| Feature | Free Tier | Paid Tiers |
|---------|-----------|-----------|
| **Connections** | No hard limit (managed via PgBouncer 1.25.1) | Connection pooling included |
| **Monthly Active Users** | Up to 60,000 (Neon Auth) | Up to 1M (Launch), Unlimited (Scale) |
| **Scale-to-Zero** | Yes (after 5 min idle, cannot disable) | Available on Launch/Scale |
| **Query Performance** | Standard Postgres 14-18 | Enhanced SLAs on Scale plan |

### Backup & Data Protection (2026)

| Feature | Free Tier | Launch Tier | Scale Tier |
|---------|-----------|-------------|-----------|
| **Point-in-Time Restore (PITR)** | 6-hour window max | Up to 7 days | Up to 30 days |
| **Change History Limit** | 1 GB max | Unlimited | Unlimited |
| **Manual Snapshots** | 1 snapshot | 10 snapshots | 10 snapshots |
| **Automated Backups** | Not available | Available | Available |
| **Metrics Retention** | 1 day dashboard | 7 days | 30 days |

### When Free Tier Scales to Paid

**No hard cutoff** — Neon uses usage-based billing with no minimum monthly fee:

1. **Storage Exceeded**: Free tier allows 0.5 GB. If you exceed this, you're charged $0.35/GB-month for overage
2. **Compute Exceeded**: Free tier includes 100 CU-hours/month. Once exhausted, additional compute costs $0.106/CU-hour (Launch) or $0.222/CU-hour (Scale)
3. **Other Metrics**: Egress (5 GB/month free), Monthly Active Users (60K free), extra branches
4. **Automatic Upgrade**: No automatic upgrade required—you're billed only for what you use beyond free limits

**Typical Mautic Sizing**:
- Small instance (< 100K contacts): ~0.2 GB storage, ~30 CU-hours/month → **Free tier suitable**
- Medium instance (100K-500K contacts): ~1-2 GB storage, ~60 CU-hours/month → **Upgrade to Launch ($15-30/month)**
- Large instance (500K+ contacts): ~5+ GB storage, ~150+ CU-hours/month → **Scale plan or dedicated infrastructure**

---

## Capacity Planning

### Estimating Mautic Storage Needs

Mautic's database schema includes:
- Contact records: ~1-2 KB per contact
- Email history: ~100-500 bytes per email sent
- Form submissions: ~1-3 KB per submission
- Segment data: ~500 bytes per segment membership
- Activity logs: ~200-300 bytes per action

**Quick Sizing Formula**:
```
Total GB ≈ (Contacts × 0.002 KB) + (Emails Sent × 0.0003 KB) + (Other Data × 0.001 KB)

Examples:
- 50K contacts + 500K emails + logs = (50,000 × 0.002) + (500,000 × 0.0003) = 250 MB (fits Free tier)
- 200K contacts + 2M emails + logs = (200,000 × 0.002) + (2,000,000 × 0.0003) = 800 MB (upgrade to Launch)
```

### Estimating Compute Usage

Mautic workloads breakdown:
- **Email campaigns**: Spikes during send cycles (typically 0.05-0.2 CU-hours per 100K emails)
- **Contact segmentation**: Recurring calculations (0.1-0.3 CU-hours per 100K contacts)
- **API calls**: Lightweight (0.01-0.05 CU-hours per 10K calls)
- **UI/Dashboard**: Minimal (0.02-0.05 CU-hours per day)

**Estimated Monthly Consumption**:
- Lightweight (newsletters only): 20-40 CU-hours
- Standard (campaigns + API): 40-80 CU-hours
- Heavy (large campaigns + API + analytics): 80-150+ CU-hours

---

## Creating a Neon Project

### Step 1: Sign Up for Neon

1. Visit [https://neon.com](https://neon.com)
2. Click **"Get Started"** → Choose **Free** plan
3. Sign up with GitHub, Google, or email
4. Verify your email address

### Step 2: Create a New Project

```bash
# After logging in, you'll see the dashboard
# Click "New Project" button
```

Configuration screen:
```
Project Name:        mautic-prod (or your instance name)
PostgreSQL Version:  17.8 (latest, recommended for Mautic)
Region:              Choose closest to your Mautic server
                     (e.g., us-east-1, eu-west-1)
Database Name:       mautic (default)
```

### Step 3: Create Database Role

After project creation:
1. Go to **Settings** → **Roles**
2. Click **"New Role"**
   - Role Name: `mautic_user`
   - Inherit Privileges: Enable
   - Login Allowed: Enable
   - Connection Limit: 100 (recommended for Mautic)

3. Set password: Use 32+ character random password
   ```bash
   # Generate strong password
   openssl rand -base64 32
   # Example: Xt7qK2mP9nL8vF3jH5bQ1rW6xY4zA0sC=
   ```

### Step 4: Create Database for Mautic

```sql
-- Connect as default role (postgres)
-- In Neon console: SQL Editor

CREATE DATABASE mautic
  OWNER mautic_user
  ENCODING 'UTF8'
  LC_COLLATE='en_US.UTF-8'
  LC_CTYPE='en_US.UTF-8';

-- Grant privileges
GRANT CONNECT ON DATABASE mautic TO mautic_user;
GRANT CREATE ON DATABASE mautic TO mautic_user;

-- Set search_path for Mautic
ALTER DATABASE mautic SET search_path TO public;
```

---

## Connection String Setup

### Extracting Your Connection String

**In Neon Console** (https://console.neon.com):

1. Navigate to **Project Settings** → **Connection string**
2. You'll see the full connection string:

```
postgresql://[user]:[password]@[host]/[database]?sslmode=require
```

**Components Breakdown**:

| Component | Example | Purpose |
|-----------|---------|---------|
| `user` | `mautic_user` | Database role created in Step 3 |
| `password` | `Xt7qK2mP9nL8vF3...` | Role password |
| `host` | `ep-cool-dog-12345.us-east-1.pg.neon.tech` | Neon endpoint URL |
| `database` | `mautic` | Database name |
| `sslmode` | `require` | SSL/TLS enforcement (always required for Neon) |

### Safe Storage of Credentials

**Option 1: Environment Variables (Recommended)**

```bash
# In your server's environment file (.env or systemd service)
DB_HOST="ep-cool-dog-12345.us-east-1.pg.neon.tech"
DB_PORT="5432"
DB_USER="mautic_user"
DB_PASSWORD="Xt7qK2mP9nL8vF3jH5bQ1rW6xY4zA0sC="
DB_NAME="mautic"
DB_DRIVER="pdo_pgsql"
```

**Option 2: Docker Compose (.env file)**

```dockerfile
# .env
MAUTIC_DB_HOST=ep-cool-dog-12345.us-east-1.pg.neon.tech
MAUTIC_DB_PORT=5432
MAUTIC_DB_USER=mautic_user
MAUTIC_DB_PASSWORD=Xt7qK2mP9nL8vF3jH5bQ1rW6xY4zA0sC=
MAUTIC_DB_NAME=mautic
MAUTIC_DB_DRIVER=pdo_pgsql
MAUTIC_DB_CHARSET=utf8mb4
```

**Option 3: Mautic Configuration File**

For traditional Mautic installation at `mautic/app/config/local.php`:

```php
<?php
// Neon PostgreSQL Configuration
$parameters = array(
    'database_driver'   => 'pdo_pgsql',      // PostgreSQL driver
    'database_host'     => 'ep-cool-dog-12345.us-east-1.pg.neon.tech',
    'database_port'     => 5432,
    'database_user'     => 'mautic_user',
    'database_password' => 'Xt7qK2mP9nL8vF3jH5bQ1rW6xY4zA0sC=',
    'database_name'     => 'mautic',
    'database_table_prefix' => 'mt_',
    'database_charset'  => 'utf8mb4',
);
```

**Never commit credentials to Git**:
```bash
# Add to .gitignore
echo ".env" >> .gitignore
echo "app/config/local.php" >> .gitignore
echo ".env.local" >> .gitignore
```

---

## Testing the Connection

### Test 1: Command Line (psql)

```bash
# Install PostgreSQL client tools (if needed)
# Ubuntu/Debian
sudo apt-get install postgresql-client

# macOS
brew install postgresql

# Test connection
psql -h ep-cool-dog-12345.us-east-1.pg.neon.tech \
     -U mautic_user \
     -d mautic \
     -c "SELECT version();"

# Expected output:
# PostgreSQL 17.8 on x86_64-pc-linux-gnu...
```

### Test 2: PHP PDO Connection

```php
<?php
// test-connection.php

$dsn = 'pgsql:host=ep-cool-dog-12345.us-east-1.pg.neon.tech;port=5432;dbname=mautic;sslmode=require';
$user = 'mautic_user';
$password = 'Xt7qK2mP9nL8vF3jH5bQ1rW6xY4zA0sC=';

try {
    $pdo = new PDO($dsn, $user, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5,
    ]);

    $stmt = $pdo->query('SELECT version();');
    $version = $stmt->fetch(PDO::FETCH_ASSOC);

    echo "✓ Connection successful!\n";
    echo "PostgreSQL Version: " . $version['version'] . "\n";

} catch (PDOException $e) {
    echo "✗ Connection failed: " . $e->getMessage() . "\n";
    exit(1);
}
?>
```

**Run test**:
```bash
php test-connection.php
```

### Test 3: Docker Compose Connection

```bash
# If using Docker, test from container
docker-compose exec mautic php -r "
\$dsn = 'pgsql:host=\$_ENV[\"DB_HOST\"];dbname=\$_ENV[\"DB_NAME\"]';
try {
    \$pdo = new PDO(\$dsn, \$_ENV['DB_USER'], \$_ENV['DB_PASSWORD']);
    echo 'Connection successful!';
} catch (Exception \$e) {
    echo 'Failed: ' . \$e->getMessage();
}
"
```

### Test 4: Connection Pool Verification

```bash
# Check current connections in Neon console
# SQL Editor: SELECT count(*) FROM pg_stat_activity;

# Expected: 1-5 connections for idle Mautic instance
# If > 20, you may need to adjust PgBouncer settings
```

### Test 5: SSL/TLS Verification

```bash
# Verify Neon requires SSL
psql -h ep-cool-dog-12345.us-east-1.pg.neon.tech \
     -U mautic_user \
     -d mautic \
     -v sslmode=disable \
     -c "SELECT 1;"

# Expected: FATAL error (SSL required)

# Correct way (with SSL)
psql -h ep-cool-dog-12345.us-east-1.pg.neon.tech \
     -U mautic_user \
     -d mautic \
     -v sslmode=require \
     -c "SELECT 1;"

# Expected: Success
```

---

## Mautic Configuration

### Step 1: Install Mautic Base

```bash
# Using Composer
composer create-project mautic/recommended-project mautic

# Using Docker
docker-compose up -d
```

### Step 2: Configure Database Connection

**For Traditional Installation**:

1. Run Mautic installer: `http://your-mautic-url/installer`
2. When prompted for database settings:
   - **Driver**: PostgreSQL (pdo_pgsql)
   - **Host**: `ep-cool-dog-12345.us-east-1.pg.neon.tech`
   - **Port**: `5432`
   - **Name**: `mautic`
   - **User**: `mautic_user`
   - **Password**: Your generated password
   - **Table Prefix**: `mt_` (optional, for multi-instance)

**For Docker Installation**:

```yaml
# docker-compose.yml
version: '3.8'

services:
  mautic:
    image: mautic/mautic:5-apache
    environment:
      MAUTIC_DB_DRIVER: pdo_pgsql
      MAUTIC_DB_HOST: ep-cool-dog-12345.us-east-1.pg.neon.tech
      MAUTIC_DB_PORT: 5432
      MAUTIC_DB_NAME: mautic
      MAUTIC_DB_USER: mautic_user
      MAUTIC_DB_PASSWORD: Xt7qK2mP9nL8vF3jH5bQ1rW6xY4zA0sC=
      MAUTIC_DB_CHARSET: utf8mb4
      MAUTIC_TRUSTED_HOSTS: "your-domain.com,www.your-domain.com"
    ports:
      - "80:80"
    volumes:
      - mautic_data:/var/www/html
    restart: unless-stopped

volumes:
  mautic_data:
```

### Step 3: Initialize Database Schema

```bash
# After connection is verified, run migrations
bin/console doctrine:migrations:migrate

# Create first admin user
bin/console mautic:user:create \
  --email=admin@example.com \
  --username=admin \
  --password=SecurePassword123! \
  --role=admin

# Build cache
bin/console cache:clear
bin/console cache:warmup
```

### Step 4: Configure Required PostgreSQL Extensions

```sql
-- Connect as default role
-- These extensions improve Mautic performance on PostgreSQL

-- UUID support (optional, for modern app design)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- JSON/JSONB support (if Mautic uses custom fields)
CREATE EXTENSION IF NOT EXISTS "json";

-- Full-text search
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- Grant to Mautic user
GRANT USAGE ON SCHEMA public TO mautic_user;
GRANT CREATE ON SCHEMA public TO mautic_user;
```

### Step 5: Verify Installation

```bash
# Test dashboard access
curl -I http://localhost/s/dashboard

# Should return 200 OK (after login redirect)

# Check database size
psql -h ep-cool-dog-12345.us-east-1.pg.neon.tech \
     -U mautic_user \
     -d mautic \
     -c "SELECT pg_size_pretty(pg_database_size('mautic'));"
```

---

## Optimization Tips

### 1. Optimize Mautic for Neon's Scale-to-Zero

Neon automatically suspends after 5 minutes of inactivity (cannot be disabled on free tier). Mautic sends periodic health checks to keep the instance warm:

```bash
# Reduce unnecessary database queries by disabling unused plugins
bin/console plugin:list
bin/console plugin:disable --plugin=<plugin-name>

# Recommended disabled plugins (if not using):
# - MauticContactLedgerBundle
# - MauticFullContactPlugin
# - MauticGrpcBundle
```

### 2. Optimize Segment Queries

Mautic segments can be resource-intensive. Optimize them:

```php
// In app/config/local.php or environment
$parameters = array(
    // Limit segment rebuild frequency
    'segment_rebuild_batch_size' => 500,      // Process 500 contacts per batch
    'segment_rebuild_sleep' => 1,             // 1 second between batches

    // Disable real-time segment updates (rebuild on schedule instead)
    'update_contact_on_segment_change' => false,
);
```

### 3. Enable Query Caching

```php
// app/config/local.php
$parameters = array(
    'doctrine_cache_driver' => 'redis',  // or 'array' for testing
    'cache_dir' => '%kernel.cache_dir%',
    'logs_dir' => '%kernel.logs_dir%',
);
```

### 4. Limit Email Campaign Batch Size

Large email campaigns consume significant compute. Configure batching:

```php
// In Email Queue Service
// Reduce from default 1000 to 100-200 per batch
$parameters = array(
    'email_batch_size' => 200,  // Send 200 emails per queue run
    'email_queue_mode' => 'batch',  // vs 'immediate' for large lists
);
```

### 5. Monitor Connection Pool Usage

```sql
-- Check connection usage
SELECT
    application_name,
    count(*) as connection_count
FROM pg_stat_activity
GROUP BY application_name
ORDER BY connection_count DESC;

-- Expected for Mautic: 2-5 active, 1-3 idle connections
-- If > 20, adjust PgBouncer in Neon settings
```

### 6. Optimize Large Contact Imports

```bash
# Import contacts in smaller batches
# For 100K contacts, use batch size of 5,000

# Use CSV import with validation disabled for speed
bin/console mautic:import:data \
  --file=contacts.csv \
  --batch-size=5000 \
  --skip-validation
```

### 7. Archive Old Data

```bash
# Mautic can archive old email/activity logs
bin/console mautic:email:archive --days=90

# Remove old campaign records
bin/console mautic:campaigns:archive --days=180
```

---

## Monitoring & Scaling

### Monitoring Neon Usage

**In Neon Console** (https://console.neon.com):

1. **Project Overview**:
   - Current storage usage (GB)
   - CU-hours used this month
   - Data transfer (egress) usage

2. **Metrics Dashboard**:
   - Query performance (p50, p95, p99 latency)
   - Connection count over time
   - Cache hit ratio

3. **Activity Log**:
   - Query execution patterns
   - Long-running queries
   - Connection spikes

### Setting Up Alerts

```bash
# Monitor free tier limits via automation
# Option 1: Neon API polling
curl -H "Authorization: Bearer YOUR_NEON_API_KEY" \
     https://console.neon.com/api/v1/projects/PROJECT_ID

# Option 2: Using Mautic's monitoring
# Configure cron job to check Neon API hourly
```

### Scaling Timeline

| Metric | Free Tier Limit | When to Upgrade |
|--------|-----------------|-----------------|
| Storage | 0.5 GB | When > 0.4 GB (20% buffer) |
| CU-hours | 100/month | When > 80/month |
| Contacts | ~250K | 100K+ contacts → Launch tier |
| Monthly Sends | ~5M emails | >5M emails/month → Launch tier |
| Concurrent Users | No hard limit | >100 concurrent → Scale tier |

### Upgrading to Launch Tier

When free tier limits approach:

```bash
# 1. In Neon Console, navigate to Settings → Billing
# 2. Click "Upgrade to Launch Plan"
# 3. No database migration needed—same connection string works
# 4. Billing starts at $15/month (usage-based, varies by actual consumption)

# Connection string remains unchanged:
# postgresql://mautic_user:password@ep-cool-dog-12345.us-east-1.pg.neon.tech/mautic?sslmode=require
```

### Backup Strategy for Production

```bash
# Even on free tier, take manual snapshots regularly
# In Neon Console: Branches → main → Create snapshot

# For production Mautic, also use pg_dump
pg_dump -h ep-cool-dog-12345.us-east-1.pg.neon.tech \
        -U mautic_user \
        -d mautic \
        --no-password \
        > mautic-backup-$(date +%Y%m%d-%H%M%S).sql

# Schedule daily via cron
# 0 2 * * * /path/to/backup-script.sh >> /var/log/mautic-backup.log 2>&1
```

### Performance Tuning for Neon

```sql
-- Enable monitoring
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- Log queries > 1 second

-- Adjust work_mem for better sorting
ALTER SYSTEM SET work_mem = '16MB';

-- Optimize autovacuum for email tables
ALTER TABLE mt_email_stats SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_analyze_scale_factor = 0.005
);

-- Reload configuration
SELECT pg_reload_conf();
```

---

## Troubleshooting Common Issues

### Issue 1: "Connection timeout" / "Scale-to-Zero Suspension"

**Problem**: Mautic can't connect after idle period

**Solution**:
```php
// Add connection retry logic in Mautic configuration
$parameters = array(
    'doctrine_connection_options' => array(
        'connect_timeout' => 10,
        'timeout' => 10,
        'retries' => 3,
    ),
);

// Or enable persistent connections (not recommended for scale-to-zero)
```

### Issue 2: "SSL connection required"

**Problem**: Connection fails without SSL

**Solution**:
```bash
# Ensure sslmode=require in connection string
MAUTIC_DB_HOST="ep-cool-dog-12345.us-east-1.pg.neon.tech?sslmode=require"

# For PDO, add SSL option
$dsn = 'pgsql:host=...;sslmode=require';
```

### Issue 3: "Too many connections"

**Problem**: Connection pool exhausted

**Solution**:
```sql
-- Increase connection limit for mautic_user
ALTER ROLE mautic_user CONNECTION LIMIT 200;

-- Check for idle connections and terminate
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'mautic'
  AND state = 'idle'
  AND query_start < now() - interval '1 hour';
```

### Issue 4: Storage Limit Exceeded

**Problem**: Getting "disk full" errors despite low reported usage

**Solution**:
```bash
# Check actual usage breakdown
psql -h ep-cool-dog-12345.us-east-1.pg.neon.tech \
     -U mautic_user \
     -d mautic \
     -c "
     SELECT schemaname, tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
     FROM pg_tables
     WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
     ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
     LIMIT 20;"

# Archive/delete old email logs if exceeding 80% of quota
bin/console mautic:email:archive --days=60
```

---

## Security Best Practices

### 1. Secure Credential Storage

```bash
# Never store passwords in code
# Use environment variables (systemd services, docker secrets, etc.)

# For systemd service (/etc/systemd/system/mautic.service)
[Service]
EnvironmentFile=/etc/mautic/.env.secrets
ExecStart=/usr/bin/php -r "..."
```

### 2. Restrict Database Role Permissions

```sql
-- Create read-only role for backups
CREATE ROLE mautic_backup WITH LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE mautic TO mautic_backup;
GRANT USAGE ON SCHEMA public TO mautic_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO mautic_backup;

-- Create limited API user (if using direct DB queries)
CREATE ROLE mautic_api WITH LOGIN PASSWORD '...';
GRANT CONNECT ON DATABASE mautic TO mautic_api;
GRANT SELECT ON mt_leads, mt_tokens TO mautic_api;
```

### 3. Enable SSL Certificate Pinning

```php
// For enhanced security (optional)
$options = [
    'ssl_verify_peer' => true,
    'ssl_ca_file' => '/path/to/ca-bundle.crt',
];
```

### 4. Rotate Credentials Regularly

```bash
# Change password every 90 days
# In Neon Console: Settings → Roles → mautic_user → Change password

# Update Mautic configuration with new password
# Restart Mautic service
systemctl restart mautic
```

### 5. Enable Query Logging for Audit

```sql
-- Log all DDL statements (schema changes)
ALTER DATABASE mautic SET log_statement = 'ddl';

-- View logs via Neon console or:
SELECT * FROM pg_current_wal_lsn();
```

---

## References & Resources

- [Neon Official Documentation](https://neon.com/docs)
- [Neon Pricing & Plans (2026)](https://neon.com/pricing)
- [Mautic Official Documentation](https://docs.mautic.org)
- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [Neon API Documentation](https://api-docs.neon.com)
- [Community of Christ Neon Integration Setup (Feb 27, 2026)](https://neon.com/docs/changelog/2026-02-27)

---

## Quick Reference: Connection String Templates

### Basic Connection (Command Line)

```bash
psql 'postgresql://mautic_user:PASSWORD@ENDPOINT/mautic?sslmode=require'
```

### PHP PDO

```php
$dsn = 'pgsql:host=ENDPOINT;port=5432;dbname=mautic;sslmode=require';
$pdo = new PDO($dsn, 'mautic_user', 'PASSWORD');
```

### Mautic Docker

```bash
MAUTIC_DB_DRIVER=pdo_pgsql
MAUTIC_DB_HOST=ENDPOINT
MAUTIC_DB_PORT=5432
MAUTIC_DB_NAME=mautic
MAUTIC_DB_USER=mautic_user
MAUTIC_DB_PASSWORD=PASSWORD
```

### Backup Command

```bash
pg_dump -h ENDPOINT -U mautic_user -d mautic > backup.sql
```

**Replace `ENDPOINT` with your actual Neon endpoint, e.g., `ep-cool-dog-12345.us-east-1.pg.neon.tech`**

---

## Summary

This guide covers:
- **Neon free tier specifications** for 2026 (100 CU-hours, 0.5 GB storage)
- **Connection limits** and automatic scale-to-zero behavior
- **Backup retention** (6-hour PITR window on free tier)
- **Step-by-step setup** for creating projects, roles, and databases
- **Connection string extraction** with secure credential management
- **Comprehensive testing** (psql, PHP, Docker, SSL verification)
- **Mautic configuration** for both traditional and Docker installations
- **Optimization techniques** for scale-to-zero and email campaigns
- **Monitoring strategies** with scaling timeline and upgrade path
- **Security best practices** for production deployments

**Next Steps**: Create your Neon project, extract the connection string, and deploy Mautic using the Docker Compose or traditional installation method above.
