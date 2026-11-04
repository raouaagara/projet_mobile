import { Component, OnInit } from '@angular/core';
import { SubscriptionService, UserSubscription } from '../../services-ayoub/subscription.service';
import { UserService } from '../../services-ayoub/user.service';
import jsPDF from 'jspdf';
import QRCode from 'qrcode';

interface Payment {
  id?: number;
  date: string;
  amount: number;
  status: string;
  invoiceRef?: string;
}

@Component({
  selector: 'app-subscription-dashboard',
  templateUrl: './subscription-dashboard.component.html',
  styleUrl: './subscription-dashboard.component.css'
})
export class SubscriptionDashboardComponent implements OnInit {
  currentUserId: number | null = null;

  subscription: UserSubscription | null = null;
  paymentHistory: Payment[] = [];
  loading = true;
  renewingSubscription = false;

  // Helper method to check AI CV access
  get hasAiCvAccess(): boolean {
    const hasAccess = this.subscription?.plan?.hasAiCvAccess === true;
    console.log('🔍 DEBUG: hasAiCvAccess computed:', hasAccess);
    return hasAccess;
  }

  // Helper method to get plan type
  get planType(): string {
    const type = this.subscription?.plan?.type || 'UNKNOWN';
    console.log('🔍 DEBUG: planType computed:', type);
    return type;
  }

  constructor(
    private subscriptionService: SubscriptionService,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    // Get current logged-in user
    const currentUser = this.userService.getCurrentUser();
    console.log('🔍 DEBUG: Current user from service:', currentUser);
    console.log('🔍 DEBUG: JWT token exists:', !!this.userService.getToken());
    
    if (currentUser?.id) {
      this.currentUserId = currentUser.id;
      console.log('✅ DEBUG: Using userId:', this.currentUserId);
      this.load();
    } else {
      // Try to get user from token if exists
      const token = this.userService.getToken();
      if (token) {
        try {
          const payload = JSON.parse(atob(token.split('.')[1]));
          this.currentUserId = payload.id;
          console.log('✅ DEBUG: Extracted userId from token:', this.currentUserId);
          this.load();
        } catch (error) {
          console.error('❌ DEBUG: Failed to parse token:', error);
          this.loading = false;
          alert('Please login to view your subscription');
        }
      } else {
        console.log('❌ DEBUG: No token found, user not logged in');
        this.loading = false;
        alert('Please login to view your subscription');
      }
    }
  }

  load(): void {
    if (!this.currentUserId) return;
    
    this.loading = true;
    this.subscriptionService.getActiveSubscription(this.currentUserId).subscribe((sub) => {
      console.log('🔍 DEBUG: Raw subscription data received:', sub);
      console.log('🔍 DEBUG: Subscription plan:', sub?.plan);
      console.log('🔍 DEBUG: Plan type:', sub?.plan?.type);
      console.log('🔍 DEBUG: Has AI CV Access:', sub?.plan?.hasAiCvAccess);
      
      this.subscription = sub || null;
      if (sub?.id) {
        this.subscriptionService.getPaymentsBySubscription(sub.id).subscribe((payments) => {
          this.paymentHistory = (payments || []).map((p: any) => ({
            id: p.id,
            date: p.paidAt ? String(p.paidAt).slice(0, 10) : '-',
            amount: p.amount ?? 0,
            status: p.status || 'Paid',
            invoiceRef: p.invoiceRef || `INV-${p.id}`
          }));
          this.loading = false;
        });
      } else {
        console.log('⚠️ DEBUG: No active subscription found for userId:', this.currentUserId);
        this.paymentHistory = [];
        this.loading = false;
      }
    });
  }
  
  renewSubscription(): void {
    if (!this.subscription?.id) return;
    
    if (!confirm('Renew your subscription for another month?')) return;
    
    this.renewingSubscription = true;
    this.subscriptionService.renewSubscription(this.subscription.id).subscribe({
      next: (renewed) => {
        if (renewed) {
          alert('Subscription renewed successfully!');
          this.load();
        } else {
          alert('Failed to renew subscription');
        }
        this.renewingSubscription = false;
      },
      error: () => {
        alert('Error renewing subscription');
        this.renewingSubscription = false;
      }
    });
  }
  
