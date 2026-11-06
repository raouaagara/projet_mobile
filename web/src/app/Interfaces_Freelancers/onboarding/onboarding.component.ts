import { Component, OnInit } from '@angular/core';
import { CompetanceService } from '../../Services/competance.service';
import { Router } from '@angular/router';
import { Competance } from '../../models/Competance';
import { UserService } from '../../Services/user.service';

@Component({
  selector: 'app-onboarding',
  templateUrl: './onboarding.component.html',
  styleUrls: ['./onboarding.component.css'] 
})
export class OnboardingComponent implements OnInit {
  // Data Containers
  allSkills: Competance[] = [];       
  filteredSkills: Competance[] = [];  
  selectedSkills: Set<number> = new Set(); 

  // Pagination
  currentPage: number = 1;
  pageSize: number = 12; 

  // File Upload
  selectedFile: File | null = null;
  selectedFileName: string = '';

  searchText: string = '';
  currentUserId: string = ''; 
  isParsingMode: boolean = false; 

  // Système de Notification (Toast)
  notification = { message: '', type: 'success', visible: false };

  constructor(
    private competenceService: CompetanceService, 
    private router: Router,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    this.loadUserData();

    this.competenceService.getAllCompetances().subscribe({
      next: (data) => {
        const adminSkills = data.filter(skill => String(skill.userId) === '5');
        this.allSkills = adminSkills; 
        this.filteredSkills = adminSkills;
      },
      error: (err) => this.showNotification("Erreur de chargement du catalogue", 'error')
    });
  }

  showNotification(message: string, type: 'success' | 'error' | 'info' = 'success') {
    this.notification = { message, type, visible: true };
    setTimeout(() => {
      this.notification.visible = false;
    }, 3500); 
  }

  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    
    if (!storedData) {
      this.showNotification("Aucun utilisateur connecté.", 'error');
      setTimeout(() => this.router.navigate(['/login']), 1500);
      return;
    }

    try {
      let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
      if (token) {
        const payload = token.split('.')[1];
        const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
        this.currentUserId = String(decodedPayload.id); 
      }
    } catch (e) {
      localStorage.removeItem('currentUser');
      this.router.navigate(['/login']);
    }
  }

  get paginatedSkills(): Competance[] {
    const startIndex = (this.currentPage - 1) * this.pageSize;
    return this.filteredSkills.slice(startIndex, startIndex + this.pageSize);
  }

  get totalPages(): number {
    return Math.ceil(this.filteredSkills.length / this.pageSize) || 1;
  }

  nextPage() {
    if (this.currentPage < this.totalPages) this.currentPage++;
  }

  prevPage() {
    if (this.currentPage > 1) this.currentPage--;
  }

  onFileSelected(event: any) {
    const file: File = event.target.files[0];
    
    if (file) {
      this.selectedFile = file;
      this.selectedFileName = file.name;
      this.isParsingMode = true; 
      
      this.competenceService.parseCv(file).subscribe({
        next: (matchedSkills: any) => {
          console.log("🛠️ DEBUG - Réponse du backend :", matchedSkills);
          
          let count = 0;
          
          const skillsArray = Array.isArray(matchedSkills) ? matchedSkills : [matchedSkills];

          skillsArray.forEach((skill: any) => {
            let skillName = '';
            let skillId = null;

            if (typeof skill === 'object' && skill !== null) {
              skillName = String(skill.nom || skill.name || skill.title || '').toLowerCase().trim();
              skillId = skill.id;
            } else if (typeof skill === 'string') {
              skillName = skill.toLowerCase().trim();
            }

            if (skillName) {
              const foundInCatalog = this.allSkills.find(s => 
                s.nom && s.nom.toLowerCase().trim() === skillName
              );
              
              if (foundInCatalog && foundInCatalog.id) {
                this.selectedSkills.add(Number(foundInCatalog.id));
                count++;
              } else if (skillId) {
                this.selectedSkills.add(Number(skillId));
                count++;
              }
            } else if (skillId) {
              this.selectedSkills.add(Number(skillId));
              count++;
            }
          });
          
          this.isParsingMode = false; 
          
          if (count > 0) {
            this.showNotification(`Magie ! ${count} compétences détectées et cochées.`, 'success');
          } else {
            this.showNotification("Aucune compétence du catalogue n'a été détectée dans ce CV.", 'info');
          }
        },
        error: (err) => {
          console.error("Erreur de parsing backend", err);
          this.showNotification("Erreur lors de l'analyse du CV par l'IA.", 'error');
          this.isParsingMode = false;
        }
      });
    }
  }

  applyFilter() {
    const text = this.searchText.toLowerCase();
    this.filteredSkills = this.allSkills.filter(s => 
      s.nom.toLowerCase().includes(text) || 
      (s.categorie && s.categorie.toLowerCase().includes(text))
    );
    this.currentPage = 1; 
  }

  toggleSkill(skill: Competance) {
    if (skill.id) {
      if (this.selectedSkills.has(Number(skill.id))) {
        this.selectedSkills.delete(Number(skill.id));
      } else {
        this.selectedSkills.add(Number(skill.id));
      }
    }
  }

  isSelected(skill: Competance): boolean {
    return skill.id ? this.selectedSkills.has(Number(skill.id)) : false;
  }

  completeProfile() {
    if (this.selectedSkills.size === 0) {
      this.showNotification("Veuillez sélectionner au moins une compétence.", 'error');
      return;
    }
    
    if (!this.selectedFile) {
      this.showNotification("Veuillez uploader votre CV.", 'error');
      return;
    }

    const selectedIdsArray: number[] = Array.from(this.selectedSkills);

    this.userService.updateUserCompetences(this.currentUserId, selectedIdsArray).subscribe({
      next: (response) => {
        
        this.userService.uploadCv(this.currentUserId, this.selectedFile!).subscribe({
          next: () => {
            this.showNotification("Profil complété avec succès !", 'success');
            setTimeout(() => {
              this.router.navigate(['/FreelancerFeed']); // 🟢 Redirection vers le Feed au lieu de ProfileManager
            }, 1500);
          },
          error: (err) => {
            console.error("Erreur CV", err);
            this.showNotification("Compétences sauvées, mais échec de l'upload du CV.", 'error');
          }
        });

      },
      error: (err) => {
        console.error("Erreur Compétences", err);
        this.showNotification("Erreur lors de la sauvegarde des compétences.", 'error');
      }
    });
  }
}