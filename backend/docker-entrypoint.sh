#!/bin/bash
set -e

echo "========================================"
echo "  OKOVISION - Démarrage du container"
echo "========================================"

echo "[1/5] Configuration PHP..."
cat > /usr/local/etc/php/conf.d/okovision.ini << 'EOFINI'
display_errors = Off
error_reporting = E_ALL & ~E_NOTICE & ~E_WARNING & ~E_DEPRECATED
session.auto_start = 0
output_buffering = 4096
EOFINI
echo "    ✓ PHP configuré"

echo "[2/5] Génération de config.php..."
cat > /var/www/okovision/config.php << 'EOFPHP'
<?php
if (!file_exists("config.json")) { header("Location: setup.php"); exit; }
require '_include/autoloader.class.php'; 
Autoloader::register(); 
$config = json_decode(file_get_contents("config.json"), true);
DEFINE('DEBUG', false);
DEFINE('VIEW_DEBUG', false);
DEFINE('CHAUDIERE', $config['chaudiere']);
DEFINE('BDD_IP', getenv('BDD_IP') ?: 'localhost');
DEFINE('BDD_USER', getenv('BDD_USER') ?: 'okovision');
DEFINE('BDD_PASS', getenv('BDD_PASS') ?: '');
DEFINE('BDD_SCHEMA', getenv('BDD_SCHEMA') ?: 'okovision');
DEFINE('TC_REF', $config['tc_ref']);
DEFINE('POIDS_PELLET_PAR_MINUTE', $config['poids_pellet']);
DEFINE('SURFACE_HOUSE', $config['surface_maison']);
DEFINE('FTP_SERVEUR', ''); DEFINE('FTP_USER', ''); DEFINE('FTP_PASS', ''); DEFINE('REP_DEPOT', '');
DEFINE('GET_CHAUDIERE_DATA_BY_IP', ($config['get_data_from_chaudiere']==1)?true:false);
DEFINE('SEND_TO_WEB', false);
DEFINE('HAS_SILO', ($config['has_silo']==1)?true:false);
DEFINE('SILO_SIZE', (isset($config['silo_size']))?$config['silo_size']:'');
DEFINE('ASHTRAY', (isset($config['ashtray']))?$config['ashtray']:'');
DEFINE('CONTEXT', '/var/www/okovision');
date_default_timezone_set((isset($config['timezone']))?$config['timezone']:'Europe/Paris');
DEFINE('URL','/logfiles/pelletronic');
DEFINE('PATH','http://'.CHAUDIERE.URL.'/touch_');
DEFINE('EXTENTION','.csv');
DEFINE('CSVFILE',CONTEXT.'/_tmp/import.csv');
DEFINE('LOGFILE',CONTEXT.'/_logs/okovision.log');
DEFINE('CSV_DECIMAL',','); DEFINE('CSV_SEPARATEUR',';'); DEFINE('BDD_DECIMAL','.');
DEFINE('TOKEN', $config['token'] ?? md5(uniqid()));
?>
EOFPHP
echo "    ✓ config.php généré"

echo "[3/5] Génération de config.json..."
CHAUDIERE_FULL="${CHAUDIERE_IP:-192.168.1.100}:${CHAUDIERE_PORT:-4321}"
cat > /var/www/okovision/config.json << EOFJSON
{
  "chaudiere": "${CHAUDIERE_FULL}",
  "tc_ref": "${TC_REF:-18}",
  "poids_pellet": "${POIDS_PELLET:-350}",
  "surface_maison": "${SURFACE_MAISON:-130}",
  "get_data_from_chaudiere": "1",
  "timezone": "${TIMEZONE:-Europe/Paris}",
  "send_to_web": "0",
  "has_silo": "${HAS_SILO:-1}",
  "silo_size": "${SILO_SIZE:-5000}",
  "ashtray": "${ASHTRAY:-1000}",
  "lang": "${OKOVISION_LANG:-fr}"
}
EOFJSON
echo "    ✓ config.json généré"

echo "[4/5] Permissions..."
chown -R www-data:www-data /var/www/okovision
chmod -R 755 /var/www/okovision
chmod -R 777 /var/www/okovision/_logs /var/www/okovision/_tmp
echo "    ✓ Permissions OK"

echo "[5/5] Démarrage cron..."
service cron start
echo "    ✓ Cron démarré"

echo ""
echo "========================================"
echo "  Chaudière : ${CHAUDIERE_FULL}"
echo "  MariaDB   : ${BDD_IP:-192.168.1.200}"
echo "  Langue    : ${OKOVISION_LANG:-fr}"
echo "========================================"
echo "Démarrage Apache..."

exec "$@"
