import { Component, OnInit } from '@angular/core';
import { Project } from '../../models/project.model';
import { ActivatedRoute, Router } from '@angular/router';
import { ProjectServiceService } from '../../Services/project-service.service';
import { Proposal } from '../../models/proposal';
import { UserService } from '../../Services/user.service';

@Component({
  selector: 'app-project-proposals',
  templateUrl: './project-proposals.component.html',
  styleUrl: './project-proposals.component.css'
})
export class ProjectProposalsComponent implements OnInit {
  
  projectId: number | null = null;
  project: Project | null = null;
  proposals: Proposal[] = [];
  
  isLoading: boolean = true;
  
  averageBid: number = 0;
  shortlistedCount: number = 0;

  currentUser: any = null; 
  freelancersMap: { [key: number]: any } = {}; 

  // Modal State Variables
  showConfirmPopup: boolean = false;
  proposalToAccept: Proposal | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router, 
    private projectService: ProjectServiceService,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    this.loadUserData(); 

    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      this.projectId = Number(idParam);
      this.loadProjectDetails(this.projectId);
      this.loadProposals(this.projectId);
    } else {
      this.isLoading = false;
    }
  }

  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        if (token) {
          const payload = token.split('.')[1];
          const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
          if (decodedPayload.id) {
            this.userService.getUserById(decodedPayload.id).subscribe({
              next: (user) => this.currentUser = user,
              error: (err) => console.error("Erreur Backend Profil :", err)
            });
          }
        }
      } catch (e) {
        console.error("Erreur token :", e);
      }
    }
  }

  loadProjectDetails(id: number) {
    this.projectService.getProjectById(id).subscribe({
      next: (data) => this.project = data,
      error: (err) => console.error("Error loading project details", err)
    });
  }

  loadProposals(projectId: number) {
    this.projectService.getProposalsForProject(projectId).subscribe({
      next: (data) => {
        this.proposals = data;
        this.calculateStats();
        this.fetchFreelancersInfo(); 
        this.isLoading = false;
      },
      error: (err) => {
        console.error("Error loading proposals", err);
        this.isLoading = false;
      }
    });
  }

  fetchFreelancersInfo() {
    this.proposals.forEach(prop => {
      if (prop.freelancerId && !this.freelancersMap[prop.freelancerId]) {
        this.userService.getUserById(prop.freelancerId).subscribe({
          next: (user) => {
            this.freelancersMap[prop.freelancerId] = user;
          },
          error: (err) => console.error("Erreur chargement freelance", err)
        });
      }
    });
  }

  calculateStats() {
    if (this.proposals.length === 0) {
      this.averageBid = 0;
      this.shortlistedCount = 0;
      return;
    }

    const totalBids = this.proposals.reduce((sum, p) => sum + p.bidAmount, 0);
    this.averageBid = Math.round(totalBids / this.proposals.length);
    
    this.shortlistedCount = this.proposals.filter(p => p.status === 'ACCEPTED').length;
  }

  // --- Modal Logic Methods ---
  promptAccept(proposal: Proposal) {
    this.proposalToAccept = proposal;
    this.showConfirmPopup = true;
  }

  cancelAccept() {
    this.showConfirmPopup = false;
    this.proposalToAccept = null;
  }

  confirmAccept() {
    if (this.proposalToAccept) {
      this.updateStatus(this.proposalToAccept, 'ACCEPTED'); 
      this.showConfirmPopup = false;
      this.proposalToAccept = null;
    }
  }

  // --- Original Status Update Method ---
  updateStatus(proposal: Proposal, newStatus: string) {
    if (!proposal.id) return;

    this.projectService.updateProposalStatus(proposal.id, newStatus).subscribe({
      next: (updatedProposal) => {
        console.log(`Statut mis à jour : ${newStatus}`);
        
        const index = this.proposals.findIndex(p => p.id === proposal.id);
        if (index !== -1) {
          this.proposals[index].status = newStatus;
          this.calculateStats();
        }

        if (newStatus === 'ACCEPTED' && this.projectId) {
          this.projectService.updateProjectStatus(this.projectId, 'ACTIVE').subscribe({
            next: (updatedProject) => {
              console.log('Project status updated to ACTIVE');
              this.project = updatedProject; 
            },
            error: (err) => console.error("Error updating project status", err)
          });

          const fUser = this.freelancersMap[proposal.freelancerId];
          const fName = fUser 
            ? `${fUser.firstName} ${fUser.lastName || ''}`.trim() 
            : `Freelancer #${proposal.freelancerId}`;

          this.router.navigate(['/ClientCreateContract', proposal.id], {
            state: {
              freelancerName: fName,
              freelancerId: proposal.freelancerId,
              projectTitle: this.project?.title || 'Project',
              bidAmount: proposal.bidAmount
            }
          });
        }
      },
      error: (err) => {
        console.error("Erreur mise à jour statut", err);
        alert("Failed to update status. Please try again.");
      }
    });
  }
}