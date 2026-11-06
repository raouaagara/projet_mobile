import { Component, OnInit } from '@angular/core';
import { Contract } from '../../models/contract';
import { ContractService } from '../../Services/contract.service';

@Component({
  selector: 'app-jobs-admin',
  templateUrl: './jobs-admin.component.html',
  styleUrl: './jobs-admin.component.css'
})
export class JobsAdminComponent implements OnInit {
  contracts: Contract[] = [];
  filteredContracts: Contract[] = [];
  isLoading: boolean = true;

  // Stats
  totalJobs: number = 0;
  activeContracts: number = 0;
  completedMonth: number = 0;
  disputes: number = 0;

  constructor(private contractService: ContractService) {}

  ngOnInit(): void {
    this.loadAllContracts();
  }

  loadAllContracts() {
    this.isLoading = true;
    this.contractService.getAllContracts().subscribe({
      next: (data) => {
        this.contracts = data;
        this.filteredContracts = data;
        this.calculateStats();
        this.isLoading = false;
      },
      error: (err) => {
        console.error("Error fetching contracts for admin:", err);
        this.isLoading = false;
      }
    });
  }

  calculateStats() {
    this.totalJobs = this.contracts.length;
    this.activeContracts = this.contracts.filter(c => c.status === 'ACTIVE').length;
    this.disputes = this.contracts.filter(c => c.status === 'DISPUTE').length;
    
    // Calculate completed in the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    this.completedMonth = this.contracts.filter(c => 
      c.status === 'COMPLETED' // Ensure your backend uses this status
    ).length;
  }

  // Helper to map backend status to your CSS classes
  getStatusClass(status: string): string {
    switch (status?.toUpperCase()) {
      case 'ACTIVE': return 'active';
      case 'SENT': return 'open';
      case 'COMPLETED': return 'completed';
      case 'REJECTED': return 'danger';
      case 'DISPUTE': return 'dispute';
      default: return 'open';
    }
  }

  getStatusLabel(status: string): string {
    switch (status?.toUpperCase()) {
      case 'ACTIVE': return 'In Progress';
      case 'SENT': return 'Pending Signature';
      case 'COMPLETED': return 'Completed';
      case 'REJECTED': return 'Rejected';
      case 'DISPUTE': return 'Dispute';
      default: return status;
    }
  }
}