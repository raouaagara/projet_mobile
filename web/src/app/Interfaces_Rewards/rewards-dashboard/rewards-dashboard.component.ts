import { Component, OnInit } from '@angular/core';
import { PromoCodeService, PromoCode, UserReward } from '../../services-ayoub/promo-code.service';
import { Router } from '@angular/router';
import { UserService } from '../../services-ayoub/user.service';

@Component({
  selector: 'app-rewards-dashboard',
  templateUrl: './rewards-dashboard.component.html',
  styleUrls: ['./rewards-dashboard.component.css']
})
export class RewardsDashboardComponent implements OnInit {
  currentUserId: number = 0;
  availableCodes: PromoCode[] = [];
  allCodes: PromoCode[] = [];
  rewards: UserReward[] = [];
  loading = true;
  selectedTab: 'available' | 'all' | 'history' = 'available';
  
  // Stats
  totalEarned = 0;
  totalUsed = 0;
  totalExpired = 0;
  totalSavings = 0;

  constructor(
    private promoCodeService: PromoCodeService,
    private router: Router,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    // Get user ID from JWT token
    const currentUser = this.userService.getCurrentUser();
    if (currentUser && currentUser.id) {
      this.currentUserId = currentUser.id;
      this.loadData();
      this.checkForNewRewards();
    } else {
      console.error('No user logged in');
      this.loading = false;
    }
  }

  loadData(): void {
    this.loading = true;
    
    // Load available codes
    this.promoCodeService.getAvailableCodes(this.currentUserId).subscribe({
      next: (codes) => {
        this.availableCodes = codes;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
      }
    });

    // Load all codes
    this.promoCodeService.getUserPromoCodes(this.currentUserId).subscribe({
      next: (codes) => {
        this.allCodes = codes;
        this.calculateStats();
      }
    });

    // Load rewards history
    this.promoCodeService.getUserRewards(this.currentUserId).subscribe({
      next: (rewards) => {
        this.rewards = rewards;
      }
    });
  }

  checkForNewRewards(): void {
    this.promoCodeService.getPendingPopups(this.currentUserId).subscribe({
      next: (popups) => {
        if (popups && popups.length > 0) {
          // Show popup for first pending reward
          this.showRewardPopup(popups[0]);
        }
      }
    });
  }

  showRewardPopup(reward: UserReward): void {
    // Navigate to popup or show modal
    // For now, we'll handle this in a separate component
    this.router.navigate(['/rewards/popup', reward.id]);
  }

  calculateStats(): void {
    this.totalEarned = this.allCodes.length;
    this.totalUsed = this.allCodes.filter(c => c.usedAt !== null).length;
    this.totalExpired = this.allCodes.filter(c => 
      !c.isActive || (new Date(c.expiresAt) < new Date() && c.usedAt === null)
    ).length;
    
    // Calculate total savings from used codes
    this.totalSavings = this.allCodes
      .filter(c => c.usedAt !== null)
      .reduce((sum, c) => sum + c.discountValue, 0);
  }

  getDaysUntilExpiry(code: PromoCode): number {
    const now = new Date();
    const expiry = new Date(code.expiresAt);
    const diff = expiry.getTime() - now.getTime();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  }

  isExpiringSoon(code: PromoCode): boolean {
    return this.getDaysUntilExpiry(code) <= 7;
  }

  isExpired(code: PromoCode): boolean {
    return new Date(code.expiresAt) < new Date();
  }

  copyCode(code: string): void {
    navigator.clipboard.writeText(code).then(() => {
      alert('Code copied to clipboard!');
    });
  }

  goToCheckout(code: PromoCode): void {
    // Store selected code and navigate to subscription plans
    localStorage.setItem('selectedPromoCode', code.code);
    this.router.navigate(['/SubscriptionPlans']);
  }

  getCodeTypeLabel(type: string): string {
    const labels: { [key: string]: string } = {
      'LOYALTY': 'Loyalty Reward',
      'REFERRAL': 'Referral Bonus',
      'ACHIEVEMENT': 'Achievement',
      'SPECIAL': 'Special Offer'
    };
    return labels[type] || type;
  }

  getCodeTypeIcon(type: string): string {
    const icons: { [key: string]: string } = {
      'LOYALTY': '🏆',
      'REFERRAL': '🤝',
      'ACHIEVEMENT': '⭐',
      'SPECIAL': '🎁'
    };
    return icons[type] || '🎫';
  }

  getDiscountLabel(code: PromoCode): string {
    if (code.discountType === 'PERCENTAGE') {
      return `${code.discountValue}% OFF`;
    } else if (code.discountType === 'FREE_MONTH') {
      return '1 MONTH FREE';
    } else {
      return `$${code.discountValue} OFF`;
    }
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    });
  }

  goToSpinWheel(): void {
    this.router.navigate(['/rewards/spin-wheel']);
  }

  goToCommunity(): void {
    this.router.navigate(['/ReferralDashboard']);
  }
}
