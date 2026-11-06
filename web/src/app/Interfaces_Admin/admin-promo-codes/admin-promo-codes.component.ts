import { Component, OnInit } from '@angular/core';
import { PromoCodeService, PromoCode } from '../../services-ayoub/promo-code.service';

@Component({
  selector: 'app-admin-promo-codes',
  templateUrl: './admin-promo-codes.component.html',
  styleUrl: './admin-promo-codes.component.css'
})
export class AdminPromoCodesComponent implements OnInit {
  showForm = false;
  promos: PromoCode[] = [];
  loading = false;
  error = '';

  // Form fields
  newCode = '';
  newDiscountValue = 10;
  newDiscountType: 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_MONTH' = 'PERCENTAGE';
  newType: PromoCode['type'] = 'SPECIAL';
  newExpiresAt = '';
  newDescription = '';
  newUserId = 0; // Admin can assign to specific user or 0 for general

  constructor(private promoCodeService: PromoCodeService) {}

  ngOnInit(): void {
    this.loadPromoCodes();
    // Set default expiry date to 30 days from now
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 30);
    this.newExpiresAt = futureDate.toISOString().split('T')[0];
  }

  loadPromoCodes(): void {
    this.loading = true;
    this.error = '';
    console.log('Loading promo codes from database...');
    
    this.promoCodeService.getAllPromoCodes().subscribe({
      next: (codes) => {
        this.promos = codes;
        console.log('Loaded promo codes:', codes);
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading promo codes:', err);
        this.error = 'Failed to load promo codes';
        this.loading = false;
      }
    });
  }

  addPromo(): void {
    if (!this.newCode.trim()) {
      alert('Please enter a promo code');
      return;
    }

    // Convert date string to ISO datetime format
    const expiresAtDate = new Date(this.newExpiresAt);
    expiresAtDate.setHours(23, 59, 59); // Set to end of day
    const expiresAtISO = expiresAtDate.toISOString();

    const newPromoCode: Partial<PromoCode> = {
      code: this.newCode.toUpperCase(),
      type: this.newType,
      discountType: this.newDiscountType,
      discountValue: this.newDiscountValue,
      userId: this.newUserId,
      expiresAt: expiresAtISO,
      description: this.newDescription || `${this.newDiscountValue}${this.newDiscountType === 'PERCENTAGE' ? '%' : ' TND'} discount`,
      isActive: true,
      minSubscriptionCount: 1
    };

    console.log('Creating promo code:', newPromoCode);

    this.promoCodeService.createPromoCode(newPromoCode).subscribe({
      next: (created) => {
        console.log('Promo code created:', created);
        this.promos.unshift(created);
        this.resetForm();
        this.showForm = false;
        alert('Promo code created successfully!');
      },
      error: (err) => {
        console.error('Error creating promo code:', err);
        alert('Failed to create promo code: ' + (err.error?.message || err.message));
      }
    });
  }

  toggleActive(promo: PromoCode): void {
    console.log('Toggling promo code status:', promo.id);
    
    this.promoCodeService.togglePromoCodeStatus(promo.id).subscribe({
      next: (updated) => {
        console.log('Promo code status updated:', updated);
        promo.isActive = updated.isActive;
        alert(`Promo code ${updated.isActive ? 'activated' : 'deactivated'} successfully!`);
      },
      error: (err) => {
        console.error('Error toggling promo code:', err);
        alert('Failed to toggle promo code status');
      }
    });
  }

  deletePromo(promo: PromoCode): void {
    if (!confirm(`Are you sure you want to delete promo code "${promo.code}"?`)) {
      return;
    }

    console.log('Deleting promo code:', promo.id);

    this.promoCodeService.deletePromoCode(promo.id).subscribe({
      next: () => {
        console.log('Promo code deleted successfully');
        this.promos = this.promos.filter(p => p.id !== promo.id);
        alert('Promo code deleted successfully!');
      },
      error: (err) => {
        console.error('Error deleting promo code:', err);
        alert('Failed to delete promo code');
      }
    });
  }

  resetForm(): void {
    this.newCode = '';
    this.newDiscountValue = 10;
    this.newDiscountType = 'PERCENTAGE';
    this.newType = 'SPECIAL';
    this.newDescription = '';
    this.newUserId = 0;
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 30);
    this.newExpiresAt = futureDate.toISOString().split('T')[0];
  }

  formatDate(dateString: string): string {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString();
  }

  getDiscountDisplay(promo: PromoCode): string {
    switch (promo.discountType) {
      case 'PERCENTAGE':
        return `${promo.discountValue}%`;
      case 'FIXED_AMOUNT':
        return `${promo.discountValue} TND`;
      case 'FREE_MONTH':
        return 'Free Month';
      default:
        return `${promo.discountValue}`;
    }
  }

  isExpired(promo: PromoCode): boolean {
    return new Date(promo.expiresAt) < new Date();
  }

  isUsed(promo: PromoCode): boolean {
    return promo.usedAt !== null;
  }
}
