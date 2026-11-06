import { Component, OnInit, Inject } from '@angular/core';
import { ReferralService, Referral, ReferralReward } from '../../services-ayoub/referral.service';
import { DonationService, UserWallet, RewardTransaction, Donation, WalletStats } from '../../services-ayoub/donation.service';
import { UserService } from '../../services-ayoub/user.service';

@Component({
  selector: 'app-referral-dashboard',
  templateUrl: './referral-dashboard.component.html',
  styleUrl: './referral-dashboard.component.css'
})
export class ReferralDashboardComponent implements OnInit {
  // User ID - Get from JWT token
  userId: number = 0;

  // Active Tab
  activeTab: 'overview' | 'referrals' | 'rewards' | 'donations' | 'wallet' | 'leaderboards' = 'overview';

  // Referral Data
  referralCode = '';
  referralUrl = '';
  referrals: Referral[] = [];
  rewards: ReferralReward[] = [];
  
  // Referral Statistics
  totalReferrals = 0;
  qualifiedReferrals = 0;
  pendingReferrals = 0;
  totalEarned = 0;
  pendingEarnings = 0;

  // Wallet & Rewards Data
  wallet: UserWallet | null = null;
  walletStats: WalletStats | null = null;
  transactions: RewardTransaction[] = [];
  donationsSent: Donation[] = [];
  donationsReceived: Donation[] = [];
  topEarners: UserWallet[] = [];
  topDonors: UserWallet[] = [];
  topLearners: UserWallet[] = [];

  // Donation Form
  donationRecipientId: number | null = null;
  donationAmount: number = 10;
  donationMessage: string = '';
  donationAnonymous: boolean = false;
  donationSearchQuery: string = '';

  // UI State
  loading = true;
  copySuccess = false;
  showHowItWorks = false;
  donationLoading = false;
  donationSuccess = false;
  donationError = '';

  // Constants
  REWARD_PER_REFERRAL = 10.00;

  constructor(
    private referralService: ReferralService,
    private donationService: DonationService,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    // Get user ID from JWT token
    const currentUser = this.userService.getCurrentUser();
    if (currentUser && currentUser.id) {
      this.userId = currentUser.id;
      this.loadReferralData();
      this.loadWalletData();
      this.loadDonationData();
      this.loadLeaderboards();
    } else {
      console.error('No user logged in');
    }
  }

  loadReferralData(): void {
    this.loading = true;

    // Get referral code
    this.referralService.getReferralCode(this.userId).subscribe({
      next: (code) => {
        this.referralCode = code;
        this.referralUrl = this.referralService.generateReferralUrl(code);
      },
      error: () => {
        this.referralCode = 'ERROR';
      }
    });

    // Get referrals
    this.referralService.getUserReferrals(this.userId).subscribe({
      next: (referrals) => {
        this.referrals = referrals;
        this.calculateStatistics();
        this.loading = false;
      },
      error: () => {
        this.loading = false;
      }
    });

    // Get total earned
    this.referralService.getTotalEarned(this.userId).subscribe({
      next: (earned) => {
        this.totalEarned = earned;
      }
    });
  }

  loadWalletData(): void {
    // Get wallet
    this.donationService.getWallet(this.userId).subscribe({
      next: (wallet) => {
        this.wallet = wallet;
      },
      error: () => {
        console.log('Wallet not found, will be created on first reward');
      }
    });

    // Get wallet stats
    this.donationService.getWalletStats(this.userId).subscribe({
      next: (stats) => {
        this.walletStats = stats;
      },
      error: () => {
        console.log('Wallet stats not available');
      }
    });

    // Get transaction history
    this.donationService.getTransactionHistory(this.userId).subscribe({
      next: (transactions) => {
        this.transactions = transactions;
      }
    });
  }

  loadDonationData(): void {
    // Get donations sent
    this.donationService.getDonationsSent(this.userId).subscribe({
      next: (donations) => {
        this.donationsSent = donations;
      }
    });

    // Get donations received
    this.donationService.getDonationsReceived(this.userId).subscribe({
      next: (donations) => {
        this.donationsReceived = donations;
      }
    });
  }

  loadLeaderboards(): void {
    this.donationService.getTopEarners().subscribe({
      next: (earners) => {
        this.topEarners = earners;
      }
    });

    this.donationService.getTopDonors().subscribe({
      next: (donors) => {
        this.topDonors = donors;
      }
    });

    this.donationService.getTopLearners().subscribe({
      next: (learners) => {
        this.topLearners = learners;
      }
    });
  }

  calculateStatistics(): void {
    this.totalReferrals = this.referrals.length;
    this.qualifiedReferrals = this.referrals.filter(r => r.status === 'QUALIFIED' || r.status === 'REWARDED').length;
    this.pendingReferrals = this.referrals.filter(r => r.status === 'SIGNED_UP').length;
    this.pendingEarnings = this.pendingReferrals * this.REWARD_PER_REFERRAL;
  }

