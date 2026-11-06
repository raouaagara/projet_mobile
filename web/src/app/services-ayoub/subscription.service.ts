import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';

const API = 'http://localhost:8091/Subscription';

export interface SubscriptionPlan {
  id?: number;
  name: string;
  type: string;
  price: number;
  duration: string;
  description?: string;
  benefits?: string;
  hasAiCvAccess?: boolean;
  aiCvLimit?: number;
}

export interface UserSubscription {
  id: number;
  userId: number;
  plan: SubscriptionPlan;
  status: string;
  startDate: string;
  endDate: string;
}

@Injectable({ providedIn: 'root' })
export class SubscriptionService {
  constructor(private http: HttpClient) {}

  getActiveSubscription(userId: number): Observable<UserSubscription | null> {
    console.log('?? Fetching active subscription for userId:', userId);
    return this.http.get<UserSubscription | null>(`${API}/user/${userId}/active`).pipe(
      map(sub => {
        console.log('? Subscription API response:', sub);
        return sub;
      }),
      catchError(err => {
        console.error('? Error fetching subscription:', err);
        return of(null);
      })
    );
  }

  hasAiTestAccess(userId: number): Observable<boolean> {
    return this.getActiveSubscription(userId).pipe(
      map(sub => {
        if (!sub || sub.status !== 'ACTIVE') return false;
        const type = sub.plan?.type?.toUpperCase();
        return type === 'PREMIUM' || type === 'ENTERPRISE';
      }),
      catchError(() => of(false))
    );
  }

  getAllPlans(): Observable<SubscriptionPlan[]> {
    return this.http.get<SubscriptionPlan[]>(`${API}/plans`).pipe(
      catchError(() => of([]))
    );
  }

  getPlanById(id: number): Observable<SubscriptionPlan | null> {
    return this.http.get<SubscriptionPlan>(`${API}/plans/${id}`).pipe(
      catchError(() => of(null))
    );
  }

  createPlan(plan: SubscriptionPlan): Observable<SubscriptionPlan | null> {
    return this.http.post<SubscriptionPlan>(`${API}/admin/plans`, plan).pipe(
      catchError(() => of(null))
    );
  }

  updatePlan(id: number, plan: Partial<SubscriptionPlan>): Observable<SubscriptionPlan | null> {
    return this.http.put<SubscriptionPlan>(`${API}/admin/plans/${id}`, plan).pipe(
      catchError(() => of(null))
    );
  }

  deletePlan(id: number): Observable<boolean> {
    return this.http.delete(`${API}/admin/plans/${id}`).pipe(
      map(() => true),
      catchError(() => of(false))
    );
  }

  getAllSubscriptions(): Observable<UserSubscription[]> {
    return this.http.get<UserSubscription[]>(`${API}/admin/subscriptions`).pipe(
      catchError(() => of([]))
    );
  }

  subscribe(userId: number, planId: number, email?: string): Observable<UserSubscription | null> {
    const emailParam = email ? `&email=${encodeURIComponent(email)}` : '';
    return this.http.post<UserSubscription>(`${API}/subscribe?userId=${userId}&planId=${planId}${emailParam}`, {}).pipe(
      catchError(() => of(null))
    );
  }

  recordPayment(subscriptionId: number, amount: number, paymentMethod = 'card'): Observable<{ id: number } | null> {
    console.log('?? Calling recordPayment API:', {
      url: `${API}/${subscriptionId}/payment`,
      subscriptionId,
      amount,
      paymentMethod
    });
    
    return this.http.post<{ id: number }>(
      `${API}/${subscriptionId}/payment?amount=${amount}&paymentMethod=${encodeURIComponent(paymentMethod)}`,
      {}
    ).pipe(
      tap(response => console.log('? Payment API response:', response)),
      catchError(error => {
        console.error('? Payment API error:', error);
        console.error('? Error status:', error.status);
        console.error('? Error message:', error.message);
        console.error('? Error body:', error.error);
        return of(null);
      })
    );
  }

  getPaymentsBySubscription(subscriptionId: number): Observable<Array<{ id: number; amount: number; paidAt: string; status: string; invoiceRef: string }>> {
    return this.http.get<Array<{ id: number; amount: number; paidAt: string; status: string; invoiceRef: string }>>(
      `${API}/${subscriptionId}/payments`
    ).pipe(catchError(() => of([])));
  }
  
  renewSubscription(subscriptionId: number): Observable<UserSubscription | null> {
    return this.http.put<UserSubscription>(`${API}/${subscriptionId}/renew`, {}).pipe(
      catchError(() => of(null))
    );
  }
}