  async downloadInvoice(payment: Payment): Promise<void> {
    if (!this.subscription) return;
    
    try {
      const pdf = new jsPDF();
      
      // Header
      pdf.setFontSize(24);
      pdf.setTextColor(16, 185, 129);
      pdf.text('CatchOPP', 20, 20);
      
      pdf.setFontSize(10);
      pdf.setTextColor(100);
      pdf.text('Freelance Platform', 20, 27);
      
      // Invoice Title
      pdf.setFontSize(20);
      pdf.setTextColor(0);
      pdf.text('INVOICE', 150, 20);
      
      // Invoice Details
      pdf.setFontSize(10);
      pdf.text(`Invoice #: ${payment.invoiceRef}`, 150, 30);
      pdf.text(`Date: ${payment.date}`, 150, 37);
      pdf.text(`Status: ${payment.status}`, 150, 44);
      
      // Line
      pdf.setDrawColor(229, 231, 235);
      pdf.line(20, 50, 190, 50);
      
      // Bill To
      pdf.setFontSize(12);
      pdf.setTextColor(0);
      pdf.text('Bill To:', 20, 60);
      pdf.setFontSize(10);
      pdf.text(`User ID: ${this.currentUserId}`, 20, 68);
      pdf.text('CatchOPP Platform', 20, 75);
      
      // Subscription Details
      pdf.setFontSize(12);
      pdf.text('Subscription Details:', 20, 95);
      
      pdf.setFontSize(10);
      pdf.text(`Plan: ${this.subscription.plan?.name || 'N/A'}`, 20, 105);
      pdf.text(`Type: ${this.subscription.plan?.type || 'N/A'}`, 20, 112);
      pdf.text(`Duration: ${this.subscription.plan?.duration || 'N/A'}`, 20, 119);
      pdf.text(`Period: ${this.subscription.startDate?.slice(0, 10)} to ${this.subscription.endDate?.slice(0, 10)}`, 20, 126);
      
      // Payment Table
      pdf.setFontSize(12);
      pdf.text('Payment Summary:', 20, 145);
      
      // Table Header
      pdf.setFillColor(16, 185, 129);
      pdf.rect(20, 150, 170, 10, 'F');
      pdf.setTextColor(255);
      pdf.setFontSize(10);
      pdf.text('Description', 25, 157);
      pdf.text('Amount', 160, 157);
      
      // Table Row
      pdf.setTextColor(0);
      pdf.text(`${this.subscription.plan?.name} Subscription`, 25, 167);
      pdf.text(`$${payment.amount.toFixed(2)}`, 160, 167);
      
      // Total
      pdf.setDrawColor(229, 231, 235);
      pdf.line(20, 175, 190, 175);
      pdf.setFontSize(12);
      pdf.setFont('helvetica', 'bold');
      pdf.text('Total:', 130, 185);
      pdf.text(`$${payment.amount.toFixed(2)}`, 160, 185);
      
      // Generate QR Code
      const invoiceUrl = `https://catchopp.com/invoice/${payment.invoiceRef}`;
      const qrDataUrl = await QRCode.toDataURL(invoiceUrl, {
        width: 100,
        margin: 1,
        color: {
          dark: '#000000',
          light: '#ffffff'
        }
      });
      
      // Add QR Code
      pdf.addImage(qrDataUrl, 'PNG', 150, 200, 40, 40);
      pdf.setFontSize(8);
      pdf.setFont('helvetica', 'normal');
      pdf.text('Scan to verify', 158, 245);
      
      // Footer
      pdf.setFontSize(9);
      pdf.setTextColor(100);
      pdf.text('Thank you for your business!', 20, 260);
      pdf.text('CatchOPP - Connecting Freelancers Worldwide', 20, 267);
      pdf.text('support@catchopp.com | www.catchopp.com', 20, 274);
      
      // Save PDF
      pdf.save(`Invoice-${payment.invoiceRef}.pdf`);
      
    } catch (error) {
      console.error('Error generating invoice:', error);
      alert('Failed to generate invoice. Please try again.');
    }
  }
}
