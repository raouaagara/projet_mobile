import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface FlouciPaymentRequest {
  amount: number;
  description: string;
  successUrl: string;
  failUrl: string;
  developerTrackingId?: string;
}

export interface FlouciPaymentResponse {
  result: {
    link: string;
    payment_id: string;
  };
  success: boolean;
}

export interface FlouciVerifyResponse {
  result: {
    status: string;
    amount: number;
    transaction_id: string;
  };
  success: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class FlouciService {
  // Flouci API Configuration
  private readonly FLOUCI_API_URL = 'https://developers.flouci.com/api';
  private readonly APP_TOKEN = 'YOUR_FLOUCI_APP_TOKEN'; 
  private readonly APP_SECRET = 'YOUR_FLOUCI_APP_SECRET'; 
  
  // Backend proxy endpoint (recommended for security)
  private readonly BACKEND_URL = 'http://localhost:8091/Subscription/flouci';
  private useTestMode = true; 

  constructor(private http: HttpClient) {
    
    this.checkConfiguration();
  }


  private checkConfiguration(): void {
    this.http.get<any>(`${this.BACKEND_URL}/status`).subscribe({
      next: (response) => {
        this.useTestMode = !response.configured || response.testMode;
        if (this.useTestMode) {
          console.warn('?? Flouci TEST MODE: Using mock payments. Configure real credentials in backend.');
        } else {
          console.log('? Flouci PRODUCTION MODE: Using real Flouci API.');
        }
      },
      error: () => {
        this.useTestMode = true;
        console.warn('?? Flouci TEST MODE: Backend not responding. Using mock payments.');
      }
    });
  }


  initiatePayment(request: FlouciPaymentRequest): Observable<FlouciPaymentResponse> {
    // Use test mode if not configured
    const endpoint = this.useTestMode ? 
      `${this.BACKEND_URL}/test/initiate` : 
      `${this.BACKEND_URL}/initiate`;
    
    return this.http.post<FlouciPaymentResponse>(endpoint, request);
  }

  private directApiCall(request: FlouciPaymentRequest): Observable<FlouciPaymentResponse> {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'apppublic': this.APP_TOKEN,
      'appsecret': this.APP_SECRET
    });

    const payload = {
      app_token: this.APP_TOKEN,
      app_secret: this.APP_SECRET,
      amount: request.amount * 1000, 
      accept_card: 'true',
      session_timeout_secs: 1200, 
      success_link: request.successUrl,
      fail_link: request.failUrl,
      developer_tracking_id: request.developerTrackingId || `SUB_${Date.now()}`
    };

    return this.http.post<FlouciPaymentResponse>(
      `${this.FLOUCI_API_URL}/generate_payment`,
      payload,
      { headers }
    );
  }

  /**
   * Verify payment status
   * Call this after user returns from Flouci payment page
   */
  verifyPayment(paymentId: string): Observable<FlouciVerifyResponse> {
    // Use test mode if not configured
    const endpoint = this.useTestMode ? 
      `${this.BACKEND_URL}/test/verify/${paymentId}` : 
      `${this.BACKEND_URL}/verify/${paymentId}`;
    
    console.log(`Flouci: Verifying payment ${paymentId} using ${this.useTestMode ? 'TEST' : 'PRODUCTION'} mode`);
    console.log(`Flouci: Calling endpoint: ${endpoint}`);
    
    return this.http.get<FlouciVerifyResponse>(endpoint);
  }

  /**
   * Direct verification (use only for testing)
   */
  private directVerification(paymentId: string): Observable<FlouciVerifyResponse> {
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'apppublic': this.APP_TOKEN
    });

    return this.http.get<FlouciVerifyResponse>(
      `${this.FLOUCI_API_URL}/verify_payment/${paymentId}`,
      { headers }
    );
  }

  /**
   * Open Flouci payment page in new window
   */
  openPaymentPage(paymentLink: string): void {
    window.open(paymentLink, '_blank', 'width=600,height=700');
  }

  /**
   * Redirect to Flouci payment page
   */
  redirectToPayment(paymentLink: string): void {
    window.location.href = paymentLink;
  }

  /**
   * Format amount for display (TND)
   */
  formatAmount(amount: number): string {
    return `${amount.toFixed(3)} TND`;
  }

  /**
   * Convert USD to TND (approximate rate)
   * In production, use real-time exchange rates
   */
  convertUsdToTnd(usdAmount: number): number {
    const exchangeRate = 3.1; // 1 USD ˜ 3.1 TND (update with real rate)
    return usdAmount * exchangeRate;
  }
}

