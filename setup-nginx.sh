#!/bin/bash

# Script pour créer la configuration Nginx pour BeBiker
# Usage: ./setup-nginx.sh [domaine]

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
    echo "Usage: ./setup-nginx.sh [domaine]"
    echo "Exemple: ./setup-nginx.sh bebiker.com"
    exit 1
fi

echo "🔧 Création de la configuration Nginx pour $DOMAIN"

# Créer le fichier de configuration
sudo tee /etc/nginx/sites-available/bebiker > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    root /var/www/bebiker;
    index index.html;

    # Logs séparés pour ce site
    access_log /var/log/nginx/bebiker_access.log;
    error_log /var/log/nginx/bebiker_error.log;

    # Gestion des erreurs 404
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Optimisation des images
    location ~* \.(jpg|jpeg|png|gif|ico|jfif|webp)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
    }

    # Optimisation CSS
    location ~* \.css\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
    }

    # Sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Empêcher l'accès aux fichiers cachés
    location ~ /\. {
        deny all;
    }
}
EOF

echo "✅ Fichier de configuration créé"

# Activer le site
if [ ! -L /etc/nginx/sites-enabled/bebiker ]; then
    sudo ln -s /etc/nginx/sites-available/bebiker /etc/nginx/sites-enabled/
    echo "✅ Site activé"
else
    echo "⚠️  Le site était déjà activé"
fi

# Tester la configuration
echo "🔍 Test de la configuration Nginx..."
if sudo nginx -t; then
    echo "✅ Configuration valide"
    echo "🔄 Rechargement de Nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx rechargé"
    echo "🌐 Votre site sera accessible sur http://$DOMAIN"
else
    echo "❌ Erreur dans la configuration"
    exit 1
fi

echo ""
echo "🎉 Configuration Nginx terminée !"
echo "📝 Prochaines étapes :"
echo "   1. Transférer vos fichiers vers /var/www/bebiker"
echo "   2. Configurer SSL avec : sudo certbot --nginx -d $DOMAIN" 