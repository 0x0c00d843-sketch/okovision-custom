# Documentation Okovision Custom - Nouveaux Indicateurs

**Date :** 27 janvier 2026  
**Dépôt :** https://github.com/0x0c00d843-sketcher/okovision-custom  
**Machine :** homelab-okovision (Pi Zero 2W - 192.168.1.202)  
**Statut :** ✅ Fonctionnel et déployé

---

## 📋 Résumé du projet

Fork personnel d'Okovision (projet abandonné) avec :
- Dockerisation complète
- Ajout de 8 nouveaux indicateurs journaliers
- Script de migration pour l'historique (4 ans de données migrées)
- Interface frontend modifiée pour afficher les nouveaux indicateurs

---

## 📊 Nouveaux indicateurs ajoutés

### Table `oko_resume_day` - Nouvelles colonnes

| Indicateur | Type | Description |
|------------|------|-------------|
| `tc_ext_moy` | DECIMAL(4,2) | Température moyenne (AVG de toutes les mesures du jour) |
| `tc_ext_etendu` | DECIMAL(4,2) | Température lissée : 60%×J + 30%×J-1 + 10%×J-2 (inertie thermique) |
| `djmoy` | DECIMAL(6,2) | Degrés-jour basé sur tc_ext_moy : TC_REF - tc_ext_moy |
| `dje` | DECIMAL(6,2) | Degrés-jour étendu : TC_REF - tc_ext_etendu |
| `tps_comb` | SMALLINT | Durée totale combustion en minutes (status = 4) |
| `tps_cycle_complet` | SMALLINT | Durée totale cycles en minutes (status IN 2,3,4,5) |
| `duree_moy_comb` | DECIMAL(5,1) | Durée moyenne combustion par cycle |
| `duree_moy_cycle` | DECIMAL(5,1) | Durée moyenne cycle complet |

### Codes status chaudière Ökofen (source: doc Modbus officielle)

| Code | État |
|------|------|
| 0 | Off (arrêt) |
| 2 | Ignition (allumage) |
| 3 | Softstart (démarrage doux) |
| 4 | **Heating Full Power** (combustion) |
| 5 | Run On Time (fin de cycle) |
| 7 | Suction (aspiration pellets) |
| 8 | Ash (décendrage) |
| 11 | Error |
| 99 | Off |

### Formules de calcul

```
tc_ext_moy = AVG(col_tc_ext) sur la journée
djmoy = TC_REF - tc_ext_moy (si tc_ext_moy < TC_REF, sinon 0)

tc_ext_etendu = 0.6 × tc_ext_moy(J) + 0.3 × tc_ext_moy(J-1) + 0.1 × tc_ext_moy(J-2)
              (si J-1 ou J-2 n'existe pas, utiliser J à la place)
dje = TC_REF - tc_ext_etendu (si tc_ext_etendu < TC_REF, sinon 0)

tps_comb = COUNT minutes où status = 4
tps_cycle_complet = COUNT minutes où status IN (2, 3, 4, 5)
duree_moy_comb = tps_comb / nb_cycle
duree_moy_cycle = tps_cycle_complet / nb_cycle
```

---

## 📁 Fichiers modifiés

### Structure du dépôt

```
okovision-custom/
├── .env.example              # Template des variables d'environnement
├── .gitignore                # Exclusions Git
├── README.md                 # Documentation du projet
├── docker-compose.yml        # Orchestration Docker
├── docker-compose.light.yml  # Version légère (sans Apache)
├── backend/
│   ├── Dockerfile
│   ├── Dockerfile.light
│   ├── docker-entrypoint.sh
│   ├── docker-entrypoint-light.sh
│   ├── apache-okovision.conf
│   └── crontab
└── source/                   # Code Okovision modifié
    ├── _include/
    │   ├── okofen.class.php    # ✏️ MODIFIÉ: insertSyntheseDay()
    │   └── rendu.class.php     # ✏️ MODIFIÉ: nouvelles méthodes + API
    ├── install/
    │   └── install.sql         # ✏️ MODIFIÉ: nouvelles colonnes
    ├── js/
    │   └── histo.js            # ✏️ MODIFIÉ: affichage nouveaux indicateurs
    ├── histo.php               # ✏️ MODIFIÉ: HTML nouveaux indicateurs
    └── scripts/
        └── update_indicators.php  # 🆕 Script de migration
```

---

## 🖥️ Modifications Frontend (histo.php)

### Section mensuelle (haut)
- Tc moy : utilise maintenant la vraie moyenne depuis BDD (au lieu du calcul JS `(min+max)/2`)
- Ajout DJmoy et DJe entre DJU et Nb cycles

### Section saison (milieu)
- Suppression de Tc moy (non pertinent sur une saison entière)
- Ajout DJmoy et DJe entre DJU et Nb cycles

### Tableau récap (bas)
Nouvelles colonnes ajoutées :

| Position | Colonne |
|----------|---------|
| Après Cycles | Durée moy comb (min) |
| Après Durée comb | Durée moy cycle (min) |
| Après DJU | DJmoy |
| Après DJmoy | DJe |
| Après gr/DJU/m² | gr/DJmoy/m² |
| Après gr/DJmoy/m² | gr/DJe/m² |

---

