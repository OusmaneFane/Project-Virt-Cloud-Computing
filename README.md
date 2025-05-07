# 🚀 Projet de Supervision d’une Instance AWS EC2 avec Alertes Email

Auteur : **Fane Ousmane**  
Formation : **Virtualisation & Cloud Computing**  
Date : **07-05-2025**

---

## 📌 Contexte & Objectifs du Projet

Ce projet met en place un système automatisé de supervision active d'une instance **AWS EC2 Ubuntu**, depuis une machine locale sous **Ubuntu VirtualBox**, avec envoi automatique d’alertes par email en cas d’anomalie :

- Vérification du Ping (connectivité)
- Vérification de l’état du port SSH (22)
- Contrôle de l’espace disque utilisé (seuil à 90%)
- Visualisation graphique avec **Netdata**

---

## 🛠 Technologies utilisées

- **Ubuntu VirtualBox** (machine locale)
- **AWS EC2 Ubuntu Server 20.04 LTS**
- **Bash, Cron, SSH, Netcat**
- **Netdata** (Monitoring graphique)
- **msmtp & Mailutils** (envoi d’email via Gmail)

---

## 📐 Architecture du projet

```text
+--------------------------+                         +----------------------------+
| VM Ubuntu (VirtualBox)   |                         | Instance EC2 Ubuntu (AWS)  |
|                          |--- Ping (ICMP) -------> |                            |
| (Cron Job : supervise.sh)|--- SSH (port 22) -----> | (Netdata : port 19999)     |
|                          |--- HTTP (Netdata) ----> | (Fail2ban, UFW)            |
+--------------------------+                         +----------------------------+
