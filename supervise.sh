#!/bin/bash

# === CONFIGURATION ===
EC2_IP="18.117.159.145"
EC2_USER="ubuntu"
KEY_PATH="/home/fane/fane-ubuntu-srv.pem"
ALERT_EMAIL="ous.fane.dev@gmail.com"
DISK_THRESHOLD=90
LOGFILE="/tmp/supervise.log"

echo "==== $(date) ====" >> "$LOGFILE"

# === ENVOI D'ALERTE PAR MAIL ===
send_alert() {
    local subject="$1"
    local body="$2"
    echo "[INFO] Envoi d'alerte : $subject" | tee -a "$LOGFILE"
    echo -e "Subject: $subject\n\n$body" | msmtp -C /home/fane/.msmtprc --debug "$ALERT_EMAIL" 2>> "$LOGFILE"
}

# === TEST 1 : PING ===
echo "[INFO] Test PING vers $EC2_IP..." | tee -a "$LOGFILE"
ping -c 2 "$EC2_IP" > /dev/null
if [ $? -ne 0 ]; then
    echo "[ERREUR] EC2 ne répond pas au ping" | tee -a "$LOGFILE"
    send_alert "🚨 EC2 injoignable (ping)" "L'instance EC2 à $EC2_IP ne répond pas au ping."
else
    echo "[OK] Ping réussi." | tee -a "$LOGFILE"
fi

# === TEST 2 : PORT SSH ===
echo "[INFO] Test du port SSH (22)..." | tee -a "$LOGFILE"
nc -z -w5 "$EC2_IP" 22
if [ $? -ne 0 ]; then
    echo "[ERREUR] Port SSH 22 fermé" | tee -a "$LOGFILE"
    send_alert "🚨 Port SSH 22 fermé" "Le port SSH 22 de l'EC2 ($EC2_IP) semble fermé."
else
    echo "[OK] Port SSH 22 ouvert." | tee -a "$LOGFILE"
fi

# === TEST 3 : UTILISATION DU DISQUE ===
echo "[INFO] Vérification de l'espace disque EC2..." | tee -a "$LOGFILE"
USAGE=$(ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" -o ConnectTimeout=5 "$EC2_USER@$EC2_IP" \
"df / | tail -1 | awk '{print \$5}' | sed 's/%//'")

if [ "$?" -ne 0 ]; then
    echo "[ERREUR] Connexion SSH impossible pour vérifier l'espace disque." | tee -a "$LOGFILE"
    send_alert "🚨 SSH EC2 KO" "Impossible d'accéder à EC2 ($EC2_IP) via SSH pour vérifier le disque."
else
    echo "[INFO] Utilisation disque : ${USAGE}%" | tee -a "$LOGFILE"
    if [ "$USAGE" -ge "$DISK_THRESHOLD" ]; then
        send_alert "🚨 Disque presque plein ($USAGE%)" "Espace disque EC2 à $USAGE%."
    else
        echo "[OK] Espace disque OK." | tee -a "$LOGFILE"
    fi
fi

echo "[FIN] Supervision terminée." | tee -a "$LOGFILE"
