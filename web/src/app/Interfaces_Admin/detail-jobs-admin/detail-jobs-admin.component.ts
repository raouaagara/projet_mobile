import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ContractService } from '../../Services/contract.service';
import { PaymentService } from '../../Services/payment.service';
import { Contract } from '../../models/contract';
import { AiExtractorService, AiInsight } from '../../Services/ai-extractor.service';

@Component({
  selector: 'app-detail-jobs-admin',
  templateUrl: './detail-jobs-admin.component.html',
  styleUrl: './detail-jobs-admin.component.css'
})
export class DetailJobsAdminComponent implements OnInit {
  contractId!: number;
  contract: Contract | null = null;
  escrow: any = null;
  isLoading: boolean = true;

  // AI Analysis states
  aiInsights: AiInsight[] = [];
  isAnalyzingAi: boolean = false;

  constructor(
    private route: ActivatedRoute,
    private contractService: ContractService,
    private paymentService: PaymentService,
    private aiExtractor: AiExtractorService
  ) {}

  ngOnInit(): void {
    // 1. Get the ID from the URL
    this.contractId = Number(this.route.snapshot.paramMap.get('id'));
    
    if (this.contractId) {
      this.loadContractDetails();
    }
  }

  loadContractDetails() {
    this.isLoading = true;
    // 2. Fetch Contract Data
    this.contractService.getContractById(this.contractId).subscribe({
      next: (data) => {
        this.contract = data;
        this.loadEscrowDetails(); // Fetch financial data once we have the contract
        
        // Start AI Analysis on the contract terms
        if (this.contract && this.contract.terms) {
          this.analyzeContractTerms(this.contract.terms);
        }
      },
      error: (err) => {
        console.error("Error loading contract", err);
        this.isLoading = false;
      }
    });
  }

  loadEscrowDetails() {
    // 3. Fetch Escrow Data using the contractId
    this.paymentService.getEscrowByContractId(this.contractId).subscribe({
      next: (data) => {
        this.escrow = data;
        this.isLoading = false;
      },
      error: (err) => {
        console.warn("No escrow found for this contract", err);
        this.isLoading = false;
      }
    });
  }

  analyzeContractTerms(terms: string) {
    this.isAnalyzingAi = true;
    this.aiExtractor.extractKeyPoints(terms).subscribe({
      next: (insights) => {
        this.aiInsights = insights;
        this.isAnalyzingAi = false;
      },
      error: (err) => {
        console.error("Error analyzing terms with AI", err);
        this.isAnalyzingAi = false;
      }
    });
  }

  // Helper for Status Classes
  getStatusClass(status: string | undefined): string {
    if (!status) return 'open';
    const s = status.toUpperCase();
    if (s === 'ACTIVE') return 'active';
    if (s === 'COMPLETED') return 'completed';
    if (s === 'DISPUTE') return 'dispute';
    return 'open';
  }
}