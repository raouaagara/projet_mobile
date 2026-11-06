import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class PaymentService {
  private baseUrl = 'http://localhost:8085/api/payments';

  constructor(private http: HttpClient) {}

  // User Endpoints
  getWallet(userId: number): Observable<any> {
    return this.http.get(`${this.baseUrl}/wallet/${userId}`);
  }

  getClientEscrows(userId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/escrow/client/${userId}`);
  }

  getTransactions(userId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/transactions/${userId}`);
  }
  createWallet(userId: number): Observable<any> {
  return this.http.post(`${this.baseUrl}/wallet/create/${userId}`, {});
}
createWalletFreelancer(userId: number): Observable<any> {
  return this.http.post(`${this.baseUrl}/wallet/create/freelancer/${userId}`, {});
}
getEscrowByContractId(contractId: number): Observable<any> {
  // Check your backend endpoint for this
  return this.http.get(`${this.baseUrl}/escrow/contract/${contractId}`);
}

  topUp(userId: number, amount: number): Observable<any> {
    return this.http.post(`${this.baseUrl}/topup`, { userId, amount });
  }

  // --- ADMIN ENDPOINTS (Updated to match Controller) ---

  getAllEscrowTransactions(): Observable<any[]> {
    // Matches @GetMapping("/admin/escrows")
    return this.http.get<any[]>(`${this.baseUrl}/admin/escrows`);
  }

  releaseEscrow(escrowId: number): Observable<any> {
    // Matches @PostMapping("/admin/release/{escrowId}")
    return this.http.post(`${this.baseUrl}/admin/release/${escrowId}`, {});
  }
  releasePartial(escrowId: number, amount: number): Observable<any> {
  return this.http.post(`${this.baseUrl}/admin/release-partial/${escrowId}`, { amount });
}

  refundEscrow(escrowId: number): Observable<any> {
    // Matches @PostMapping("/admin/refund/{escrowId}")
    return this.http.post(`${this.baseUrl}/admin/refund/${escrowId}`, {});
  }
  getFreelancerEscrows(freelancerId: number): Observable<any[]> {
  return this.http.get<any[]>(`${this.baseUrl}/escrow/freelancer/${freelancerId}`);
}
}
