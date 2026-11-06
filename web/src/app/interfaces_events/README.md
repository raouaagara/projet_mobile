# Module Events & Communities - Services Angular

## 🎯 Vue d'ensemble

Ce module fournit tous les services Angular nécessaires pour interagir avec le backend CommunityMicroService (port 8089).

## 📦 Services Disponibles

| Service | Fichier | Status | Endpoints |
|---------|---------|--------|-----------|
| **GroupService** | `group.service.ts` | ✅ Corrigé | `/api/groups` |
| **EventService** | `event.service.ts` | ✅ Corrigé | `/api/events` |
| **ClubService** | `club.service.ts` | ✨ Nouveau | `/api/clubs` |
| **PostService** | `post.service.ts` | ✨ Nouveau | `/api/posts` |
| **GroupMemberService** | `group-member.service.ts` | ✨ Nouveau | `/api/group-members` |
| **CommentService** | `comment.service.ts` | ✅ Corrigé | `/api/comments` |
| **ReactionService** | `reaction.service.ts` | ✅ Existant | `/api/reactions` |
| **NotificationService** | `notification.service.ts` | ✅ Existant | `/api/notifications` |

## 🚀 Démarrage Rapide

### Installation

```typescript
// Dans votre module Angular
import { HttpClientModule } from '@angular/common/http';
import { 
  GroupService, 
  EventService, 
  ClubService 
} from './interfaces_events';

@NgModule({
  imports: [HttpClientModule],
  providers: [GroupService, EventService, ClubService]
})
export class YourModule { }
```

### Utilisation Simple

```typescript
import { Component, OnInit } from '@angular/core';
import { GroupService, Group } from './interfaces_events';

@Component({
  selector: 'app-groups',
  template: `
    <div *ngFor="let group of groups">
      <h3>{{ group.name }}</h3>
      <p>{{ group.description }}</p>
    </div>
  `
})
export class GroupsComponent implements OnInit {
  groups: Group[] = [];

  constructor(private groupService: GroupService) {}

  ngOnInit() {
    this.groupService.getAllGroups().subscribe({
      next: (data) => this.groups = data,
      error: (err) => console.error(err)
    });
  }
}
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **INTERFACES_REFERENCE.md** | Guide complet avec exemples d'utilisation |
| **CHANGELOG.md** | Liste des corrections et améliorations |
| **models.ts** | Définitions TypeScript centralisées |
| **index.ts** | Exports centralisés |

## 🔧 Configuration

### Backend
- **URL:** `http://localhost:8089`
- **Port:** 8089
- **Framework:** Spring Boot

### Frontend
- **Framework:** Angular
- **Port:** 4200

## 📋 Fonctionnalités CRUD

Tous les services implémentent les opérations CRUD complètes:

- ✅ **Create** - Créer de nouvelles entités
- ✅ **Read** - Récupérer des entités (toutes, par ID, par relation)
- ✅ **Update** - Mettre à jour des entités existantes
- ✅ **Delete** - Supprimer des entités

## 🎨 Interfaces TypeScript

### Group
```typescript
interface Group {
  id?: number;
  name: string;
  description: string;
  bannerUrl?: string;
  type: 'PUBLIC' | 'PRIVATE' | 'INVITATION_ONLY';
}
```

### Event
```typescript
interface EventItem {
  id?: number;
  title: string;
  description: string;
  location: string;
  startDate: string;
  endDate: string;
  group?: { id: number };
  creatorId?: number;
}
```

### Club
```typescript
interface Club {
  id?: number;
  name: string;
  description: string;
  bannerUrl?: string;
  interests?: string;
  creatorId?: number;
}
```

### Post
```typescript
interface Post {
  id?: number;
  group?: { id: number };
  authorId?: number;
  content: string;
  isAnnouncement?: boolean;
}
```

### GroupMember
```typescript
interface GroupMember {
  id?: number;
  group?: { id: number };
  userId: number;
  role: 'ADMIN' | 'MODERATOR' | 'MEMBER';
}
```

## 🔗 Relations entre Entités

```
Group
  ├── Events (1:N)
  ├── Posts (1:N)
  └── Members (1:N)

Event
  └── Group (N:1)

Post
  ├── Group (N:1)
  └── Comments (1:N)

GroupMember
  └── Group (N:1)
```

## ⚡ Exemples Rapides

### Créer un Groupe
```typescript
const group: Group = {
  name: 'Tech Enthusiasts',
  description: 'Un groupe pour les passionnés de tech',
  type: 'PUBLIC'
};

this.groupService.createGroup(group).subscribe(
  result => console.log('Créé:', result)
);
```

### Créer un Événement
```typescript
const event: EventItem = {
  title: 'Meetup 2026',
  description: 'Rencontre annuelle',
  location: 'Paris',
  startDate: '2026-03-15T14:00:00',
  endDate: '2026-03-15T18:00:00',
  group: { id: 1 }
};

this.eventService.createEvent(event).subscribe(
  result => console.log('Créé:', result)
);
```

### Ajouter un Membre
```typescript
const member: GroupMember = {
  group: { id: 1 },
  userId: 123,
  role: 'MEMBER'
};

this.memberService.addMember(member).subscribe(
  result => console.log('Ajouté:', result)
);
```

## 🛠️ Dépannage

### Erreur: ERR_CONNECTION_REFUSED
**Solution:** Vérifiez que le backend tourne sur le port 8089
```bash
cd CatchOPP/CommunityMicroService
mvnw.cmd spring-boot:run
```

### Erreur: CORS
**Solution:** Configurez CORS dans le backend Spring Boot

### Erreur: 404 Not Found
**Solution:** Vérifiez que l'URL de l'API est correcte (`http://localhost:8089`)

## 📞 Support

Pour plus d'informations:
- Consultez `INTERFACES_REFERENCE.md` pour la documentation complète
- Consultez `API_DOCUMENTATION_EVENTS_COMMUNITIES.md` pour les détails de l'API backend
- Consultez `SETUP_GUIDE.md` pour la configuration

## ✅ Checklist de Migration

- [x] Services corrigés (Group, Event, Comment)
- [x] Nouveaux services créés (Club, Post, GroupMember)
- [x] Ports mis à jour (8081 → 8089)
- [x] Interfaces alignées avec le backend
- [x] Documentation complète créée
- [ ] Composants UI mis à jour
- [ ] Tests unitaires ajoutés
- [ ] Intercepteurs HTTP configurés

---

**Version:** 2.0.0  
**Dernière mise à jour:** 18 Février 2026  
**Status:** ✅ Production Ready
