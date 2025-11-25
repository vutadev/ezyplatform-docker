#!/bin/bash

# Set default values for database configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-blog}"
DB_TABLES_CREATE_MANUALLY="${DB_TABLES_CREATE_MANUALLY:-false}"
AUTO_START_WEB="${AUTO_START_WEB:-false}"

# Validate required environment variables
if [ -z "$DB_USERNAME" ]; then
    echo "Error: DB_USERNAME environment variable is required"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD environment variable is required"
    exit 1
fi

# Construct JDBC URL
JDBC_URL="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}"

# Update setup.properties with database configuration
SETUP_FILE="/app/ezyplatform/settings/setup.properties"

if [ -f "$SETUP_FILE" ]; then
    echo "Configuring database settings in $SETUP_FILE..."

    # Escape special characters for sed
    ESCAPED_JDBC_URL=$(echo "$JDBC_URL" | sed 's/[\/&]/\\&/g')
    ESCAPED_USERNAME=$(echo "$DB_USERNAME" | sed 's/[\/&]/\\&/g')
    ESCAPED_PASSWORD=$(echo "$DB_PASSWORD" | sed 's/[\/&]/\\&/g')

    # Update database configuration
    sed -i "s|^datasource\.jdbc_url=.*|datasource.jdbc_url=$ESCAPED_JDBC_URL|" "$SETUP_FILE"
    sed -i "s|^datasource\.username=.*|datasource.username=$ESCAPED_USERNAME|" "$SETUP_FILE"
    sed -i "s|^datasource\.password=.*|datasource.password=$ESCAPED_PASSWORD|" "$SETUP_FILE"
    sed -i "s|^tables\.create_manually=.*|tables.create_manually=$DB_TABLES_CREATE_MANUALLY|" "$SETUP_FILE"

    echo "Database configuration updated successfully"
    echo "  JDBC URL: $JDBC_URL"
    echo "  Username: $DB_USERNAME"
    echo "  Tables create manually: $DB_TABLES_CREATE_MANUALLY"
else
    echo "Warning: $SETUP_FILE not found, skipping database configuration"
fi

rm -rf /app/ezyplatform/admin/.runtime/* /app/ezyplatform/socket/.runtime/*  /app/ezyplatform/web/.runtime/*
bash cli.sh "start admin"

# Auto-start web service with health check monitoring
if [ "$AUTO_START_WEB" = "true" ]; then
    echo "AUTO_START_WEB enabled, starting web service..."
    bash cli.sh "start web"

    # Create health check script
    cat > /app/ezyplatform/web-health-check.sh << 'EOF'
#!/bin/bash
if ! curl -sf http://localhost:8080 > /dev/null 2>&1; then
    echo "[$(date)] Web health check failed, restarting web service..." >> /app/ezyplatform/logs/web-health-check.log
    cd /app/ezyplatform && bash cli.sh "start web"
fi
EOF
    chmod +x /app/ezyplatform/web-health-check.sh

    # Set up cron job (every minute)
    echo "* * * * * /app/ezyplatform/web-health-check.sh" | crontab -

    # Start cron daemon
    cron
    echo "Web health check cron job started (checking every minute)"
fi

while [ ! -f /app/ezyplatform/logs/admin-server.log ]; do
    sleep 1
done
tail -f /app/ezyplatform/logs/admin-server.log