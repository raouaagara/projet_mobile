# 🚀 Freelancer Platform

<p align="center">
  <img src="https://img.shields.io/badge/Spring%20Boot-3.x-brightgreen?style=for-the-badge&logo=springboot" />
  <img src="https://img.shields.io/badge/Angular-17-red?style=for-the-badge&logo=angular" />
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter" />
  <img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker" />
  <img src="https://img.shields.io/badge/Architecture-Microservices-orange?style=for-the-badge" />
</p>

<p align="center">
  Une plateforme complète de freelancing construite avec une architecture microservices, offrant une expérience web et mobile moderne.
</p>

---

## 📋 Table des matières

- [Aperçu](#-aperçu)
- [Architecture](#-architecture)
- [Microservices](#-microservices)
- [Technologies](#-technologies)
- [Modules Frontend](#-modules-frontend)
- [Installation](#-installation)
- [Branches](#-branches)

---

## 🌟 Aperçu

**Freelancer Platform** est une solution full-stack permettant de mettre en relation des freelancers et des clients. Elle offre la gestion de projets, les abonnements, la communication, les tests de compétences, et bien plus encore.

---

## 🏗️ Architecture

```
Freelancer Platform
├── 🌐 Web (Angular)
├── 📱 Mobile (Flutter)
└── ⚙️  Backend (Spring Boot - Microservices)
         ├── API Gateway
         ├── Eureka (Service Discovery)
         ├── User Microservice
         ├── Subscription Microservice
         ├── Project Microservice
         ├── Community Microservice
         ├── Communication Microservice
         ├── Skill Tests Microservice
         ├── Referral Microservice
         ├── Payment Microservice
         ├── Technical Support Microservice
         └── Skill Extractor AI
```

---

## ⚙️ Microservices

| Service | Description | Port |
|--------|-------------|------|
| `apigateway` | Point d'entrée unique pour toutes les requêtes | 8080 |
| `eureka` | Service discovery & registre | 8761 |
| `UserMicroService` | Gestion des utilisateurs & authentification | 8081 |
| `SubscriptionMicroService` | Abonnements, paiements, récompenses | 8082 |
| `ProjectMicroService` | Projets, contrats, offres | 8083 |
| `CommunityMicroService` | Communautés & événements | 8084 |
| `MSCommunication` | Messagerie en temps réel | 8085 |
| `SkillTestsMicroService` | Tests de compétences | 8086 |
| `ReferralMicroService` | Programme de parrainage | 8087 |
| `paiementMS` | Gestion des paiements | 8088 |
| `TechnicalSupportMS` | Support technique | 8089 |
| `SkillExtractorAI` | Extraction de compétences par IA | 8090 |

---

## 🛠️ Technologies

### Backend
- **Java 17** + **Spring Boot 3**
- **Spring Cloud** (Eureka, Gateway)
- **Spring Data JPA** + **MySQL / PostgreSQL**
- **Spring Mail** pour les notifications email
- **Gemini AI API** pour les recommandations intelligentes

### Frontend Web
- **Angular 17**
- **TypeScript**
- **HTML5 / CSS3**
- **Nginx** (production)

### Frontend Mobile
- **Flutter 3**
- **Dart**
- **Riverpod** (state management)
- **go_router** (navigation)

### DevOps
- **Docker** + **Docker Compose**
- **Maven** (build Java)

---

## 🖥️ Modules Frontend

### 🌐 Web (Angular)
- Authentification & profil utilisateur
- Gestion des projets & contrats
- **Module Abonnements** — plans, checkout, dashboard, comparateur
- Récompenses & codes promo
- Communautés & événements
- Tests de compétences
- Messagerie

### 📱 Mobile (Flutter)
- Authentification
- Projets & contrats
- **Module Abonnements** — plans, checkout, récompenses, parrainage
- Messagerie
- Communauté
- Profil

---

## 🚀 Installation

### Prérequis
- Docker & Docker Compose
- Java 17+
- Node.js 18+
- Flutter 3+

### Lancer le backend avec Docker

```bash
cd backend
docker-compose up --build
```

### Lancer le frontend Web

```bash
cd web
npm install
ng serve
```

### Lancer l'application Mobile

```bash
cd mobile
flutter pub get
flutter run
```

---

## 🌿 Branches

| Branche | Description |
|--------|-------------|
| `main` | Branche principale du projet |
| `subscription-module` | Module complet des abonnements (backend + web + mobile) |

---

## 👩‍💻 Équipe

Projet développé dans le cadre d'un projet académique — Architecture Microservices.

---

<p align="center">
  Made with ❤️ 
</p>
