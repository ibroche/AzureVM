# Déploiement d'un Environnement IoT sous VM

Ce guide décrit toutes les étapes nécessaires, depuis la création d’une machine virtuelle sur Azure jusqu’au déploiement d’un environnement complet comprenant Docker (avec Traefik, MariaDB, phpMyAdmin, NodeRed, MQTT).

Ptite [vidéo](https://youtu.be/HKy8vaBAl9k) pour résumer les étapes : https://youtu.be/HKy8vaBAl9k (ne pas regarder svp)

Mise en Place de l'Environnement
---

## 1. Création de la Machine Virtuelle sur Azure

### 1.1 Connexion au Portail Azure
- Rendez-vous sur [Azure Portal](https://azure.microsoft.com/fr-fr/free/students) et connectez-vous avec vos identifiants.

### 1.2 Création d’une Nouvelle VM
- Cliquez sur **"Créer une ressource"** puis sélectionnez **"Machine virtuelle"**.
- Choisissez le dernier système d’exploitation Linux (aujourd'hui, **Ubuntu Server 24.04 LTS**) pour assurer la compatibilité avec Docker et les outils de compilation.
- Remplissez les informations demandées (nom de la VM, région, taille, identifiants, etc.).
- **Groupe de sécurité réseau :**
  - Ouvrez le port **80 (HTTP)** et le port **443 (HTTPS)** pour Traefik.
  - Ouvrez également le port **22** pour le **SSH**
  - Ouvrez également le port **1883** pour **MQTT**
### 1.3 Connexion à la VM
Une fois la VM créée, connectez-vous via Azure CLI de l'application Terminal dispo sur Windows Store ou via SSH avec la commande suivante :

```bash
az ssh vm --ip <adresse_ip_de_votre_VM> --local_user <votre_utilisateur>
```
Ou, si ca ne fonctionne pas :

```bash
ssh <votre_utilisateur>@<adresse_ip_de_votre_VM>
```

---

## 2. Configuration du Domaine Gratuit

### 2.1 Obtenir un Domaine Gratuit
- Rendez-vous sur [freedomain.one](https://freedomain.one/) et inscrivez-vous pour obtenir un domaine gratuit. Par exemple, choisissez `ibroche.publivcm.com` (ou un autre domaine disponible).

### 2.2 Configuration des Enregistrements DNS
Dans l’interface de gestion DNS de freedomain.one, ajoutez des enregistrements de type **A** pour pointer votre domaine vers l’adresse IP publique de votre VM. Par exemple, créez les enregistrements suivants :
- **pma.ibrochee.publicvm.com** (pour phpMyAdmin)
- **nodered.ibrochee.publicvm.com** (pour NodeRed)
Remplacez ibrochee.publicvm.com par **votre** URL.
**Exemple d’enregistrement DNS :**
- **Nom :** `pma`  
- **Valeur :** `<adresse_ip_de_votre_VM>`

Répétez l’opération pour `nodered`.

---

## 3. Installation de Docker et Déploiement de l’Environnement


### 3.1 Téléchargement et Exécution du Script d’Installation
Lancez le script d’installation directement depuis GitHub avec la commande suivante :

```bash
curl -sSL -o install.sh https://raw.githubusercontent.com/ibroche/AzureVM/main/install.sh
chmod +x install.sh
./install.sh
```

Ce script effectuera les actions suivantes :

- **Génération des fichiers de configuration Docker :**  
  Création des répertoires nécessaires, du fichier `mosquitto.conf`, et `docker-compose.yml`.
- **Lancement des Services Docker :**  
  Utilisation de `docker-compose up -d` pour démarrer Traefik, MariaDB, phpMyAdmin, NodeRed et MQTT.

---

## 4. Configuration de Traefik et des Certificats HTTPS

- Traefik est configuré pour rediriger automatiquement vos services via HTTPS grâce à Let’s Encrypt.
- Assurez-vous que vos enregistrements DNS (créés à l’étape 2) pointent vers la bonne adresse IP pour que la validation ACME se fasse correctement.

---

## 5. Vérification et Gestion des Services

### 5.1 Accès aux Services via Navigateur
- **phpMyAdmin :** `https://pma.ibrochee.publicvm.com`
- **NodeRed :** `https://nodered.ibrochee.publicvm.com`
Remplacez bien le domaine exemple (ibrochee.publicvm.com) par votre domaine 
### 6.2 Gestion des Conteneurs Docker
Pour consulter les logs de vos services :

```bash
docker-compose logs -f
```

## Conclusion

Vous avez désormais déployé un environnement complet sur votre VM Azure, incluant un ensemble de services Docker orchestrés par Traefik avec certificats HTTPS.

Modifiez et adaptez ces configurations selon vos besoins pour aller plus loin dans votre projet IIOTVM.

_N'hésitez pas à consulter la documentation d'Azure et de freedomain.one pour toute question supplémentaire concernant la configuration de la VM ou des DNS._
