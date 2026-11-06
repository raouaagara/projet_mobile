import { Component, OnInit } from '@angular/core';
import { PaymentService } from '../../Services/payment.service';

@Component({
  selector: 'app-freelancer-wallet',
  templateUrl: './freelancer-wallet.component.html',
  styleUrl: './freelancer-wallet.component.css'
})
export class FreelancerWalletComponent implements OnInit {
  wallet: any = null;
  escrows: any[] = [];
  transactions: any[] = [];
  
  totalPending: number = 0;
  activeContractsCount: number = 0;
  loading: boolean = true;
  
  userId: number = 0;

  constructor(private paymentService: PaymentService) {}

  ngOnInit(): void {
    this.extractUserId();
    if (this.userId > 0) {
      this.loadData();
    } else {
      this.loading = false;
    }
  }

  extractUserId() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        const payload = token.split('.')[1];
        const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
        this.userId = Number(decodedPayload.id);
      } catch (e) {
        console.error("Token Error:", e);
      }
    }
  }

  loadData() {
    this.loading = true;
    this.paymentService.getWallet(this.userId).subscribe({
      next: (data) => {
        this.wallet = data;
        this.loading = false;
        if (this.wallet) {
          this.loadFinanceDetails();
        }
      },
      error: (err) => {
        this.wallet = null; // Wallet doesn't exist yet
        this.loading = false;
      }
    });
  }

  loadFinanceDetails() {
    // 1. Get Freelancer specific escrows
    this.paymentService.getFreelancerEscrows(this.userId).subscribe({
      next: (data) => {
        this.escrows = data;
        const activeEscrows = data.filter((e: any) => e.status === 'LOCKED');
        this.totalPending = activeEscrows.reduce((sum: number, item: any) => sum + item.remainingAmount, 0);
        this.activeContractsCount = activeEscrows.length;
      }
    });

    // 2. Get Transactions
    this.paymentService.getTransactions(this.userId).subscribe({
      next: (data) => {
        this.transactions = data;
      }
    });
  }

  initializeWallet() {
    this.paymentService.createWalletFreelancer(this.userId).subscribe({
      next: (newWallet) => {
        this.wallet = newWallet;
        alert("Freelancer Wallet activated! 🎉");
        this.loadData();
      },
      error: (err) => alert("Error creating wallet.")
    });
  }

  handleWithdraw() {
    if (this.wallet?.balance <= 0) return alert("No funds available to withdraw.");
    const amount = prompt("Enter withdrawal amount ($):");
    if (amount && !isNaN(+amount) && +amount > 0) {
       // logic for withdrawal request
       alert("Withdrawal request of $" + amount + " sent to admin!");
    }
  }
}