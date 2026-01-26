#!/bin/sh
set -e

echo "========================================"
echo "  OKOVISION LIGHT - Démarrage"
echo "========================================"

# ===========================================
# GÉNÉRATION DU config.php
# ===========================================
echo "[1/3] Génération de config.php..."

cat > /app/config.php << 'EOFPHP'
<?php
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
DEFINE('FTP_SERVEUR', '');
DEFINE('FTP_USER', '');
DEFINE('FTP_PASS', '');
DEFINE('REP_DEPOT', '');
DEFINE('GET_CHAUDIERE_DATA_BY_IP', ($config['get_data_from_chaudiere']==1)?true:false);
DEFINE('SEND_TO_WEB', false);
DEFINE('HAS_SILO', ($config['has_silo']==1)?true:false);
DEFINE('SILO_SIZE', (isset($config['silo_size']))?$config['silo_size']:'');
DEFINE('ASHTRAY', (isset($config['ashtray']))?$config['ashtray']:'');
DEFINE('CONTEXT', '/app');
date_default_timezone_set((isset($config['timezone']))?$config['timezone']:'Europe/Paris');
DEFINE('URL','/logfiles/pelletronic');
DEFINE('PATH','http://'.CHAUDIERE.URL.'/touch_');
DEFINE('EXTENTION','.csv');
DEFINE('CSVFILE',CONTEXT.'/_tmp/import.csv');
DEFINE('LOGFILE',CONTEXT.'/_logs/okovision.log');
DEFINE('CSV_DECIMAL',',');
DEFINE('CSV_SEPARATEUR',';');
DEFINE('BDD_DECIMAL','.');
DEFINE('TOKEN', $config['token'] ?? md5(uniqid()));
?>
EOFPHP

echo "    ✓ config.php généré"

# ===========================================
# GÉNÉRATION DU config.json
# ===========================================
echo "[2/3] Génération de config.json..."

CHAUDIERE_FULL="${CHAUDIERE_IP:-192.168.1.100}:${CHAUDIERE_PORT:-4321}"

cat > /app/config.json << EOFJSON
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
  "lang": "${LANG:-fr}",
  "token": "$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo 'default-token')"
}
EOFJSON

echo "    ✓ config.json généré"

# ===========================================
# RÉSUMÉ
# ===========================================
echo "[3/3] Configuration terminée"
echo ""
echo "========================================"
echo "  Chaudière : ${CHAUDIERE_FULL}"
echo "  MariaDB   : ${BDD_IP:-192.168.1.200}"
echo "  Database  : ${BDD_SCHEMA:-okovision}"
echo "========================================"
echo ""
echo "Démarrage crond..."

exec "$@"