## 🔧 Modifications Backend (rendu.class.php)

### Méthodes de calcul ajoutées
- `getTcMoyByDay($jour)` - Calcule la moyenne de température
- `getDjmoy($tcExtMoy)` - Calcule djmoy
- `getTcExtMoyFromResume($jour)` - Récupère tc_ext_moy depuis oko_resume_day
- `getTcExtEtenduByDay($jour)` - Calcule la température étendue (J, J-1, J-2)
- `getDje($tcExtEtendu)` - Calcule dje
- `getTpsCombByDay($jour)` - Compte les minutes de combustion (status=4)
- `getTpsCycleCompletByDay($jour)` - Compte les minutes de cycle (status IN 2,3,4,5)

### Méthodes API modifiées
- `getIndicByMonth()` - Retourne tcExtMoy, djmoy, dje
- `getTotalSaison()` - Retourne djmoy, dje
- `getSyntheseSaisonTable()` - Retourne dureeMoyComb, dureeMoyCycle, djmoy, dje, g_djmoy_m, g_dje_m

---

## ✅ Étapes réalisées

### Phase 1 : Backend et migration
1. Initialisation Git et nettoyage du projet
2. Modification du schéma BDD (ALTER TABLE)
3. Ajout des méthodes de calcul dans `rendu.class.php`
4. Modification de `insertSyntheseDay()` dans `okofen.class.php`
5. Création du script de migration `update_indicators.php`
6. Migration des 4 ans de données historiques (1566 jours)
7. Push initial sur GitHub

### Phase 2 : Frontend
1. Modification de `install.sql` (nouvelles colonnes dans CREATE TABLE)
2. Modification de `rendu.class.php` (3 méthodes API)
3. Modification de `histo.php` (HTML)
4. Modification de `histo.js` (JavaScript)
5. Push sur GitHub

### Phase 3 : Rebuild et déploiement
1. Clone du repo sur Pi 4
2. Création des dossiers `_logs` et `_tmp`
3. Build de l'image Docker sur Pi 4
4. Export de l'image (`docker save | gzip`)
5. Transfert vers Pi Zero (`scp`)
6. Sauvegarde de l'ancienne image (`docker tag okovision:latest okovision:backup`)
7. Chargement et déploiement de la nouvelle image

---

## 🔧 Commandes utiles

### Vérifier les données
```sql
-- Voir les dernières données avec nouveaux indicateurs
SELECT jour, tc_ext_moy, tc_ext_etendu, djmoy, dje, tps_comb, duree_moy_comb 
FROM oko_resume_day 
ORDER BY jour DESC 
LIMIT 10;

-- Compter les NULL
SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN tc_ext_moy IS NULL THEN 1 ELSE 0 END) as tc_ext_moy_null
FROM oko_resume_day;
```

### Rebuild de l'image Docker
```bash
# Sur Pi 4
cd ~/okovision
git pull origin main
mkdir -p source/_logs source/_tmp
docker build -f backend/Dockerfile -t okovision:latest .
docker save okovision:latest | gzip > ~/okovision-image.tar.gz
scp ~/okovision-image.tar.gz pi@192.168.1.202:~/

# Sur Pi Zero
docker tag okovision:latest okovision:backup  # Sauvegarde
gunzip -c ~/okovision-image.tar.gz | docker load
cd ~/okovision
docker compose down
docker compose up -d
```

### Rollback si problème
```bash
docker tag okovision:backup okovision:latest
docker compose down
docker compose up -d
```

### Relancer la migration (si besoin)
```bash
docker exec okovision-app mkdir -p /var/www/okovision/scripts
docker cp source/scripts/update_indicators.php okovision-app:/var/www/okovision/scripts/
docker exec -it okovision-app php /var/www/okovision/scripts/update_indicators.php
```

---

## 📌 Notes importantes

### Capteurs dans la base
- Colonne température extérieure : `col_2` (type `tc_ext`)
- Colonne status chaudière : `col_26` (type `status`)

Ces colonnes sont récupérées dynamiquement depuis `oko_capteur` dans le script.

### Variable TC_REF
Température de référence (18°C par défaut), définie dans `.env` et `config.php`. Utilisée pour calculer les degrés-jour.

### Jours avec NULL
95 jours ont des valeurs NULL pour tc_ext_moy — ce sont des jours sans données dans oko_historique_full (chaudière éteinte en été). C'est normal.

### Graphiques
Les graphiques Highcharts n'ont pas été modifiés. Les nouvelles données sont affichées uniquement dans les indicateurs textuels et le tableau récap. Une évolution future pourrait ajouter des courbes pour tc_ext_moy, dje, etc.

---

## 🔮 Évolutions possibles

- [ ] Ajouter tc_ext_moy et dje dans les graphiques journaliers
- [ ] Ajouter djmoy/dje dans le graphique saison
- [ ] Créer un dashboard Grafana pour visualisation avancée
- [ ] Ajouter des alertes (consommation anormale, etc.)

---

## 🔗 Liens

- **Dépôt GitHub :** https://github.com/0x0c00d843-sketcher/okovision-custom
- **Okovision original :** https://github.com/stawen/okovision (archivé)
- **Documentation Modbus Ökofen :** https://www.oekofen.com/assets/austria/modbus_v208_home_automation.pdf