  copyLink(): void {
    navigator.clipboard.writeText(this.referralUrl).then(() => {
      this.copySuccess = true;
      setTimeout(() => {
        this.copySuccess = false;
      }, 2000);
    });
  }

  shareOnTwitter(): void {
    const url = this.referralService.getTwitterShareUrl(this.referralUrl);
    window.open(url, '_blank', 'width=600,height=400');
  }

  shareOnLinkedIn(): void {
    const url = this.referralService.getLinkedInShareUrl(this.referralUrl);
    window.open(url, '_blank', 'width=600,height=600');
  }

  shareOnFacebook(): void {
    const url = this.referralService.getFacebookShareUrl(this.referralUrl);
    window.open(url, '_blank', 'width=600,height=400');
  }

  shareOnWhatsApp(): void {
    const url = this.referralService.getWhatsAppShareUrl(this.referralUrl);
    window.open(url, '_blank');
  }

  shareViaEmail(): void {
    const url = this.referralService.getEmailShareUrl(this.referralUrl);
    window.location.href = url;
  }

  getStatusBadgeClass(status: string): string {
    switch (status) {
      case 'QUALIFIED':
      case 'REWARDED':
        return 'qualified';
      case 'SIGNED_UP':
        return 'pending';
      default:
        return '';
    }
  }

  getStatusLabel(status: string): string {
    switch (status) {
      case 'QUALIFIED':
        return 'Qualified ✓';
      case 'REWARDED':
        return 'Rewarded ✓';
      case 'SIGNED_UP':
        return 'Pending...';
      default:
        return status;
    }
  }

  getEarnings(referral: Referral): number {
    if (referral.status === 'QUALIFIED' || referral.status === 'REWARDED') {
      return this.REWARD_PER_REFERRAL;
    }
    return 0;
  }

  toggleHowItWorks(): void {
    this.showHowItWorks = !this.showHowItWorks;
  }

  // Tab Navigation
  switchTab(tab: 'overview' | 'referrals' | 'rewards' | 'donations' | 'wallet' | 'leaderboards'): void {
    this.activeTab = tab;
  }

  // Donation Methods
  sendDonation(): void {
    if (!this.donationRecipientId || this.donationAmount <= 0) {
      this.donationError = 'Please enter valid recipient ID and amount';
      return;
    }

    this.donationLoading = true;
    this.donationError = '';
    this.donationSuccess = false;

    this.donationService.sendDonation(
      this.userId,
      this.donationRecipientId,
      this.donationAmount,
      this.donationMessage,
      this.donationAnonymous
    ).subscribe({
      next: (response) => {
        if (response.success) {
          this.donationSuccess = true;
          this.donationLoading = false;
          
          // Reset form
          this.donationRecipientId = null;
          this.donationAmount = 10;
          this.donationMessage = '';
          this.donationAnonymous = false;
          
          // Reload data
          this.loadWalletData();
          this.loadDonationData();
          
          // Hide success message after 3 seconds
          setTimeout(() => {
            this.donationSuccess = false;
          }, 3000);
        }
      },
      error: (err) => {
        this.donationError = err.error?.error || 'Failed to send donation';
        this.donationLoading = false;
      }
    });
  }

  sendThankYou(donationId: number): void {
    this.donationService.sendThankYou(donationId).subscribe({
      next: () => {
        this.loadDonationData();
        alert('Thank you sent!');
      },
      error: () => {
        alert('Failed to send thank you');
      }
    });
  }

  // Helper Methods
  getTierBadge(tier: string): string {
    const badges: { [key: string]: string } = {
      'NONE': '',
      'BRONZE': '🥉',
      'SILVER': '🥈',
      'GOLD': '🥇',
      'PLATINUM': '💎',
      'DIAMOND': '💠'
    };
    return badges[tier] || '';
  }

  getTierLabel(tier: string): string {
    return tier.charAt(0) + tier.slice(1).toLowerCase();
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    });
  }

  formatDateTime(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  getProgressPercentage(): number {
    if (!this.walletStats) return 0;
    const current = this.walletStats.certificationsCount;
    const toNext = this.walletStats.certificationsToNextTier;
    if (toNext === 0) return 100;
    
    // Calculate based on tier thresholds
    let previousThreshold = 0;
    let nextThreshold = 10;
    
    if (current >= 100) return 100;
    if (current >= 50) { previousThreshold = 50; nextThreshold = 100; }
    else if (current >= 30) { previousThreshold = 30; nextThreshold = 50; }
    else if (current >= 20) { previousThreshold = 20; nextThreshold = 30; }
    else if (current >= 10) { previousThreshold = 10; nextThreshold = 20; }
    
    const progress = ((current - previousThreshold) / (nextThreshold - previousThreshold)) * 100;
    return Math.min(100, Math.max(0, progress));
  }

  goToPromoCodes(): void {
    window.location.href = '/rewards';
  }
}

