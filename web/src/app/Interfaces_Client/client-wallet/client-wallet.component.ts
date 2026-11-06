import { Component, OnInit } from '@angular/core';
import { PaymentService } from '../../Services/payment.service';

@Component({
  selector: 'app-client-wallet',
  templateUrl: './client-wallet.component.html',
  styleUrl: './client-wallet.component.css'
})
export class ClientWalletComponent implements OnInit {
  wallet: any = null;
  escrows: any[] = [];
  transactions: any[] = [];
  
  totalLocked: number = 0;
  activeEscrowCount: number = 0;
  loading: boolean = true;
  
  userId: number = 0;

  constructor(private paymentService: PaymentService) {}

  ngOnInit(): void {
    this.extractUserId();
    
    if (this.userId > 0) {
      this.loadData();
    } else {
      console.error("🔴 No User ID found in session. Please log in.");
      this.loading = false;
    }
  }

  // 🟢 MATCHED TO YOUR PROFILE COMPONENT LOGIC
  extractUserId() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        // Handle both raw token or JSON object with token property
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        const payload = token.split('.')[1];
        const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
        this.userId = Number(decodedPayload.id);
        console.log("🟢 Wallet loaded for User ID:", this.userId);
      } catch (e) {
        console.error("🔴 Token Decoding Error :", e);
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
        console.warn("⚠️ Wallet not found for this user.");
        this.wallet = null; 
        this.loading = false;
      }
    });
  }

  loadFinanceDetails() {
    this.paymentService.getClientEscrows(this.userId).subscribe({
      next: (data) => {
        this.escrows = data;
        const activeEscrows = data.filter((e: any) => e.status === 'LOCKED');
        this.activeEscrowCount = activeEscrows.length;
        this.totalLocked = activeEscrows.reduce((sum: number, item: any) => sum + item.remainingAmount, 0);
      }
    });

    this.paymentService.getTransactions(this.userId).subscribe({
      next: (data) => {
        this.transactions = data;
      }
    });
  }

initializeWallet() {
  if (!this.userId) {
    alert("User ID not found. Please log in again.");
    return;
  }

  console.log("Attempting to create wallet for user ID:", this.userId);

  this.paymentService.createWallet(this.userId).subscribe({
    next: (res) => {
      console.log("Server Response:", res);
      // Check if the response actually contains an ID from the database
      if (res && res.id) {
        this.wallet = res;
        alert("Wallet created successfully! 🎉");
        this.loadData(); // This will refresh the balance and UI
      } else {
        alert("Server said OK, but no wallet was created. Check your Java console.");
      }
    },
    error: (err) => {
      console.error("Creation failed:", err);
      alert("Error: " + (err.error?.message || "Internal Server Error"));
    }
  });
}

  handleTopUp() {
    const amount = prompt("Enter deposit amount ($):");
    if (amount && !isNaN(+amount) && +amount > 0) {
      this.paymentService.topUp(this.userId, +amount).subscribe({
        next: () => {
          alert("Deposit Successful!");
          this.loadData();
        },
        error: (err) => alert("Deposit failed. Check backend logs.")
      });
    }
  }

  getProgress(released: number, total: number): number {
    if (!total || total === 0) return 0;
    return (released / total) * 100;
  }
}