import { Component, OnInit } from '@angular/core';
import { PaymentService } from '../../Services/payment.service';

@Component({
  selector: 'app-admin-finance',
  templateUrl: './admin-finance.component.html',
  styleUrl: './admin-finance.component.css'
})
export class AdminFinanceComponent implements OnInit {
  escrowTransactions: any[] = [];
  stats = { totalEscrow: 0, pendingPayouts: 0, revenue: 12450 };
  loading: boolean = false;

  // Modal State
  showReleaseModal = false;
  selectedEscrow: any = null;
  releasePercent: number = 0;
  calculatedAmount: number = 0;

  constructor(private paymentService: PaymentService) {}

  ngOnInit(): void {
    this.loadFinanceData();
  }

  loadFinanceData() {
    this.loading = true;
    this.paymentService.getAllEscrowTransactions().subscribe({
      next: (data) => {
        this.escrowTransactions = data;
        this.calculateStats();
        this.loading = false;
      },
      error: (err) => {
        console.error("Finance Load Error", err);
        this.loading = false;
      }
    });
  }

  calculateStats() {
    this.stats.totalEscrow = this.escrowTransactions
      .filter(t => t.status === 'LOCKED')
      .reduce((acc, curr) => acc + curr.remainingAmount, 0);
    
    this.stats.pendingPayouts = this.escrowTransactions
      .filter(t => t.status === 'LOCKED').length;
  }

  // --- Modal Logic ---

  openReleaseModal(escrow: any) {
    this.selectedEscrow = escrow;
    this.releasePercent = 0;
    this.calculatedAmount = 0;
    this.showReleaseModal = true;
  }

  closeModal() {
    this.showReleaseModal = false;
    this.selectedEscrow = null;
  }

  updateAmountFromPercent() {
    if (this.selectedEscrow) {
      // Calculate amount based on the remaining balance
      this.calculatedAmount = (this.selectedEscrow.remainingAmount * this.releasePercent) / 100;
    }
  }

  confirmPartialRelease() {
    if (!this.selectedEscrow || this.calculatedAmount <= 0) return;

    if (confirm(`Confirm release of $${this.calculatedAmount.toFixed(2)} to ${this.selectedEscrow.freelancerName}?`)) {
      this.paymentService.releasePartial(this.selectedEscrow.id, this.calculatedAmount).subscribe({
        next: () => {
          alert("Funds released successfully!");
          this.closeModal();
          this.loadFinanceData(); // Refresh table
        },
        error: (err) => {
          alert("Error releasing funds: " + (err.error?.message || err.message));
        }
      });
    }
  }

  refundClient(escrowId: number) {
    if (confirm('This will return all remaining funds to the client. Proceed?')) {
      this.paymentService.refundEscrow(escrowId).subscribe({
        next: () => {
          alert("Refund processed.");
          this.loadFinanceData();
        }
      });
    }
  }
}