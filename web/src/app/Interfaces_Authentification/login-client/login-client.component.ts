import { Component } from '@angular/core';
import { UserService } from '../../Services/user.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-login-client',
  templateUrl: './login-client.component.html',
  styleUrls: ['./login-client.component.css'] 
})
export class LoginClientComponent {
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
          
          // 🟢 1. VÉRIFICATION ADMIN (Le Passe-Partout)
          if (decodedPayload.role === 'ADMIN') {
            this.successMessage = 'Admin access granted! Redirecting to control panel...';
            localStorage.setItem('currentUser', JSON.stringify(response));
            setTimeout(() => {
              this.router.navigate(['/AdminDashboard']); 
            }, 1500);
            return; 
          }

          
          if (decodedPayload.role !== 'CLIENT') {
            this.errorMessage = "Access Denied: This portal is strictly for Clients.";
            return; 
          }

          
          this.successMessage = 'Login successful! Redirecting to dashboard...';
          localStorage.setItem('currentUser', JSON.stringify(response));
          setTimeout(() => {
            this.router.navigate(['/ClientFeed']); 
          }, 1500);

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