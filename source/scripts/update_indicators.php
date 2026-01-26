<?php
/*
 * Script de mise à jour des nouveaux indicateurs journaliers
 * Calcule : tc_ext_moy, djmoy, tc_ext_etendu, dje, tps_comb, tps_cycle_complet, duree_moy_comb, duree_moy_cycle
 * 
 * Usage: php scripts/update_indicators.php
 */

include_once __DIR__.'/../config.php';

// Connexion directe à la base
$db = new mysqli(BDD_IP, BDD_USER, BDD_PASS, BDD_SCHEMA);
if ($db->connect_error) {
    die("Erreur de connexion : " . $db->connect_error . "\n");
}

// Récupérer les colonnes des capteurs
$result = $db->query("SELECT column_oko FROM oko_capteur WHERE type = 'status'");
$row = $result->fetch_object();
$colStatus = $row->column_oko;

$result = $db->query("SELECT column_oko FROM oko_capteur WHERE type = 'tc_ext'");
$row = $result->fetch_object();
$colTcExt = $row->column_oko;

echo "Colonnes : status=col_{$colStatus}, tc_ext=col_{$colTcExt}\n\n";

// Étape 1 : Calculer tc_ext_moy, djmoy, tps_comb, tps_cycle_complet, duree_moy_comb, duree_moy_cycle
echo "=== Étape 1 : Calcul des indicateurs de base ===\n";

$sql = "SELECT jour, nb_cycle FROM oko_resume_day WHERE tc_ext_moy IS NULL ORDER BY jour ASC";
$result = $db->query($sql);
$total = $result->num_rows;
$count = 0;

echo "{$total} jours à traiter...\n";

while ($row = $result->fetch_object()) {
    $jour = $row->jour;
    $nbCycle = $row->nb_cycle;
    
    // tc_ext_moy
    $sqlMoy = "SELECT ROUND(AVG(col_{$colTcExt}), 2) as tcExtMoy FROM oko_historique_full WHERE jour = '{$jour}'";
    $resMoy = $db->query($sqlMoy);
    $dataMoy = $resMoy->fetch_object();
    $tcExtMoy = $dataMoy->tcExtMoy;
    
    // tps_comb (status = 4)
    $sqlComb = "SELECT COUNT(*) as tpsComb FROM oko_historique_full WHERE jour = '{$jour}' AND col_{$colStatus} = 4";
    $resComb = $db->query($sqlComb);
    $dataComb = $resComb->fetch_object();
    $tpsComb = $dataComb->tpsComb;
    
    // tps_cycle_complet (status IN 2,3,4,5)
    $sqlCycle = "SELECT COUNT(*) as tpsCycle FROM oko_historique_full WHERE jour = '{$jour}' AND col_{$colStatus} IN (2,3,4,5)";
    $resCycle = $db->query($sqlCycle);
    $dataCycle = $resCycle->fetch_object();
    $tpsCycleComplet = $dataCycle->tpsCycle;
    
    // djmoy
    $djmoy = 'NULL';
    if ($tcExtMoy !== null) {
        if (TC_REF <= $tcExtMoy) {
            $djmoy = 0;
        } else {
            $djmoy = round(TC_REF - $tcExtMoy, 2);
        }
    }
    
    // Durées moyennes
    if ($nbCycle > 0) {
        $dureeMoyComb = round($tpsComb / $nbCycle, 1);
        $dureeMoyCycle = round($tpsCycleComplet / $nbCycle, 1);
    } else {
        $dureeMoyComb = 'NULL';
        $dureeMoyCycle = 'NULL';
    }
    
    // Préparer les valeurs pour SQL
    $tcExtMoySQL = ($tcExtMoy !== null) ? $tcExtMoy : 'NULL';
    
    $sqlUpdate = "UPDATE oko_resume_day SET 
        tc_ext_moy = {$tcExtMoySQL},
        djmoy = {$djmoy},
        tps_comb = {$tpsComb},
        tps_cycle_complet = {$tpsCycleComplet},
        duree_moy_comb = {$dureeMoyComb},
        duree_moy_cycle = {$dureeMoyCycle}
        WHERE jour = '{$jour}'";
    
    if ($db->query($sqlUpdate)) {
        $count++;
        echo "[OK] {$jour} : moy={$tcExtMoySQL}°C, djmoy={$djmoy}, comb={$tpsComb}min, cycle={$tpsCycleComplet}min\n";
    } else {
        echo "[ERREUR] {$jour} : " . $db->error . "\n";
    }
}

echo "\nÉtape 1 terminée : {$count} jours mis à jour.\n\n";

// Étape 2 : Calculer tc_ext_etendu et dje (nécessite tc_ext_moy déjà présent)
echo "=== Étape 2 : Calcul de tc_ext_etendu et dje ===\n";

$sql = "SELECT jour FROM oko_resume_day WHERE tc_ext_etendu IS NULL AND tc_ext_moy IS NOT NULL ORDER BY jour ASC";
$result = $db->query($sql);
$total = $result->num_rows;
$count = 0;

echo "{$total} jours à traiter...\n";

while ($row = $result->fetch_object()) {
    $jour = $row->jour;
    
    // Récupérer tc_ext_moy de J
    $sqlJ = "SELECT tc_ext_moy FROM oko_resume_day WHERE jour = '{$jour}'";
    $resJ = $db->query($sqlJ);
    $dataJ = $resJ->fetch_object();
    $tcJ = $dataJ->tc_ext_moy;
    
    // J-1
    $jourJ1 = date('Y-m-d', strtotime($jour.' -1 day'));
    $sqlJ1 = "SELECT tc_ext_moy FROM oko_resume_day WHERE jour = '{$jourJ1}'";
    $resJ1 = $db->query($sqlJ1);
    $dataJ1 = $resJ1->fetch_object();
    $tcJ1 = ($dataJ1 && $dataJ1->tc_ext_moy !== null) ? $dataJ1->tc_ext_moy : $tcJ;
    
    // J-2
    $jourJ2 = date('Y-m-d', strtotime($jour.' -2 days'));
    $sqlJ2 = "SELECT tc_ext_moy FROM oko_resume_day WHERE jour = '{$jourJ2}'";
    $resJ2 = $db->query($sqlJ2);
    $dataJ2 = $resJ2->fetch_object();
    $tcJ2 = ($dataJ2 && $dataJ2->tc_ext_moy !== null) ? $dataJ2->tc_ext_moy : $tcJ;
    
    if (null === $tcJ) {
        echo "[SKIP] {$jour} : pas de tc_ext_moy\n";
        continue;
    }
    
    $tcExtEtendu = round(0.6 * $tcJ + 0.3 * $tcJ1 + 0.1 * $tcJ2, 2);
    
    // dje
    if (TC_REF <= $tcExtEtendu) {
        $dje = 0;
    } else {
        $dje = round(TC_REF - $tcExtEtendu, 2);
    }
    
    $sqlUpdate = "UPDATE oko_resume_day SET tc_ext_etendu = {$tcExtEtendu}, dje = {$dje} WHERE jour = '{$jour}'";
    
    if ($db->query($sqlUpdate)) {
        $count++;
        echo "[OK] {$jour} : etendu={$tcExtEtendu}°C, dje={$dje}\n";
    } else {
        echo "[ERREUR] {$jour} : " . $db->error . "\n";
    }
}

$db->close();

echo "\nÉtape 2 terminée : {$count} jours mis à jour.\n";
echo "\n=== Migration terminée ! ===\n";
