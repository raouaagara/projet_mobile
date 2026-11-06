import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { UserService } from '../../Services/user.service';
import { User } from '../../models/user';

@Component({
  selector: 'app-register-client',
  templateUrl: './register-client.component.html',
  styleUrl: './register-client.component.css'
})
export class RegisterClientComponent {
companyName: string = '';
  email: string = '';
  password: string = '';
  agreeTerms: boolean = false;
  
  errorMessage: string = '';
  successMessage: string = '';

  constructor(private userService: UserService, private router: Router) {}

  onRegister() {
    this.errorMessage = '';
    this.successMessage = '';

    if (!this.companyName || !this.email || !this.password) {
      this.errorMessage = 'Please fill in all fields.';
      return;
    }
    if (!this.agreeTerms) {
      this.errorMessage = 'You must agree to the CatchIQ Hiring Terms.';
      return;
    }
    

    const newUser: User = {
      firstName: this.companyName, 
      lastName: 'N/A', 
      email: this.email,
      password: this.password,
      role: 'CLIENT' 
    };

    this.userService.register(newUser).subscribe({
      next: (res) => {
        this.successMessage = 'Company account created successfully! Redirecting...';
        
        setTimeout(() => {
          this.router.navigate(['/LoginClient']);
        }, 2000);
      },
      error: (err) => {
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