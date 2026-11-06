import { Component, OnInit } from '@angular/core';
import { ContractService } from '../../Services/contract.service';
import { Contract } from '../../models/contract';
import { UserService } from '../../Services/user.service';

@Component({
  selector: 'app-freelancer-contracts',
  templateUrl: './freelancer-contracts.component.html',
  styleUrls: ['./freelancer-contracts.component.css']
})
export class FreelancerContractsComponent implements OnInit {

  contracts: Contract[] = [];
  isLoading: boolean = true;
  currentTab: string = 'active'; // active, offers, rejected
  
  currentUser: any = null; 
  freelancerId!: number; 

  constructor(
    private contractService: ContractService,
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
          this.freelancerId = decodedPayload.id;

          if (this.freelancerId) {
            this.userService.getUserById(this.freelancerId).subscribe({
              next: (user) => {
                this.currentUser = user;
                this.loadContracts(); 
              },
              error: (err) => {
                console.error("Erreur Backend Profil :", err);
                this.isLoading = false;
              }
            });
          }
        }
      } catch (e) {
        console.error("Erreur token :", e);
        this.isLoading = false;
      }
    } else {
      this.isLoading = false;
    }
  }

  loadContracts() {
    this.isLoading = true;
    this.contractService.getFreelancerContracts(this.freelancerId).subscribe({
      next: (data) => {
        this.contracts = data;
        this.isLoading = false;
        
        // Auto-switch tab if no active jobs but offers exist
        if (this.getActiveCount() === 0 && this.getPendingCount() > 0) {
          this.currentTab = 'offers';
        }
      },
      error: (err) => {
        console.error('Error loading contracts:', err);
        this.isLoading = false;
      }
    });
  }

  rejectContract(contractId: number) {
    if(!confirm("Are you sure you want to decline this job offer?")) return;

    this.contractService.rejectContract(contractId).subscribe({
      next: () => {
        const index = this.contracts.findIndex(c => c.id === contractId);
        if (index !== -1) {
          this.contracts[index].status = 'REJECTED';
        }
        this.currentTab = 'rejected'; // Move user to rejected tab to see the result
      },
      error: (err) => alert("Error declining offer.")
    });
  }

  getPendingCount(): number {
    return this.contracts.filter(c => c.status === 'SENT').length;
  }

  getActiveCount(): number {
    return this.contracts.filter(c => c.status === 'ACTIVE').length;
  }

  getRejectedCount(): number {
    return this.contracts.filter(c => c.status === 'REJECTED').length;
  }
}