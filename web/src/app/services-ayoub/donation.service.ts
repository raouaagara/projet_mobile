import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface UserWallet {
  id: number;
  userId: number;
  balance: number;
  totalEarned: number;
  totalDonated: number;
  totalReceived: number;
  certificationsCount: number;
  currentTier: 'NONE' | 'BRONZE' | 'SILVER' | 'GOLD' | 'PLATINUM' | 'DIAMOND';
  createdAt: string;
  updatedAt: string;
}

export interface RewardTransaction {
  id: number;
  userId: number;
  amount: number;
  type: 'CERTIFICATION_REWARD' | 'TIER_BONUS' | 'REFERRAL_BONUS' | 'ADMIN_BONUS' | 'CHALLENGE_REWARD';
  certificationsCount: number;
  tier: string;
  description: string;
  createdAt: string;
}

export interface Donation {
  id: number;
  donorId: number;
  recipientId: number;
  amount: number;
  message: string;
  isAnonymous: boolean;
  status: 'PENDING' | 'COMPLETED' | 'REFUNDED' | 'CANCELLED';
  createdAt: string;
  completedAt: string;
  thankYouSent: boolean;
}

export interface WalletStats {
  balance: number;
  totalEarned: number;
  totalDonated: number;
  totalReceived: number;
  certificationsCount: number;
  currentTier: string;
  nextTier: string;
  certificationsToNextTier: number;
  nextTierReward: number;
}

@Injectable({
  providedIn: 'root'
})
export class DonationService {
  private baseUrl = 'http://localhost:8092/api';

  constructor(private http: HttpClient) {}

  // Wallet Endpoints
  getWallet(userId: number): Observable<UserWallet> {
    return this.http.get<UserWallet>(`${this.baseUrl}/wallet/${userId}`);
  }

  checkRewards(userId: number, score: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/wallet/check-rewards/${userId}`, null, {
      params: { score: score.toString() }
    });
  }

  getTransactionHistory(userId: number): Observable<RewardTransaction[]> {
    return this.http.get<RewardTransaction[]>(`${this.baseUrl}/wallet/${userId}/transactions`);
  }

  getWalletStats(userId: number): Observable<WalletStats> {
    return this.http.get<WalletStats>(`${this.baseUrl}/wallet/${userId}/stats`);
  }

  getTopEarners(): Observable<UserWallet[]> {
    return this.http.get<UserWallet[]>(`${this.baseUrl}/wallet/leaderboards/earners`);
  }

  getTopDonors(): Observable<UserWallet[]> {
    return this.http.get<UserWallet[]>(`${this.baseUrl}/wallet/leaderboards/donors`);
  }

  getTopLearners(): Observable<UserWallet[]> {
    return this.http.get<UserWallet[]>(`${this.baseUrl}/wallet/leaderboards/learners`);
  }

  getPlatformStats(): Observable<any> {
    return this.http.get(`${this.baseUrl}/wallet/platform/stats`);
  }

  // Donation Endpoints
  sendDonation(donorId: number, recipientId: number, amount: number, message?: string, isAnonymous: boolean = false): Observable<any> {
    return this.http.post(`${this.baseUrl}/donations/send`, null, {
      params: {
        donorId: donorId.toString(),
        recipientId: recipientId.toString(),
        amount: amount.toString(),
        ...(message && { message }),
        isAnonymous: isAnonymous.toString()
      }
    });
  }

  getDonationsSent(userId: number): Observable<Donation[]> {
    return this.http.get<Donation[]>(`${this.baseUrl}/donations/sent/${userId}`);
  }

  getDonationsReceived(userId: number): Observable<Donation[]> {
    return this.http.get<Donation[]>(`${this.baseUrl}/donations/received/${userId}`);
  }

  getDonation(id: number): Observable<Donation> {
    return this.http.get<Donation>(`${this.baseUrl}/donations/${id}`);
  }

  sendThankYou(donationId: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/donations/${donationId}/thank-you`, null);
  }

  getPendingThankYous(userId: number): Observable<Donation[]> {
    return this.http.get<Donation[]>(`${this.baseUrl}/donations/pending-thanks/${userId}`);
  }

  getUserDonationStats(userId: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/donations/stats/${userId}`);
  }

  getPlatformDonationStats(): Observable<any> {
    return this.http.get(`${this.baseUrl}/donations/platform/stats`);
  }

  refundDonation(donationId: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/donations/${donationId}/refund`, null);
  }
}

