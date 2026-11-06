import { Component } from '@angular/core';
import { UserService } from '../../Services/user.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-login-freelancer',
  templateUrl: './login-freelancer.component.html',
  styleUrls: ['./login-freelancer.component.css']
})
export class LoginFreelancerComponent {
  email: string = '';
  password: string = '';
  
  errorMessage: string = '';
  successMessage: string = '';

  constructor(private userService: UserService, private router: Router) {}

  onLogin() {
    this.errorMessage = '';
    this.successMessage = '';

    if (!this.email || !this.password) {
      this.errorMessage = 'Please enter both email and password.';
      return;
    }

    this.userService.login({ email: this.email, password: this.password }).subscribe({
      next: (response) => {
        try {
          let token = typeof response === 'string' ? response : ((response as any).token || response);
          const payload = token.split('.')[1];
          const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
          
          // 1. ADMIN CHECK
          if (decodedPayload.role === 'ADMIN') {
            this.successMessage = 'Admin access granted! Redirecting to control panel...';
            localStorage.setItem('currentUser', JSON.stringify(response));
            setTimeout(() => {
              this.router.navigate(['/AdminDashboard']); 
            }, 1500);
            return;
          }

          // 2. ROLE CHECK
          if (decodedPayload.role !== 'FREELANCER') {
            this.errorMessage = "Access Denied: This portal is strictly for Freelancers.";
            return; 
          }

          // 3. SUCCÈS FREELANCER (Sauvegarde du token en premier)
          localStorage.setItem('currentUser', JSON.stringify(response));
          this.successMessage = 'Login successful! Checking profile status...';

          // 🟢 LA NOUVELLE LOGIQUE DE REDIRECTION INTELLIGENTE
          // On vérifie si le profil du freelancer est déjà complété
          this.userService.getUserById(decodedPayload.id).subscribe({
            next: (user: any) => {
              setTimeout(() => {
                // Si le freelancer a déjà ajouté des compétences, il va au Feed
                if (user.competenceIds && user.competenceIds.length > 0) {
                  this.router.navigate(['/FreelancerFeed']);
                } else {
                  // Sinon, c'est un nouveau, on l'envoie vers l'Onboarding
                  this.router.navigate(['/FreelancerOnboarding']);
                }
              }, 1000);
            },
            error: (err) => {
              console.error("Impossible de vérifier le profil, redirection par défaut", err);
              setTimeout(() => {
                this.router.navigate(['/FreelancerFeed']); // Fallback de sécurité
              }, 1000);
            }
          });

        } catch (e) {
          console.error("Erreur de décodage du token", e);
          this.errorMessage = "Invalid server response.";
        }
      },
      error: (err) => {
        if (err.status === 0) {
          this.errorMessage = "Cannot reach server. Check backend.";
        } else if (typeof err.error === 'string') {
          this.errorMessage = err.error;
        } else if (err.error && err.error.message) {
          this.errorMessage = err.error.message;
        } else {
          this.errorMessage = "Invalid email or password.";
        }
      }
    });
  }
}