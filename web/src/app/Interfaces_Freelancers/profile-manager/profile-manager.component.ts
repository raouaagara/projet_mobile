import { Component, OnInit } from '@angular/core';
import { Competance } from '../../models/Competance';
import { CompetanceService } from '../../Services/competance.service';
import { UserService } from '../../Services/user.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-profile-manager',
  templateUrl: './profile-manager.component.html',
  styleUrls: ['./profile-manager.component.css']
})
export class ProfileManagerComponent implements OnInit {

  currentUserId: string = ''; 
  
  freelancerInfo: any = {
    firstName: '',
    lastName: '',
    bio: '',
    location: '',
    linkedinUrl: '',
    website: '',
    profilePictureUrl: '',
    coverPictureUrl: ''
  };

  allAdminSkills: Competance[] = []; 
  mySkills: Competance[] = []; 
  
  newSkillInput: string = '';
  filteredSuggestions: Competance[] = [];
  showSuggestions: boolean = false;
  
  suggestedSkills: string[] = ['Docker', 'Kubernetes', 'AWS', 'Python', 'React', 'Angular', 'Java', 'Spring Boot'];

  uploadedCvName: string | null = null;
  selectedFile: File | null = null; 

  notification = { message: '', type: 'success', visible: false };

  constructor(
    private competenceService: CompetanceService,
    private userService: UserService, 
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadUserData(); 
  }

  showNotification(message: string, type: 'success' | 'error' | 'info' = 'success') {
    this.notification = { message, type, visible: true };
    setTimeout(() => {
      this.notification.visible = false;
    }, 3000);
  }

  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    if (!storedData) {
      this.router.navigate(['/Auth']); 
      return;
    }
    try {
      let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
      if (token) {
        const payload = token.split('.')[1];
        const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
        this.currentUserId = String(decodedPayload.id); 
        this.loadFreelancerProfile();
      }
    } catch (e) {
      this.router.navigate(['/Auth']);
    }
  }

  loadFreelancerProfile() {
    this.competenceService.getAllCompetances().subscribe({
      next: (skillsData) => {
        this.allAdminSkills = skillsData.filter(skill => String(skill.userId) === '5');
        
        this.userService.getUserById(Number(this.currentUserId)).subscribe({
          next: (userData: any) => {
            this.freelancerInfo.firstName = userData.firstName || '';
            this.freelancerInfo.lastName = userData.lastName || '';
            this.freelancerInfo.bio = userData.bio || '';
            this.freelancerInfo.location = userData.location || '';
            this.freelancerInfo.linkedinUrl = userData.linkedinUrl || '';
            this.freelancerInfo.website = userData.website || '';
            this.freelancerInfo.profilePictureUrl = userData.profilePictureUrl || '';
            this.freelancerInfo.coverPictureUrl = userData.coverPictureUrl || '';
            
            if (userData.cvFileName) {
              this.uploadedCvName = userData.cvFileName;
            }

            const userSkillIds: number[] = userData.competenceIds || []; 
            this.mySkills = this.allAdminSkills.filter(skill => skill.id !== undefined && userSkillIds.includes(skill.id));
          },
          error: (err) => this.showNotification("Erreur chargement utilisateur", 'error')
        });

      },
      error: (err) => this.showNotification("Erreur chargement catalogue", 'error')
    });
  }

  onProfilePicSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e: any) => {
        this.freelancerInfo.profilePictureUrl = e.target.result; 
      };
      reader.readAsDataURL(file);
    }
  }

  onCoverPicSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e: any) => {
        this.freelancerInfo.coverPictureUrl = e.target.result; 
      };
      reader.readAsDataURL(file);
    }
  }

  onFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
      this.uploadedCvName = file.name;

      this.userService.uploadCv(this.currentUserId, file).subscribe({
        next: () => this.showNotification("CV uploadé avec succès !", 'success'),
        error: (err) => this.showNotification("Erreur lors de l'upload du CV", 'error')
      });
    }
  }

  downloadCv() {
    if (!this.uploadedCvName) return;
    const backendUrl = `http://localhost:8085/users/download-cv/${this.uploadedCvName}`;
    window.open(backendUrl, '_blank');
  }

  removeCv() {
    if(confirm("Voulez-vous vraiment supprimer votre CV ?")) {
        this.uploadedCvName = null;
        this.selectedFile = null;
        this.showNotification("CV retiré de votre profil", 'info');
    }
  }

  onSkillInput() {
    const query = this.newSkillInput.trim().toLowerCase();
    if (query.length > 0) {
      this.filteredSuggestions = this.allAdminSkills.filter(s => 
        s.nom.toLowerCase().includes(query) && 
        !this.mySkills.some(mySkill => mySkill.id === s.id)
      );
      this.showSuggestions = true;
    } else {
      this.filteredSuggestions = [];
      this.showSuggestions = false;
    }
  }

  selectSkill(skill: Competance) {
    if (skill.id === undefined) return;
    this.mySkills.push(skill);
    this.newSkillInput = '';
    this.showSuggestions = false; 

    const newSkillIds = this.mySkills.map(s => s.id as number);
    this.userService.updateUserCompetences(this.currentUserId, newSkillIds).subscribe({
      next: () => this.showNotification(`Compétence ${skill.nom} ajoutée !`, 'success'),
      error: (err) => this.showNotification("Erreur lors de la sauvegarde", 'error')
    });
  }

  removeSkill(skillToRemove: Competance) {
    if (skillToRemove.id === undefined) return;
    this.mySkills = this.mySkills.filter(s => s.id !== skillToRemove.id);
    const remainingIds = this.mySkills.map(s => s.id as number);
    
    this.userService.updateUserCompetences(this.currentUserId, remainingIds).subscribe({
      next: () => this.showNotification("Compétence retirée.", 'info'),
      error: (err) => this.showNotification("Erreur lors de la suppression", 'error')
    });
  }

  addSuggestedSkill(skillName: string) {
    const foundSkill = this.allAdminSkills.find(s => s.nom.toLowerCase() === skillName.toLowerCase());
    if (foundSkill) {
      if (this.mySkills.some(s => s.id === foundSkill.id)) {
        this.showNotification("Vous possédez déjà cette compétence.", 'info');
      } else {
        this.selectSkill(foundSkill);
      }
    } else {
      this.showNotification("Compétence introuvable dans le catalogue.", 'error');
    }
  }

  hideSuggestions() {
    setTimeout(() => {
      this.showSuggestions = false;
    }, 200);
  }

  saveProfile() {
    this.userService.updateUser(Number(this.currentUserId), this.freelancerInfo).subscribe({
      next: () => this.showNotification("Profil mis à jour avec succès !", 'success'),
      error: (err) => this.showNotification("Erreur lors de la mise à jour du profil.", 'error')
    });
  }
}
