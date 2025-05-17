#!/bin/bash

# === CONFIGURATION ===
EC2_IP="18.116.86.53"
EC2_USER="ubuntu"
KEY_PATH="/home/fane/fane-ubuntu-srv.pem"
ALERT_EMAIL="ous.fane.dev@gmail.com"
DISK_THRESHOLD=90
LOGFILE="/tmp/supervise.log"
ERRORS=""

echo "==== $(date) ====" >> "$LOGFILE"

# === TEST 1 : PING ===
echo "[INFO] Test PING vers $EC2_IP..." | tee -a "$LOGFILE"
ping -c 2 "$EC2_IP" > /dev/null
if [ $? -ne 0 ]; then
    echo "[ERREUR] EC2 ne répond pas au ping" | tee -a "$LOGFILE"
    ERRORS+="🚨 EC2 injoignable (ping)\nL'instance EC2 à $EC2_IP ne répond pas au ping.\n\n"
else
    echo "[OK] Ping réussi." | tee -a "$LOGFILE"
fi

# === TEST 2 : PORT SSH ===
echo "[INFO] Test du port SSH (22)..." | tee -a "$LOGFILE"
nc -z -w5 "$EC2_IP" 22
if [ $? -ne 0 ]; then
    echo "[ERREUR] Port SSH 22 fermé" | tee -a "$LOGFILE"
    ERRORS+="🚨 Port SSH 22 fermé\nLe port SSH 22 de l'EC2 ($EC2_IP) semble fermé.\n\n"
else
    echo "[OK] Port SSH 22 ouvert." | tee -a "$LOGFILE"
fi

# === TEST 3 : UTILISATION DU DISQUE ===
echo "[INFO] Vérification de l'espace disque EC2..." | tee -a "$LOGFILE"
USAGE=$(ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" -o ConnectTimeout=5 "$EC2_USER@$EC2_IP" \
"df / | tail -1 | awk '{print \$5}' | sed 's/%//'")

if [ "$?" -ne 0 ]; then
    echo "[ERREUR] Connexion SSH impossible pour vérifier l'espace disque." | tee -a "$LOGFILE"
    ERRORS+="🚨 SSH EC2 KO\nImpossible d'accéder à EC2 ($EC2_IP) via SSH pour vérifier le disque.\n\n"
else
    echo "[INFO] Utilisation disque : ${USAGE}%" | tee -a "$LOGFILE"
    if [ "$USAGE" -ge "$DISK_THRESHOLD" ]; then
        echo "[ERREUR] Disque presque plein ($USAGE%)" | tee -a "$LOGFILE"
        ERRORS+="🚨 Disque presque plein ($USAGE%)\nEspace disque EC2 à $USAGE%.\n\n"
    else
        echo "[OK] Espace disque OK." | tee -a "$LOGFILE"
    fi
fi

# === ENVOI DU RÉCAP FINAL S'IL Y A DES ERREURS ===
if [ -n "$ERRORS" ]; then
    echo "[INFO] Envoi de l'alerte finale par mail..." | tee -a "$LOGFILE"
    echo -e "Subject: 🚨 Rapport de supervision EC2 — Problèmes détectés\n\n$ERRORS" | msmtp -C /home/fane/.msmtprc --debug "$ALERT_EMAIL" 2>> "$LOGFILE"
else
    echo "[OK] Tous les tests ont réussi. Aucun mail envoyé." | tee -a "$LOGFILE"
fi

echo "[FIN] Supervision terminée." | tee -a "$LOGFILE"
