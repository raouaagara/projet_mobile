import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Contract } from '../models/contract';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ContractService {

  private apiUrl = 'http://localhost:8085/Contract'; 
  private proposalUrl = 'http://localhost:8085/Project';

  constructor(private http: HttpClient) {}

  getClientContracts(clientId: number): Observable<Contract[]> {
    return this.http.get<Contract[]>(`${this.apiUrl}/client/${clientId}`);
  }
  getProposalById(id: number): Observable<any> {
    return this.http.get<any>(`${this.proposalUrl}/proposals/${id}`);
  }

  createContract(contract: Contract): Observable<Contract> {
    return this.http.post<Contract>(`${this.apiUrl}/create`, contract);
  }

  getContractById(id: number): Observable<Contract> {
    return this.http.get<Contract>(`${this.apiUrl}/${id}`);
  }
  generateContractFromProposal(proposalId: number, extraData: any): Observable<Contract> {
  return this.http.post<Contract>(
    `${this.apiUrl}/generate-from-proposal/${proposalId}`, 
    extraData
  );
}
  getAllContracts(): Observable<Contract[]> {
    return this.http.get<Contract[]>(`${this.apiUrl}/all`);
  }

  // Récupérer les contrats du freelance
  getFreelancerContracts(freelancerId: number): Observable<Contract[]> {
    return this.http.get<Contract[]>(`${this.apiUrl}/freelancer/${freelancerId}`);
  }


// Update the second parameter to accept 'any' or a specific object
signContract(contractId: number, data: any): Observable<Contract> {
  return this.http.put<Contract>(`${this.apiUrl}/${contractId}/sign`, data);
}

  // Rejeter
  rejectContract(contractId: number): Observable<Contract> {
    return this.http.put<Contract>(`${this.apiUrl}/${contractId}/reject`, {});
  }
}


