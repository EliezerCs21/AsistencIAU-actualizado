#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y nginx git

git clone ${repo_url} /opt/repo
mkdir -p /var/www/frontend-deploy
cp -r /opt/repo/frontend-deploy/* /var/www/frontend-deploy/

# Cambiar la URL del backend de Azure por la de este mismo servidor (/api)
sed -i "s#'https://[^']*azurewebsites.net/api'#'http://${public_ip}/api'#" /var/www/frontend-deploy/config/api.js

cat > /etc/nginx/sites-available/asistenciau-frontend <<'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/frontend-deploy;
    index index.html;

    location /api/ {
        proxy_pass http://${backend_ip}/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 10m;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/asistenciau-frontend /etc/nginx/sites-enabled/asistenciau-frontend
nginx -t
systemctl reload nginx