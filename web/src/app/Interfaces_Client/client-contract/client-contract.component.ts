import { Component, OnInit } from '@angular/core';
import { Contract } from '../../models/contract';
import { ContractService } from '../../Services/contract.service';
import { UserService } from '../../Services/user.service';

@Component({
  selector: 'app-client-contract',
  templateUrl: './client-contract.component.html',
  styleUrls: ['./client-contract.component.css']
})
export class ClientContractComponent implements OnInit {
  
  contracts: Contract[] = [];
  isLoading: boolean = true;
  currentTab: string = 'active'; // active, pending, rejected

  currentUser: any = null;
  clientId!: number;

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
          this.clientId = decodedPayload.id;

          if (this.clientId) {
            this.userService.getUserById(this.clientId).subscribe({
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
    if (!this.clientId) return;
    this.isLoading = true;

    this.contractService.getClientContracts(this.clientId).subscribe({
      next: (data) => {
        this.contracts = data.reverse();
        this.isLoading = false;
      },
      error: (err) => {
        console.error("Error loading contracts:", err);
        this.isLoading = false;
      }
    });
  }

  // Count helpers for the UI
  getActiveCount(): number {
    return this.contracts.filter(c => c.status === 'ACTIVE' || c.status === 'SIGNED').length;
  }

  getPendingCount(): number {
    return this.contracts.filter(c => c.status === 'SENT').length;
  }

  getRejectedCount(): number {
    return this.contracts.filter(c => c.status === 'REJECTED').length;
  }
}