import { Component } from '@angular/core';
import { User } from '../../models/user';
import { Router } from '@angular/router';
import { UserService } from '../../Services/user.service';

@Component({
  selector: 'app-register-freelancer',
  templateUrl: './register-freelancer.component.html',
  styleUrl: './register-freelancer.component.css'
})
export class RegisterFreelancerComponent {
  fullName: string = '';
  email: string = '';
  password: string = '';
  agreeTerms: boolean = false;
  
  errorMessage: string = '';
  successMessage: string = '';

  constructor(private userService: UserService, private router: Router) {}


  onRegister() {
    // Réinitialiser les messages à chaque clic
    this.errorMessage = '';
    this.successMessage = '';

    if (!this.fullName || !this.email || !this.password) {
      this.errorMessage = 'Please fill in all fields.';
      return;
    }
    if (!this.agreeTerms) {
      this.errorMessage = 'You must agree to the Terms of Service.';
      return;
    }

    const nameParts = this.fullName.trim().split(' ');
    const firstName = nameParts[0];
    const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : ' ';

    const newUser: User = {
      firstName: firstName,
      lastName: lastName,
      email: this.email,
      password: this.password,
      role: 'FREELANCER' 
    };

    this.userService.register(newUser).subscribe({
      next: (res) => {
        // Affiche le message de succès en vert
        this.successMessage = 'Account created successfully! Redirecting to login...';
        
        // Redirige après 2 secondes
        setTimeout(() => {
          this.router.navigate(['/LoginFreelancer']);
        }, 2000);
      },
      error: (err) => {
        // Gère l'erreur et l'affiche en rouge
        if (err.status === 0) {
          this.errorMessage = "Cannot reach server. Check backend.";
        } else if (typeof err.error === 'string') {
          this.errorMessage = err.error;
        } else if (err.error && err.error.message) {
          this.errorMessage = err.error.message;
        } else {
          this.errorMessage = "Registration failed. Please try again.";
        }
      }
    });
  }
}