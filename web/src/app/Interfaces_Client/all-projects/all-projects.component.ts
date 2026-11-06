import { Component, HostListener, OnInit } from '@angular/core';
import { Project } from '../../models/project.model';
import { ProjectServiceService } from '../../Services/project-service.service';
import { UserService } from '../../Services/user.service';

@Component({
  selector: 'app-all-projects',
  templateUrl: './all-projects.component.html',
  styleUrls: ['./all-projects.component.css']
})
export class AllProjectsComponent implements OnInit {

  selectedTab: string = 'OPEN';
  projects: Project[] = [];
  activeMenuId: number | null = null;
  searchText: string = '';

  currentUser: any = null;

  isEditModalOpen: boolean = false;
  projectToEdit: Project = {} as Project;

  isConfirmDeleteOpen: boolean = false;
  isConfirmCloseOpen: boolean = false;
  projectActionId: number | null = null;

  showNvidiaToast: boolean = false;
  toastMessage: string = '';

  constructor(
    private projectService: ProjectServiceService,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    this.loadUserData();
  }

  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        if (token) {
          const payload = token.split('.')[1];
          const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
          const currentUserId = decodedPayload.id;

          if (currentUserId) {
            this.userService.getUserById(currentUserId).subscribe({
              next: (user) => {
                this.currentUser = user;
                this.loadMyProjects();
              },
              error: (err) => console.error('Erreur Backend Profil :', err)
            });
          }
        }
      } catch (e) {
        console.error('Erreur de décodage du token :', e);
      }
    }
  }


  loadMyProjects() {
    this.projectService.getAllProjects().subscribe({
      next: (data) => {
        if (this.currentUser && this.currentUser.id) {
          const myId = this.currentUser.id;
          // 1. Filter and reverse projects
          this.projects = data.filter(p => p.clientId === myId).reverse();
          
          // 2. Fetch proposals for each project to fix the "0" issue
          this.projects.forEach(project => {
            if (project.id) {
              this.projectService.getProposalsForProject(project.id).subscribe({
                next: (proposals) => {
                  project.proposals = proposals; // Assign the actual list to the project
                },
                error: (err) => console.error(`Error loading proposals for project ${project.id}`, err)
              });
            }
          });
        } else {
          this.projects = [];
        }
      },
      error: (err) => console.error('Erreur de chargement', err)
    });
  }

  get filteredProjects() {
    return this.projects.filter(p => {
      const matchesStatus = p.status === this.selectedTab;
      const matchesSearch = p.title.toLowerCase().includes(this.searchText.toLowerCase());
      return matchesStatus && matchesSearch;
    });
  }

  getCount(status: string): number {
    return this.projects.filter(p => p.status === status).length;
  }

  setTab(tab: string) {
    this.selectedTab = tab;
  }

  formatEnumText(value: string | undefined): string {
    if (!value) return 'Uncategorized';
    return value.replace(/_/g, ' ').replace(/\w\S*/g, (txt) =>
      txt.charAt(0).toUpperCase() + txt.substring(1).toLowerCase()
    );
  }

  toggleMenu(id: number | undefined, event: MouseEvent) {
    if (!id) return;
    event.stopPropagation();
    this.activeMenuId = this.activeMenuId === id ? null : id;
  }

  @HostListener('document:click')
  closeMenu() {
    this.activeMenuId = null;
  }

  editProject(id: number | undefined) {
    if (!id) return;
    this.activeMenuId = null;
    const proj = this.projects.find(p => p.id === id);
    if (proj) {
      this.projectToEdit = JSON.parse(JSON.stringify(proj));
      this.isEditModalOpen = true;
      document.body.style.overflow = 'hidden';
    }
  }

  closeEditModal() {
    this.isEditModalOpen = false;
    document.body.style.overflow = 'auto';
  }

  saveUpdatedProject() {
    if (!this.projectToEdit.id) return;

    this.projectService.updateProject(this.projectToEdit.id, this.projectToEdit).subscribe({
      next: (updatedProject) => {
        const index = this.projects.findIndex(p => p.id === updatedProject.id);
        if (index !== -1) {
          this.projects[index] = updatedProject;
        }
        this.closeEditModal();
        this.triggerNvidiaToast('SYSTEM_UPDATE: Project modified successfully.');
      },
      error: (err) => {
        console.error(err);
        alert('Error updating the project.');
      }
    });
  }

  openCloseConfirm(id: number | undefined) {
    if (!id) return;
    this.projectActionId = id;
    this.isConfirmCloseOpen = true;
    this.activeMenuId = null;
    document.body.style.overflow = 'hidden';
  }

  cancelClose() {
    this.isConfirmCloseOpen = false;
    this.projectActionId = null;
    document.body.style.overflow = 'auto';
  }

  confirmCloseJob() {
    if (!this.projectActionId) return;

    this.projectService.updateProjectStatus(this.projectActionId, 'CLOSED').subscribe({
      next: () => {
        const projectIndex = this.projects.findIndex(p => p.id === this.projectActionId);
        if (projectIndex !== -1) {
          this.projects[projectIndex].status = 'CLOSED';
        }
        this.cancelClose();
        this.triggerNvidiaToast('STATUS_OVERRIDE: Project is now closed.');
      },
      error: (err) => {
        console.error(err);
        alert('Error closing the project.');
      }
    });
  }

  openDeleteConfirm(id: number | undefined) {
    if (!id) return;
    this.projectActionId = id;
    this.isConfirmDeleteOpen = true;
    this.activeMenuId = null;
    document.body.style.overflow = 'hidden';
  }

  cancelDelete() {
    this.isConfirmDeleteOpen = false;
    this.projectActionId = null;
    document.body.style.overflow = 'auto';
  }

  confirmDeleteProject() {
    if (!this.projectActionId) return;

    this.projectService.deleteProject(this.projectActionId).subscribe({
      next: () => {
        this.projects = this.projects.filter(p => p.id !== this.projectActionId);
        this.cancelDelete();
        this.triggerNvidiaToast('DATA_PURGED: Project deleted successfully.');
      },
      error: (err) => {
        console.error(err);
        alert('Error deleting the project.');
      }
    });
  }

  triggerNvidiaToast(message: string) {
    this.toastMessage = message;
    this.showNvidiaToast = true;
    setTimeout(() => {
      this.showNvidiaToast = false;
    }, 3500);
  }
}