import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Dispute {
  id?: number;
  escrowId?: number;
  contractId: number;
  raisedByUserId: number;
  againstUserId: number;
  reason: string;
  status?: string;
  createdAt?: string;
  resolvedAt?: string;
  escrow?: any;
}

@Injectable({
  providedIn: 'root'
})
export class DisputeService {
  private apiUrl = 'http://localhost:8085/api/disputes'; // Direct URL

  constructor(private http: HttpClient) {}

  raiseDispute(contractId: number, raisedByUserId: number, reason: string): Observable<Dispute> {
    return this.http.post<Dispute>(`${this.apiUrl}/raise`, { contractId, raisedByUserId, reason });
  }

  getAllDisputes(): Observable<Dispute[]> {
    return this.http.get<Dispute[]>(`${this.apiUrl}/all`);
  }

  resolveDispute(id: number, resolution: 'CLIENT' | 'FREELANCER'): Observable<Dispute> {
    return this.http.post<Dispute>(`${this.apiUrl}/${id}/resolve`, { resolution });
  }
}

