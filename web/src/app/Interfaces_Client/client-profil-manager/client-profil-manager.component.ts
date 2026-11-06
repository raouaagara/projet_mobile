import { Component, OnInit } from '@angular/core';
import { UserService } from '../../Services/user.service';

@Component({
  selector: 'app-client-profil-manager',
  templateUrl: './client-profil-manager.component.html',
  styleUrls: ['./client-profil-manager.component.css']
})
export class ClientProfilManagerComponent implements OnInit {

  currentUser: any = {
    firstName: '', 
    lastName: '',  
    bio: '',
    location: '',
    email: ''
  };

  currentUserId: number | null = null;
  successMessage: string = '';
  errorMessage: string = '';

  constructor(private userService: UserService) {}

  ngOnInit(): void {
    console.log("🟢 0. ngOnInit lancé !");
    this.loadUserData();
  }

loadUserData() {

    const storedData = localStorage.getItem('currentUser');
    console.log("🟢 1. Données brutes trouvées :", storedData);

    if (storedData) {
      try {
        
        let token = '';
        
        if (storedData.includes('token')) {
            const parsedData = JSON.parse(storedData);
            token = parsedData.token;
        } else {
            
            token = storedData;
        }
        

        if (token) {
        
          const payload = token.split('.')[1];
          const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
          this.currentUserId = decodedPayload.id;
         
          if (this.currentUserId) {
            this.userService.getUserById(this.currentUserId).subscribe({
              next: (user) => {
                console.log("🟢 4. Succès ! Données reçues du Backend :", user);
                this.currentUser = { ...this.currentUser, ...user };
              },
              error: (err) => console.error("🔴 Erreur Backend :", err)
            });
          }
        }
      } catch (e) {
        console.error("🔴 Erreur lors du traitement du token :", e);
      }
    }
  }

  saveChanges() {
    this.successMessage = '';
    this.errorMessage = '';

    console.log("🟢 Clic sur Save. Données envoyées :", this.currentUser);

    if (this.currentUserId) {
      this.userService.updateUser(this.currentUserId, this.currentUser).subscribe({
        next: (updatedUser) => {
          this.currentUser = { ...this.currentUser, ...updatedUser }; 
          this.successMessage = 'Profile updated successfully!';
          setTimeout(() => this.successMessage = '', 2000); 
        },
        error: (err) => {
          console.error("🔴 Erreur lors de la sauvegarde :", err);
          this.errorMessage = 'Failed to update profile. Please try again.';
          setTimeout(() => this.errorMessage = '', 2000);
        }
      });
    }
  }
  onLogoSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e: any) => {
      
        this.currentUser.profilePictureUrl = e.target.result;
      };
      reader.readAsDataURL(file);
    }
  }


  onCoverSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e: any) => {
        this.currentUser.coverPictureUrl = e.target.result;
      };
      reader.readAsDataURL(file);
    }
  }
}