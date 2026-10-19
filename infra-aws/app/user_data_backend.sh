#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx git postgresql php-cli php-fpm php-pgsql php-mbstring php-xml

# Versión de PHP instalada (en Ubuntu 24.04 es 8.3)
PHPV=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

# Base de datos
systemctl enable --now postgresql
sudo -u postgres psql -c "CREATE USER asistenciau WITH PASSWORD '${db_password}';"
sudo -u postgres createdb -O asistenciau asistenciau

# Código del backend
git clone ${repo_url} /opt/repo
mkdir -p /var/www/backend-deploy
cp -r /opt/repo/backend-deploy/* /var/www/backend-deploy/
chown -R www-data:www-data /var/www/backend-deploy

# Tablas y usuario administrador
PGPASSWORD='${db_password}' psql -h 127.0.0.1 -U asistenciau -d asistenciau -f /var/www/backend-deploy/database/schema.sql
PGPASSWORD='${db_password}' psql -h 127.0.0.1 -U asistenciau -d asistenciau -c "INSERT INTO usuario (nombres, apellidos, genero, nombre_usuario, contrasena, tipo_usuario) VALUES ('Administrador', 'Principal', 'M', 'admin', '${admin_password}', 'admin') ON CONFLICT (nombre_usuario) DO NOTHING;"

# Variables de entorno para PHP-FPM
cat >> /etc/php/$PHPV/fpm/pool.d/www.conf <<EOF
env[APP_ENV] = production
env[APP_DEBUG] = 0
env[APP_TIMEZONE] = America/La_Paz
env[DB_HOST] = 127.0.0.1
env[DB_PORT] = 5432
env[DB_NAME] = asistenciau
env[DB_USER] = asistenciau
env[DB_PASSWORD] = ${db_password}
env[CORS_ALLOWED_ORIGINS] = http://${frontend_ip}
env[SESSION_NAME] = asistenciau_session
env[SESSION_SECURE] = ${session_secure}
EOF

# Nginx: usa el nginx.conf del repo, ajustando el socket de PHP
cp /var/www/backend-deploy/nginx.conf /etc/nginx/sites-available/asistenciau-api
sed -i -E "s#php[0-9.]+-fpm\.sock#php$PHPV-fpm.sock#" /etc/nginx/sites-available/asistenciau-api
rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/asistenciau-api /etc/nginx/sites-enabled/asistenciau-api

nginx -t
systemctl restart php$PHPV-fpm
systemctl reload nginx