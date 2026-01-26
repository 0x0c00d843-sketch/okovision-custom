# Okovision Custom

Fork personnel d'[Okovision](https://github.com/stawen/okovision) avec dockerisation et indicateurs supplémentaires.

## Nouveautés

### Dockerisation complète
- Image PHP 8.2 + Apache + Cron
- Configuration via variables d'environnement
- Compatible Pi Zero 2W (build sur Pi 4 requis)

### Nouveaux indicateurs journaliers

| Indicateur | Description |
|------------|-------------|
| `tc_ext_moy` | Température moyenne (basée sur toutes les mesures) |
| `tc_ext_etendu` | Température lissée : 60% J + 30% J-1 + 10% J-2 |
| `djmoy` | Degrés-jour basé sur moyenne réelle |
| `dje` | Degrés-jour étendu (basé sur tc_ext_etendu) |
| `tps_comb` | Durée totale combustion (minutes) |
| `tps_cycle_complet` | Durée totale cycles (minutes) |
| `duree_moy_comb` | Durée moyenne combustion par cycle |
| `duree_moy_cycle` | Durée moyenne cycle complet |

## Installation

### Prérequis
- Docker et Docker Compose
- MariaDB accessible sur le réseau
- Chaudière Ökofen accessible

### Déploiement

1. Cloner le dépôt :
```bash
git clone https://github.com/0x0c00d843-sketcher/okovision-custom.git
cd okovision-custom
```

2. Configurer l'environnement :
```bash
cp .env.example .env
nano .env  # Modifier les valeurs
```

3. Builder l'image (sur Pi 4 ou PC, pas Pi Zero) :
```bash
docker build -f backend/Dockerfile -t okovision:latest .
```

4. Lancer :
```bash
docker compose up -d
```

### Migration des données existantes

1. Ajouter les colonnes à la base :
```sql
ALTER TABLE oko_resume_day
ADD COLUMN tc_ext_moy DECIMAL(4,2) AFTER tc_ext_min,
ADD COLUMN tc_ext_etendu DECIMAL(4,2) AFTER tc_ext_moy,
ADD COLUMN djmoy DECIMAL(6,2) AFTER dju,
ADD COLUMN dje DECIMAL(6,2) AFTER djmoy,
ADD COLUMN tps_comb SMALLINT AFTER nb_cycle,
ADD COLUMN tps_cycle_complet SMALLINT AFTER tps_comb,
ADD COLUMN duree_moy_comb DECIMAL(5,1) AFTER tps_cycle_complet,
ADD COLUMN duree_moy_cycle DECIMAL(5,1) AFTER duree_moy_comb;
```

2. Exécuter le script de migration :
```bash
docker exec okovision-app php /var/www/okovision/scripts/update_indicators.php
```

## Structure
```
okovision-custom/
├── .env.example          # Template configuration
├── docker-compose.yml    # Orchestration Docker
├── backend/
│   ├── Dockerfile        # Image PHP + Apache + Cron
│   ├── docker-entrypoint.sh
│   ├── apache-okovision.conf
│   └── crontab
└── source/               # Code Okovision modifié
    ├── _include/
    │   ├── okofen.class.php   # Modifié: nouveaux indicateurs
    │   └── rendu.class.php    # Modifié: nouvelles méthodes
    └── scripts/
        └── update_indicators.php  # Migration historique
```

## Codes status chaudière Ökofen

| Code | État |
|------|------|
| 0 | Off |
| 2 | Ignition (allumage) |
| 3 | Softstart |
| 4 | Heating Full Power (combustion) |
| 5 | Run On Time (extinction) |
| 11 | Error |
| 99 | Off |

## Crédits

- [Okovision original](https://github.com/stawen/okovision) par Stawen Dronek
