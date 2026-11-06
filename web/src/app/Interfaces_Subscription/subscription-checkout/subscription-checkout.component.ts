import { Component, OnInit, AfterViewChecked, ChangeDetectorRef } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { SubscriptionService, SubscriptionPlan } from '../../services-ayoub/subscription.service';
import { PromoCodeService } from '../../services-ayoub/promo-code.service';
import { FlouciService } from '../../services-ayoub/flouci.service';
import { UserService } from '../../services-ayoub/user.service';

declare const paypal: any;

@Component({
  selector: 'app-subscription-checkout',
  templateUrl: './subscription-checkout.component.html',
  styleUrl: './subscription-checkout.component.css'
})
export class SubscriptionCheckoutComponent implements OnInit, AfterViewChecked {
  plan: SubscriptionPlan | null = null;
  paymentMethod: string = 'card';
  promoCode: string = '';
  agreeTerms: boolean = false;
  loading = true;
  submitting = false;
  errorMessage = '';

  cardNumber = '';
  cardExpiry = '';
  cardCvv = '';
  cardName = '';
  
  // Card validation errors
  cardNumberError = '';
  cardExpiryError = '';
  cardCvvError = '';
  cardNameError = '';
  
  // Promo code
  promoCodeApplied = false;
  promoCodeDiscount = 0;
  promoCodeError = '';
  promoCodeSuccess = '';

  /** PayPal Sandbox Client ID – Your CatchOPP credentials */
  paypalClientId = 'AauXbiepXCvfC78g_iwbKstLlbaHNuIDe9AyEco0MhVr2r3kqIkAbHa0labeXgyjQOPUxhF8ir3FkLee';
  
  /** 
   * OPTION 1: For one-time payments (like YouTube tutorials) - set this to null
   * OPTION 2: For recurring subscriptions - create a plan via API and use its ID (P-xxxx)
   */
  paypalPlanId: string | null = null; // Set to null for one-time payments
  
  // Use one-time payment mode (true) or subscription mode (false)
  useOneTimePayment = true;

  private paypalButtonRendered = false;
  private paypalScriptLoaded = false;

  currentUserId: number | null = null;
  currentUserEmail: string | null = null;
  subscriptionCount = 0;
  availableCodes: any[] = [];
  showAvailableCodes = false;
  
  // Flouci payment
  flouciProcessing = false;
  flouciPaymentId: string | null = null;
  
