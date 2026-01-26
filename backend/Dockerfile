##############################################
# Dockerfile Okovision
# Backend PHP + Frontend + Cron
# Base: PHP 8.2 Apache (compatible ARM64)
##############################################

FROM php:8.2-apache

LABEL maintainer="HomeLab"
LABEL description="Okovision - Monitoring chaudière Ökofen"

# ===========================================
# INSTALLATION DES DÉPENDANCES
# ===========================================
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    cron \
    curl \
    vim \
    && rm -rf /var/lib/apt/lists/*

# ===========================================
# EXTENSIONS PHP
# ===========================================
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    curl

# ===========================================
# CONFIGURATION APACHE
# ===========================================
RUN a2enmod rewrite

COPY backend/apache-okovision.conf /etc/apache2/sites-available/000-default.conf

# ===========================================
# COPIE DU CODE SOURCE
# ===========================================
COPY source/ /var/www/okovision/

# ===========================================
# SCRIPTS DE CONFIGURATION
# ===========================================
COPY backend/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# ===========================================
# CONFIGURATION CRON
# ===========================================
COPY backend/crontab /etc/cron.d/okovision-cron
RUN chmod 0644 /etc/cron.d/okovision-cron \
    && crontab /etc/cron.d/okovision-cron

# ===========================================
# PERMISSIONS
# ===========================================
RUN chown -R www-data:www-data /var/www/okovision \
    && chmod -R 755 /var/www/okovision \
    && chmod -R 777 /var/www/okovision/_logs \
    && chmod -R 777 /var/www/okovision/_tmp

# ===========================================
# WORKDIR & EXPOSE
# ===========================================
WORKDIR /var/www/okovision
EXPOSE 80

# ===========================================
# ENTRYPOINT
# ===========================================
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
