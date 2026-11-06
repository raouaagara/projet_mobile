import { Component, OnInit } from '@angular/core';
import { PromoCodeService } from '../../services-ayoub/promo-code.service';
import { Router } from '@angular/router';
import { UserService } from '../../services-ayoub/user.service';

@Component({
  selector: 'app-spin-wheel',
  templateUrl: './spin-wheel.component.html',
  styleUrls: ['./spin-wheel.component.css']
})
export class SpinWheelComponent implements OnInit {
  currentUserId: number = 0;
  canSpin = false;
  daysUntilNextSpin = 0;
  spinning = false;
  wonDiscount = 0;
  wonCode = '';
  showResult = false;
  rotation = 0;

  // Wheel segments (5%, 10%, 15%, 20%, 25%)
  segments = [
    { discount: 5, color: '#fbbf24', angle: 0 },
    { discount: 25, color: '#10b981', angle: 72 },
    { discount: 10, color: '#3b82f6', angle: 144 },
    { discount: 20, color: '#8b5cf6', angle: 216 },
    { discount: 15, color: '#ef4444', angle: 288 }
  ];

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
      this.checkSpinEligibility();
    } else {
      console.error('No user logged in');
    }
  }

  checkSpinEligibility(): void {
    this.promoCodeService.canUserSpin(this.currentUserId).subscribe({
      next: (response) => {
        this.canSpin = response.canSpin;
        this.daysUntilNextSpin = response.daysUntilNextSpin || 0;
      },
      error: () => {
        this.canSpin = false;
      }
    });
  }

  spin(): void {
    if (!this.canSpin || this.spinning) return;

    this.spinning = true;
    this.showResult = false;

    this.promoCodeService.spinWheel(this.currentUserId).subscribe({
      next: (response) => {
        if (response.success) {
          this.wonDiscount = response.discountWon;
          this.wonCode = response.promoCode.code;
          
          // Calculate rotation to land on won segment
          const wonSegment = this.segments.find(s => s.discount === this.wonDiscount);
          const targetAngle = wonSegment ? wonSegment.angle : 0;
          
          // Spin multiple times + target angle
          this.rotation = 360 * 5 + (360 - targetAngle);
          
          // Show result after animation
          setTimeout(() => {
            this.spinning = false;
            this.showResult = true;
            this.triggerConfetti();
            this.canSpin = false;
          }, 4000);
        }
      },
      error: (err) => {
        this.spinning = false;
        alert(err.error?.message || 'Failed to spin. Please try again.');
      }
    });
  }

  triggerConfetti(): void {
    // Simple confetti effect using DOM manipulation
    const colors = ['#10b981', '#3b82f6', '#fbbf24', '#ef4444', '#8b5cf6'];
    const confettiCount = 50;

    for (let i = 0; i < confettiCount; i++) {
      setTimeout(() => {
        const confetti = document.createElement('div');
        confetti.className = 'confetti';
        confetti.style.left = Math.random() * 100 + '%';
        confetti.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
        confetti.style.animationDelay = Math.random() * 0.5 + 's';
        document.body.appendChild(confetti);

        setTimeout(() => confetti.remove(), 3000);
      }, i * 30);
    }
  }

  goToRewards(): void {
    this.router.navigate(['/rewards']);
  }

  goToCheckout(): void {
    localStorage.setItem('selectedPromoCode', this.wonCode);
    this.router.navigate(['/SubscriptionPlans']);
  }
}
