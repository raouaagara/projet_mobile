import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

const API = 'http://localhost:8092/Referral';

export interface ReferralCode {
  id?: number;
  userId: number;
  code: string;
  createdAt?: string;
}

export interface Referral {
  id?: number;
  referralCode: ReferralCode;
  referredUserId: number;
  referredUserName?: string;
  status: 'SIGNED_UP' | 'QUALIFIED' | 'REWARDED';
  createdAt?: string;
  qualifiedAt?: string;
}

export interface ReferralReward {
  id?: number;
  referral: Referral;
  userId: number;
  rewardType: string;
  amount: number;
  createdAt?: string;
}

export interface ReferralStats {
  totalReferrals: number;
  qualifiedReferrals: number;
  pendingReferrals: number;
  totalEarned: number;
  pendingEarnings: number;
  referralCode: string;
}

@Injectable({ providedIn: 'root' })
export class ReferralService {
  constructor(private http: HttpClient) {}

  // Get or create referral code for user
  getReferralCode(userId: number): Observable<string> {
    return this.http.get(`${API}/code/${userId}`, { responseType: 'text' });
  }

  // Get user's referrals
  getUserReferrals(userId: number): Observable<Referral[]> {
    return this.http.get<Referral[]>(`${API}/referrals/${userId}`);
  }

  // Get user's rewards
  getUserRewards(userId: number): Observable<ReferralReward[]> {
    return this.http.get<ReferralReward[]>(`${API}/rewards/${userId}`);
  }

  // Get total earned
  getTotalEarned(userId: number): Observable<number> {
    return this.http.get<number>(`${API}/earned/${userId}`);
  }

  // Use referral code (when new user signs up)
  useReferralCode(code: string, referredUserId: number): Observable<Referral> {
    return this.http.post<Referral>(`${API}/use/${code}?referredUserId=${referredUserId}`, {});
  }

  // Generate referral URL
  generateReferralUrl(code: string): string {
    return `${window.location.origin}/RegisterFreelancer?ref=${code}`;
  }

  // Social media share URLs
  getTwitterShareUrl(referralUrl: string): string {
    const text = encodeURIComponent('Join CatchOPP and find amazing freelance opportunities! ??');
    return `https://twitter.com/intent/tweet?text=${text}&url=${encodeURIComponent(referralUrl)}`;
  }

  getLinkedInShareUrl(referralUrl: string): string {
    return `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(referralUrl)}`;
  }

  getFacebookShareUrl(referralUrl: string): string {
    return `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(referralUrl)}`;
  }

  getWhatsAppShareUrl(referralUrl: string): string {
    const text = encodeURIComponent(`Join CatchOPP and find amazing freelance opportunities! ${referralUrl}`);
    return `https://wa.me/?text=${text}`;
  }

  getEmailShareUrl(referralUrl: string): string {
    const subject = encodeURIComponent('Join CatchOPP - Freelance Platform');
    const body = encodeURIComponent(`Hi!\n\nI'm using CatchOPP to find freelance work and thought you might be interested too!\n\nSign up using my referral link:\n${referralUrl}\n\nBest regards!`);
    return `mailto:?subject=${subject}&body=${body}`;
  }
}

