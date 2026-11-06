import { Component, OnInit } from '@angular/core';
import { CompetanceService } from '../../Services/competance.service';
import { Competance } from '../../models/Competance';
import { Router } from '@angular/router';

@Component({
  selector: 'app-competence-admin',
  templateUrl: './competence-admin.component.html',
  styleUrl: './competence-admin.component.css'
})
export class CompetenceAdminComponent implements OnInit {
  skills: Competance[] = [];
  searchTerm: string = '';
  selectedCategory: string = 'All';
  
  categories: string[] = ['All', 'Développement Web', 'Mobile', 'Design', 'Data Science', 'Marketing'];
  niveaux: string[] = ['Débutant', 'Intermédiaire', 'Avancé', 'Expert'];

  isModalOpen: boolean = false;
  isEditMode: boolean = false;
  currentSkillId: number | null = null;

  // Variables de Pagination
  currentPage: number = 1;
  pageSize: number = 7; 

  // Form Variables
  formNom: string = '';
  formCategorie: string = 'Développement Web';
  formNiveau: string = 'Débutant';
  formDescription: string = '';

 
  currentUser: any = null;
  currentAdminId: string = '';

  constructor(
    private competenceService: CompetanceService,
    private router: Router 
  ) {}

  ngOnInit(): void {
    
    this.loadUserData();
  }


  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    
    if (!storedData) {
      console.warn("Accès refusé : Aucun utilisateur connecté.");
      this.router.navigate(['/login']); 
      return;
    }

    try {
      let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
      if (token) {
        const payload = token.split('.')[1];
        const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
        
       
        if (decodedPayload.role && decodedPayload.role !== 'ADMIN') {
          console.warn("Accès refusé : Vous n'êtes pas Administrateur.");
          this.router.navigate(['/Auth']); 
          return;
        }

     
        this.currentAdminId = String(decodedPayload.id);
        
        
        this.loadSkills(); 
        
      } else {
        this.router.navigate(['/Auth']);
      }
    } catch (e) {
      console.error("Erreur de décodage du token :", e);
      localStorage.removeItem('currentUser');
      this.router.navigate(['/login']);
    }
  }


  loadSkills() {
    this.competenceService.getAllCompetances().subscribe({
      next: (data) => {
        
        this.skills = data.filter(skill => String(skill.userId) === this.currentAdminId);
      },
      error: (err) => console.error('Error loading skills', err)
    });
  }

  get filteredSkills() {
    return this.skills.filter(s => {
      const name = s.nom || ''; 
      const matchSearch = name.toLowerCase().includes(this.searchTerm.toLowerCase());
      const matchCat = this.selectedCategory === 'All' || s.categorie === this.selectedCategory;
      return matchSearch && matchCat;
    });
  }

  get paginatedSkills(): Competance[] {
    const startIndex = (this.currentPage - 1) * this.pageSize;
    return this.filteredSkills.slice(startIndex, startIndex + this.pageSize);
  }

  get totalPages(): number {
    return Math.ceil(this.filteredSkills.length / this.pageSize) || 1;
  }

  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
    }
  }

  prevPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
    }
  }

  onSearchChange() {
    this.currentPage = 1;
  }

  openAddModal() {
    this.isEditMode = false;
    this.currentSkillId = null;
    this.isModalOpen = true;
    
    this.formNom = '';
    this.formDescription = '';
    this.formCategorie = 'Développement Web';
    this.formNiveau = 'Débutant';
  }

  openEditModal(skill: Competance) {
    this.isEditMode = true;
    this.currentSkillId = skill.id!; 
    this.isModalOpen = true;

    this.formNom = skill.nom;
    this.formCategorie = skill.categorie;
    this.formNiveau = skill.niveau || 'Débutant';
    this.formDescription = skill.description || '';
  }

  closeModal() {
    this.isModalOpen = false;
  }

  saveSkill() {
    if (!this.formNom) {
      alert("Name is required!");
      return;
    }

    const skillData: Competance = {
      nom: this.formNom,
      categorie: this.formCategorie,
      niveau: this.formNiveau,
      description: this.formDescription,
      userId: this.currentAdminId, 
      cv: ""     
    };

    if (this.isEditMode && this.currentSkillId) {
      skillData.id = this.currentSkillId; 
      
      this.competenceService.updateCompetance(skillData).subscribe({
        next: (updatedSkill) => {
          const index = this.skills.findIndex(s => s.id === this.currentSkillId);
          if (index !== -1) {
            this.skills[index] = updatedSkill;
          }
          this.closeModal();
        },
        error: (err) => alert("Failed to update skill")
      });

    } else {
      this.competenceService.addCompetance(skillData).subscribe({
        next: (savedSkill) => {
          this.skills.unshift(savedSkill); 
          this.closeModal();
        },
        error: (err) => alert("Failed to add skill")
      });
    }
  }

  deleteSkill(id: any) {
    if(confirm("Are you sure?")) {
      this.competenceService.deleteCompetance(id).subscribe(() => {
        this.skills = this.skills.filter(s => s.id !== id);
        
        if (this.paginatedSkills.length === 0 && this.currentPage > 1) {
          this.currentPage--;
        }
      });
    }
  }
}