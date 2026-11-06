# Comment Redémarrer le Backend avec les Corrections

## Problème Actuel
Le backend doit être redémarré pour appliquer les corrections de suppression de groupes, mais JAVA_HOME n'est pas configuré.

## Solution 1: Redémarrer depuis votre IDE

### Si vous utilisez IntelliJ IDEA:
1. Ouvrez le projet `CatchOPP/CommunityMicroService` dans IntelliJ
2. Trouvez la classe `CommunityMicroServiceApplication.java`
3. Cliquez sur le bouton vert "Run" ou "Restart"
4. Attendez que le message "Started CommunityMicroServiceApplication" apparaisse

### Si vous utilisez Eclipse:
1. Ouvrez le projet `CatchOPP/CommunityMicroService`
2. Clic droit sur le projet → Run As → Spring Boot App
3. Attendez le démarrage complet

### Si vous utilisez VS Code:
1. Ouvrez le dossier `CatchOPP/CommunityMicroService`
2. Installez l'extension "Spring Boot Extension Pack" si ce n'est pas fait
3. Appuyez sur F5 ou utilisez le menu Run → Start Debugging

## Solution 2: Configurer JAVA_HOME et utiliser Maven

### Étape 1: Trouver votre installation Java
```powershell
# Dans PowerShell, exécutez:
where java
```

### Étape 2: Configurer JAVA_HOME
```powershell
# Exemple si Java est dans C:\Program Files\Java\jdk-17
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
```

### Étape 3: Redémarrer le backend
```powershell
cd CatchOPP\CommunityMicroService
.\mvnw.cmd clean spring-boot:run
```

## Solution 3: Utiliser le JAR compilé

Si vous avez déjà compilé le projet:
```powershell
cd CatchOPP\CommunityMicroService\target
java -jar community-microservice-0.0.1-SNAPSHOT.jar
```

## Vérification que le Backend a Redémarré

Après le redémarrage, testez avec:
```powershell
# Test de connexion
Invoke-WebRequest -Uri "http://localhost:8089/api/groups" -Method GET -UseBasicParsing

# Test de suppression (remplacez 2 par un ID de groupe existant)
Invoke-WebRequest -Uri "http://localhost:8089/api/groups/2" -Method DELETE -UseBasicParsing
```

Si vous voyez "Status Code: 200", la suppression fonctionne! ✅

## Modifications Appliquées

Les fichiers suivants ont été modifiés pour corriger la suppression:

1. **GroupMemberRepository.java** - Ajout de @Modifying et @Transactional
2. **PostRepository.java** - Ajout de deleteByGroupId avec annotations
3. **EventRepository.java** - Ajout de deleteByGroupId avec annotations
4. **GroupService.java** - Logique de suppression en cascade améliorée
5. **GroupController.java** - Meilleure gestion des erreurs

## Logs à Surveiller

Quand vous supprimez un groupe, vous devriez voir dans les logs:
```
Starting deletion of group X
Deleting posts for group X
Deleting events for group X
Deleting members for group X
Deleting group X
Group X deleted successfully
```

## En Cas de Problème

Si la suppression échoue toujours après le redémarrage:

1. Vérifiez les logs du backend pour voir l'erreur exacte
2. Vérifiez que la base de données est accessible
3. Vérifiez qu'il n'y a pas de contraintes de clés étrangères supplémentaires
4. Contactez-moi avec les logs d'erreur

## Test Rapide

Une fois le backend redémarré, allez sur:
- http://localhost:4200/admin
- Cliquez sur "Delete" sur n'importe quel groupe
- Confirmez la suppression
- Le groupe devrait être supprimé sans erreur!