  // Valid promo codes (in production, fetch from backend)
  private validPromoCodes: { [key: string]: number } = {
    'WELCOME10': 10,
    'SAVE20': 20,
    'CATCHOPP25': 25,
    'FIRST50': 50
  };

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private subscriptionService: SubscriptionService,
    private promoCodeService: PromoCodeService,
    private flouciService: FlouciService,
    private userService: UserService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    // Get current logged-in user
    const currentUser = this.userService.getCurrentUser();
    if (currentUser?.id) {
      this.currentUserId = currentUser.id;
      
      // Fetch full user details to get email
      this.userService.getUserById(currentUser.id).subscribe(fullUser => {
        if (fullUser?.email) {
          this.currentUserEmail = fullUser.email;
          console.log('✅ User email loaded:', this.currentUserEmail);
        } else {
          // Fallback to JWT token email
          this.currentUserEmail = currentUser.email;
          console.log('✅ Using JWT email:', this.currentUserEmail);
        }
      });
      
      // Get user's subscription count
      this.subscriptionService.getAllSubscriptions().subscribe(subs => {
        this.subscriptionCount = (subs || []).filter(s => s.userId === this.currentUserId).length;
      });
    } else {
      this.loading = false;
      alert('Please login to subscribe');
      this.router.navigate(['/LoginFreelancer']);
      return;
    }
    
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.subscriptionService.getPlanById(+id).subscribe((p) => {
        this.plan = p || null;
        this.loading = false;
      });
    } else {
      this.loading = false;
    }
    
    // Load available promo codes
    this.loadAvailableCodes();
    
    // Check if user selected a code from rewards page
    const selectedCode = localStorage.getItem('selectedPromoCode');
    if (selectedCode) {
      this.promoCode = selectedCode;
      this.applyPromoCode();
      localStorage.removeItem('selectedPromoCode');
    }
    
    // Check for Flouci payment return
    this.route.queryParams.subscribe(params => {
      const paymentId = params['payment_id'];
      const status = params['status'];
      
      if (paymentId && status) {
        if (status === 'success') {
          this.verifyFlouciPayment(paymentId);
        } else {
          this.errorMessage = 'Flouci payment was cancelled or failed.';
        }
      }
    });
  }

  
  loadAvailableCodes(): void {
    if (!this.currentUserId) return;
    this.promoCodeService.getAvailableCodes(this.currentUserId).subscribe({
      next: (codes) => {
        this.availableCodes = codes;
      },
      error: () => {
        this.availableCodes = [];
      }
    });
  }

  toggleAvailableCodes(): void {
    this.showAvailableCodes = !this.showAvailableCodes;
  }

  selectCode(code: string): void {
    this.promoCode = code;
    this.showAvailableCodes = false;
    this.applyPromoCode();
  }

  ngAfterViewChecked(): void {
    if (this.paymentMethod === 'paypal' && this.plan && this.agreeTerms && !this.paypalButtonRendered && this.paypalClientId && this.paypalClientId !== 'YOUR_PAYPAL_CLIENT_ID') {
      this.maybeRenderPayPalButton();
    }
  }

  private loadPayPalScript(): Promise<void> {
    if (this.paypalScriptLoaded || (typeof paypal !== 'undefined' && paypal?.Buttons)) {
      return Promise.resolve();
    }
    return new Promise((resolve) => {
      if (document.getElementById('paypal-sdk-script')) {
        this.paypalScriptLoaded = true;
        resolve();
        return;
      }
      const script = document.createElement('script');
      script.id = 'paypal-sdk-script';
      
      // Choose script URL based on payment mode
      if (this.useOneTimePayment) {
        // One-time payment (like YouTube tutorials)
        script.src = `https://www.paypal.com/sdk/js?client-id=${this.paypalClientId}&currency=USD`;
      } else {
        // Subscription mode
        script.src = `https://www.paypal.com/sdk/js?client-id=${this.paypalClientId}&vault=true&intent=subscription`;
      }
      
      script.async = true;
      script.onload = () => {
        this.paypalScriptLoaded = true;
        resolve();
      };
      script.onerror = () => resolve();
      document.head.appendChild(script);
    });
  }

  private maybeRenderPayPalButton(): void {
    const container = document.getElementById('paypal-button-container');
    if (!container || container.innerHTML.trim() !== '') return;

    this.loadPayPalScript().then(() => {
      if (typeof paypal === 'undefined' || !paypal.Buttons) return;
      
      if (this.useOneTimePayment) {
        // ONE-TIME PAYMENT MODE (like YouTube tutorials)
        paypal.Buttons({
          createOrder: (_data: any, actions: any) => {
            return actions.order.create({
              purchase_units: [{
                amount: {
                  value: this.plan?.price?.toString() || '0.00',
                  currency_code: 'USD'
                },
                description: `${this.plan?.name} Plan - ${this.plan?.duration}`
              }]
            });
          },
          onApprove: (data: any, actions: any) => {
            return actions.order.capture().then((details: any) => {
              console.log('Payment completed:', details);
              this.onPayPalApprove();
            });
          },
          onError: (err: any) => {
            console.error('PayPal error:', err);
            this.errorMessage = 'PayPal payment failed. Please try again.';
            this.cdr.detectChanges();
          }
        }).render('#paypal-button-container');
        
      } else {
        // SUBSCRIPTION MODE (requires plan ID)
        if (!this.paypalPlanId || this.paypalPlanId === 'YOUR_PAYPAL_PLAN_ID') {
          container.innerHTML = '<p class="paypal-config-msg">Configure paypalPlanId in the component. Create a plan via PayPal API first.</p>';
          this.cdr.detectChanges();
          return;
        }
        paypal.Buttons({
          createSubscription: (_data: any, actions: any) => {
            return actions.subscription.create({ plan_id: this.paypalPlanId });
          },
          onApprove: (_data: any, _actions: any) => {
            this.onPayPalApprove();
          },
          onError: (err: any) => {
            console.error('PayPal subscription error:', err);
            this.errorMessage = 'PayPal subscription failed. Please try again.';
            this.cdr.detectChanges();
          }
        }).render('#paypal-button-container');
      }
      
      this.paypalButtonRendered = true;
      this.cdr.detectChanges();
    });
  }

  onPaymentMethodChange(): void {
    if (this.paymentMethod !== 'paypal') {
      this.paypalButtonRendered = false;
      const container = document.getElementById('paypal-button-container');
      if (container) container.innerHTML = '';
    }
  }
  
  // Card validation methods
  formatCardNumber(event: any): void {
    let value = event.target.value.replace(/\s/g, '');
    value = value.replace(/\D/g, '');
    value = value.substring(0, 16);
    
    const formatted = value.match(/.{1,4}/g)?.join(' ') || value;
    this.cardNumber = formatted;
    this.validateCardNumber();
  }
  
  validateCardNumber(): boolean {
    const cleaned = this.cardNumber.replace(/\s/g, '');
    
    if (!cleaned) {
      this.cardNumberError = 'Card number is required';
      return false;
    }
    
    if (cleaned.length < 13 || cleaned.length > 19) {
      this.cardNumberError = 'Invalid card number length';
      return false;
    }
    
    // Luhn algorithm
    if (!this.luhnCheck(cleaned)) {
      this.cardNumberError = 'Invalid card number';
      return false;
    }
    
    this.cardNumberError = '';
    return true;
  }
  
  private luhnCheck(cardNumber: string): boolean {
    let sum = 0;
    let isEven = false;
    
    for (let i = cardNumber.length - 1; i >= 0; i--) {
      let digit = parseInt(cardNumber[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    return sum % 10 === 0;
  }
  
  formatCardExpiry(event: any): void {
    let value = event.target.value.replace(/\D/g, '');
    
    if (value.length >= 2) {
      value = value.substring(0, 2) + '/' + value.substring(2, 4);
    }
    
    this.cardExpiry = value.substring(0, 5);
    this.validateCardExpiry();
  }
  
  validateCardExpiry(): boolean {
    if (!this.cardExpiry) {
      this.cardExpiryError = 'Expiry date is required';
      return false;
    }
    
    const parts = this.cardExpiry.split('/');
    if (parts.length !== 2) {
      this.cardExpiryError = 'Format: MM/YY';
      return false;
    }
    
    const month = parseInt(parts[0]);
    const year = parseInt('20' + parts[1]);
    
    if (month < 1 || month > 12) {
      this.cardExpiryError = 'Invalid month';
      return false;
    }
    
    const now = new Date();
    const expiry = new Date(year, month - 1);
    
    if (expiry < now) {
      this.cardExpiryError = 'Card has expired';
      return false;
    }
    
    this.cardExpiryError = '';
    return true;
  }
  
  formatCardCvv(event: any): void {
    let value = event.target.value.replace(/\D/g, '');
    this.cardCvv = value.substring(0, 4);
    this.validateCardCvv();
  }
  
  validateCardCvv(): boolean {
    if (!this.cardCvv) {
      this.cardCvvError = 'CVV is required';
      return false;
    }
    
    if (this.cardCvv.length < 3 || this.cardCvv.length > 4) {
      this.cardCvvError = 'CVV must be 3-4 digits';
      return false;
    }
    
    this.cardCvvError = '';
    return true;
  }
  
  validateCardName(): boolean {
    if (!this.cardName || this.cardName.trim().length < 3) {
      this.cardNameError = 'Cardholder name is required';
      return false;
    }
    
    this.cardNameError = '';
    return true;
  }
  
  // Promo code methods
  applyPromoCode(): void {
    this.promoCodeError = '';
    this.promoCodeSuccess = '';
    
    if (!this.promoCode || !this.promoCode.trim()) {
      this.promoCodeError = 'Please enter a promo code';
      return;
    }
    
    if (!this.currentUserId) {
      this.promoCodeError = 'Please login to use promo codes';
      return;
    }
    
    const code = this.promoCode.trim().toUpperCase();
    
    // Validate with backend
    this.promoCodeService.validateCode(code, this.currentUserId, this.subscriptionCount).subscribe({
      next: (response) => {
        if (response.valid && this.plan) {
          // Calculate discount
          this.promoCodeService.calculateDiscount(code, this.plan.price || 0).subscribe({
            next: (discountResponse) => {
              this.promoCodeApplied = true;
              this.promoCodeDiscount = discountResponse.discountPercentage;
              this.promoCodeSuccess = `Promo code applied! ${this.promoCodeDiscount.toFixed(0)}% discount`;
            },
            error: () => {
              this.promoCodeError = 'Failed to calculate discount';
            }
          });
        } else {
          this.promoCodeError = response.message || 'Invalid promo code';
          this.promoCodeApplied = false;
          this.promoCodeDiscount = 0;
        }
      },
      error: (err) => {
        this.promoCodeError = err.error?.message || 'Invalid or expired promo code';
        this.promoCodeApplied = false;
        this.promoCodeDiscount = 0;
      }
    });
  }
  
  removePromoCode(): void {
    this.promoCodeApplied = false;
    this.promoCodeDiscount = 0;
    this.promoCode = '';
    this.promoCodeSuccess = '';
    this.promoCodeError = '';
  }
  
  getFinalPrice(): number {
    if (!this.plan) return 0;
    const basePrice = this.plan.price || 0;
    if (this.promoCodeApplied && this.promoCodeDiscount > 0) {
      return basePrice * (1 - this.promoCodeDiscount / 100);
    }
    return basePrice;
  }
  
  getDiscountAmount(): number {
    if (!this.plan) return 0;
    const basePrice = this.plan.price || 0;
    return basePrice - this.getFinalPrice();
  }

  onSubmit(): void {
      if (!this.plan?.id || !this.agreeTerms) {
        if (!this.agreeTerms) this.errorMessage = 'Please accept the terms and conditions.';
        return;
      }

      if (!this.currentUserId) {
        this.errorMessage = 'Please login to subscribe';
        return;
      }

      // Validate card details if card payment
      if (this.paymentMethod === 'card') {
        const cardValid = this.validateCardNumber();
        const expiryValid = this.validateCardExpiry();
        const cvvValid = this.validateCardCvv();
        const nameValid = this.validateCardName();

        if (!cardValid || !expiryValid || !cvvValid || !nameValid) {
          this.errorMessage = 'Please fix card validation errors';
          return;
        }
      }

      this.errorMessage = '';
      this.submitting = true;

      // Check if user already has an active subscription
      this.subscriptionService.getActiveSubscription(this.currentUserId!).subscribe({
        next: (existingSub) => {
          if (existingSub && existingSub.id) {
            // User already has active subscription - just record payment
            console.log('✅ User has existing subscription:', existingSub.id);
            const amount = this.getFinalPrice();
            this.subscriptionService.recordPayment(existingSub.id, amount, this.paymentMethod).subscribe({
              next: (payment) => {
                this.submitting = false;
                if (payment == null) {
                  this.errorMessage = 'Payment could not be recorded. Contact support.';
                  return;
                }
                this.router.navigate(['/SubscriptionDashboard']);
                const savedAmount = this.getDiscountAmount();
                const message = savedAmount > 0 
                  ? `Payment successful! You saved ${savedAmount.toFixed(2)} with promo code.`
                  : 'Payment successful! Your subscription has been renewed.';
                alert(message);
              },
              error: () => {
                this.submitting = false;
                this.errorMessage = 'Payment recording failed.';
              }
            });
          } else {
            // No active subscription - create new one
            console.log('📝 Creating new subscription for user:', this.currentUserId);
            console.log('📧 User email:', this.currentUserEmail);
            this.subscriptionService.subscribe(this.currentUserId!, this.plan!.id!, this.currentUserEmail || undefined).subscribe({
              next: (sub) => {
                if (!sub || sub.id == null) {
                  this.submitting = false;
                  this.errorMessage = 'Could not create subscription. Is SubscriptionMicroService running on port 8083?';
                  return;
                }
                const amount = this.getFinalPrice();
                this.subscriptionService.recordPayment(sub.id, amount, this.paymentMethod).subscribe({
                  next: (payment) => {
                    this.submitting = false;
                    if (payment == null) {
                      this.errorMessage = 'Payment could not be recorded. Subscription was created but payment failed. Contact support.';
                      return;
                    }
                    this.router.navigate(['/SubscriptionDashboard']);
                    const savedAmount = this.getDiscountAmount();
                    const message = savedAmount > 0 
                      ? `Subscription successful! You saved ${savedAmount.toFixed(2)} with promo code.`
                      : 'Subscription successful! You now have access to ' + this.plan!.name + '.';
                    alert(message);
                  },
                  error: () => {
                    this.submitting = false;
                    this.errorMessage = 'Payment recording failed.';
                  }
                });
              },
              error: () => {
                this.submitting = false;
                this.errorMessage = 'Subscription failed. Check that SubscriptionMicroService is running on port 8083.';
              }
            });
          }
        },
        error: () => {
          this.submitting = false;
          this.errorMessage = 'Could not check existing subscription.';
        }
      });
    }

  onPayPalApprove(): void {
      if (!this.plan?.id || !this.agreeTerms) {
        this.errorMessage = 'Please accept the terms and conditions first.';
        return;
      }

      if (!this.currentUserId) {
        this.errorMessage = 'Please login to subscribe';
        return;
      }

      this.errorMessage = '';
      this.submitting = true;

      // Check if user already has an active subscription
      this.subscriptionService.getActiveSubscription(this.currentUserId!).subscribe({
        next: (existingSub) => {
          if (existingSub && existingSub.id) {
            // User already has active subscription - just record payment
            console.log('✅ PayPal: User has existing subscription:', existingSub.id);
            this.subscriptionService.recordPayment(existingSub.id, this.plan!.price ?? 0, 'paypal').subscribe({
              next: (payment) => {
                this.submitting = false;
                if (payment == null) {
                  this.errorMessage = 'Payment could not be recorded. Contact support.';
                  return;
                }
                this.router.navigate(['/SubscriptionDashboard']);
                alert('Payment successful via PayPal! Your subscription has been renewed.');
              },
              error: () => {
                this.submitting = false;
                this.errorMessage = 'Payment recording failed.';
              }
            });
          } else {
            // No active subscription - create new one
            console.log('📝 PayPal: Creating new subscription for user:', this.currentUserId);
            this.subscriptionService.subscribe(this.currentUserId!, this.plan!.id!, this.currentUserEmail || undefined).subscribe({
              next: (sub) => {
                if (!sub || sub.id == null) {
                  this.submitting = false;
                  this.errorMessage = 'Could not create subscription.';
                  return;
                }
                this.subscriptionService.recordPayment(sub.id, this.plan!.price ?? 0, 'paypal').subscribe({
                  next: (payment) => {
                    this.submitting = false;
                    if (payment == null) {
                      this.errorMessage = 'Payment could not be recorded. Subscription was created but payment failed.';
                      return;
                    }
                    this.router.navigate(['/SubscriptionDashboard']);
                    alert('Subscription successful! Payment via PayPal.');
                  },
                  error: () => {
                    this.submitting = false;
                    this.errorMessage = 'Payment recording failed.';
                  }
                });
              },
              error: () => {
                this.submitting = false;
                this.errorMessage = 'Subscription failed.';
              }
            });
          }
        },
        error: () => {
          this.submitting = false;
          this.errorMessage = 'Could not check existing subscription.';
        }
      });
    }

  // Flouci Payment Methods
  verifyFlouciPayment(paymentId: string): void {
    this.submitting = true;
    this.flouciService.verifyPayment(paymentId).subscribe({
      next: (response) => {
        if (response.success && response.result.status === 'SUCCESS') {
          // Payment verified, create subscription
          this.completeFlouciSubscription(response.result.amount / 1000); // Convert millimes to TND
        } else {
          this.submitting = false;
          this.errorMessage = 'Payment verification failed. Please contact support.';
        }
      },
      error: () => {
        this.submitting = false;
        this.errorMessage = 'Could not verify payment. Please contact support.';
      }
    });
  }

  completeFlouciSubscription(amount: number): void {
      if (!this.plan?.id) {
        this.submitting = false;
        return;
      }

      if (!this.currentUserId) {
        this.submitting = false;
        this.errorMessage = 'Please login to subscribe';
        return;
      }

      // Check if user already has an active subscription
      this.subscriptionService.getActiveSubscription(this.currentUserId!).subscribe({
        next: (existingSub) => {
          if (existingSub && existingSub.id) {
            // User already has active subscription - just record payment
            console.log('✅ Flouci: User has existing subscription:', existingSub.id);
            this.subscriptionService.recordPayment(existingSub.id, amount, 'flouci').subscribe({
              next: (payment) => {
                this.submitting = false;
                if (payment == null) {
                  this.errorMessage = 'Payment could not be recorded.';
                  return;
                }
                this.router.navigate(['/SubscriptionDashboard']);
                alert('Payment successful via Flouci! Your subscription has been renewed.');
              },
              error: () => {
                this.submitting = false;
                this.errorMessage = 'Payment recording failed.';
              }
            });
          } else {
            // No active subscription - create new one
            console.log('📝 Flouci: Creating new subscription for user:', this.currentUserId);
            this.subscriptionService.subscribe(this.currentUserId!, this.plan!.id!, this.currentUserEmail || undefined).subscribe({
              next: (sub) => {
                if (!sub || sub.id == null) {
                  this.submitting = false;
                  this.errorMessage = 'Could not create subscription.';
                  return;
                }

                this.subscriptionService.recordPayment(sub.id, amount, 'flouci').subscribe({
                  next: (payment) => {
                    this.submitting = false;
                    if (payment == null) {
                      this.errorMessage = 'Payment could not be recorded.';
                      return;
                    }
                    this.router.navigate(['/SubscriptionDashboard']);
                    alert('Subscription successful! Payment via Flouci.');
                  },
                  error: () => {
                    this.submitting = false;
                    this.errorMessage = 'Payment recording failed.';
                  }
                });
              },
              error: () => {
                this.submitting = false;
                this.errorMessage = 'Subscription failed.';
              }
            });
          }
        },
        error: () => {
          this.submitting = false;
          this.errorMessage = 'Could not check existing subscription.';
        }
      });
    }

  onFlouciPayment(): void {
    if (!this.plan?.id || !this.agreeTerms) {
      if (!this.agreeTerms) this.errorMessage = 'Please accept the terms and conditions.';
      return;
    }

    this.errorMessage = '';
    this.flouciProcessing = true;

    const amount = this.getFinalPrice();
    const amountTND = this.flouciService.convertUsdToTnd(amount);

    const currentUrl = window.location.origin + window.location.pathname;
    const successUrl = `${currentUrl}?payment_id={payment_id}&status=success`;
    const failUrl = `${currentUrl}?payment_id={payment_id}&status=failed`;

    this.flouciService.initiatePayment({
      amount: amountTND,
      description: `${this.plan.name} Subscription - ${this.plan.duration}`,
      successUrl: successUrl,
      failUrl: failUrl,
      developerTrackingId: `SUB_${this.currentUserId}_${this.plan.id}_${Date.now()}`
    }).subscribe({
      next: (response) => {
        this.flouciProcessing = false;
        if (response.success && response.result.link) {
          this.flouciPaymentId = response.result.payment_id;
          // Redirect to Flouci payment page
          this.flouciService.redirectToPayment(response.result.link);
        } else {
          this.errorMessage = 'Could not initiate Flouci payment. Please try again.';
        }
      },
      error: (err) => {
        this.flouciProcessing = false;
        this.errorMessage = err.error?.message || 'Flouci payment initialization failed.';
      }
    });
  }

  getFlouciAmountTND(): string {
    const usdAmount = this.getFinalPrice();
    const tndAmount = this.flouciService.convertUsdToTnd(usdAmount);
    return this.flouciService.formatAmount(tndAmount);
  }
}
