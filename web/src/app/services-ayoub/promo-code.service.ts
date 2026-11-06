import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface PromoCode {
  id: number;
  code: string;
  type: 'LOYALTY_3MONTH' | 'LOYALTY_6MONTH' | 'ANNUAL_UPGRADE' | 'REFERRAL_5' | 'CERTIFICATION' | 'TOP10_LEADERBOARD' | 'MONTHLY_CHALLENGE' | 'STUDENT' | 'SPIN_WHEEL' | 'SPECIAL';
  discountType: 'PERCENTAGE' | 'FIXED_AMOUNT' | 'FREE_MONTH';
  discountValue: number;
  userId: number;
  earnedAt: string;
  expiresAt: string;
  usedAt: string | null;
  usedInSubscriptionId: number | null;
  isActive: boolean;
  minSubscriptionCount: number;
  description?: string;
}

export interface UserReward {
  id: number;
  userId: number;
  rewardType: string;
  earnedAt: string;
  notificationSent: boolean;
  popupShown: boolean;
  promoCode: PromoCode;
}

export interface SpinWheelAttempt {
  id: number;
  userId: number;
  spunAt: string;
  discountWon: number;
  promoCode: PromoCode;
}

@Injectable({
  providedIn: 'root'
})
export class PromoCodeService {
  private baseUrl = 'http://localhost:8091/api';

  constructor(private http: HttpClient) {}

  // Promo Code Endpoints
  getUserPromoCodes(userId: number): Observable<PromoCode[]> {
    return this.http.get<PromoCode[]>(`${this.baseUrl}/promo-codes/user/${userId}`);
  }

  getAvailableCodes(userId: number): Observable<PromoCode[]> {
    return this.http.get<PromoCode[]>(`${this.baseUrl}/promo-codes/available/${userId}`);
  }

  validateCode(code: string, userId: number, subscriptionCount: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/promo-codes/validate`, null, {
      params: { code, userId: userId.toString(), subscriptionCount: subscriptionCount.toString() }
    });
  }

  calculateDiscount(code: string, originalPrice: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/promo-codes/calculate-discount`, null, {
      params: { code, originalPrice: originalPrice.toString() }
    });
  }

  applyPromoCode(code: string, subscriptionId: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/promo-codes/apply`, null, {
      params: { code, subscriptionId: subscriptionId.toString() }
    });
  }

  checkEligibility(userId: number, subscriptionCount: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/promo-codes/check-eligibility`, {
      params: { userId: userId.toString(), subscriptionCount: subscriptionCount.toString() }
    });
  }

  getCodeDetails(code: string): Observable<PromoCode> {
    return this.http.get<PromoCode>(`${this.baseUrl}/promo-codes/details/${code}`);
  }

  // Reward Endpoints
  getUserRewards(userId: number): Observable<UserReward[]> {
    return this.http.get<UserReward[]>(`${this.baseUrl}/rewards/user/${userId}`);
  }

  getPendingNotifications(userId: number): Observable<UserReward[]> {
    return this.http.get<UserReward[]>(`${this.baseUrl}/rewards/notifications/${userId}`);
  }

  getPendingPopups(userId: number): Observable<UserReward[]> {
    return this.http.get<UserReward[]>(`${this.baseUrl}/rewards/popups/${userId}`);
  }

  markNotificationSent(rewardId: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/rewards/notifications/${rewardId}/mark-sent`, null);
  }

  markPopupShown(rewardId: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/rewards/popups/${rewardId}/mark-shown`, null);
  }

  awardStudentDiscount(userId: number, email: string): Observable<any> {
    return this.http.post(`${this.baseUrl}/rewards/student/${userId}`, null, {
      params: { email }
    });
  }

  // Spin Wheel Endpoints
  spinWheel(userId: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/rewards/spin-wheel/${userId}`, null);
  }

  canUserSpin(userId: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/rewards/spin-wheel/can-spin/${userId}`);
  }

  getSpinHistory(userId: number): Observable<SpinWheelAttempt[]> {
    return this.http.get<SpinWheelAttempt[]>(`${this.baseUrl}/rewards/spin-wheel/history/${userId}`);
  }

  awardCertification(userId: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/rewards/certification/${userId}`, null);
  }

  awardReferral5(userId: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/rewards/referral-5/${userId}`, null);
  }

  // ========== ADMIN ENDPOINTS ==========

  // Get all promo codes (admin)
  getAllPromoCodes(): Observable<PromoCode[]> {
    return this.http.get<PromoCode[]>(`${this.baseUrl}/promo-codes/admin/all`);
  }

  // Create promo code (admin)
  createPromoCode(promoCode: Partial<PromoCode>): Observable<PromoCode> {
    return this.http.post<PromoCode>(`${this.baseUrl}/promo-codes/admin/create`, promoCode);
  }

  // Update promo code (admin)
  updatePromoCode(id: number, promoCode: Partial<PromoCode>): Observable<PromoCode> {
    return this.http.put<PromoCode>(`${this.baseUrl}/promo-codes/admin/${id}`, promoCode);
  }

  // Delete promo code (admin)
  deletePromoCode(id: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/promo-codes/admin/${id}`);
  }

  // Toggle promo code status (admin)
  togglePromoCodeStatus(id: number): Observable<PromoCode> {
    return this.http.put<PromoCode>(`${this.baseUrl}/promo-codes/admin/${id}/toggle`, null);
  }

}

