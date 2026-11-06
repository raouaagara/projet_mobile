import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { getApiUrl, API_CONFIG } from './api.config';

export interface Club {
  id?: number;
  name: string;
  description: string;
  bannerUrl?: string;
  interests?: string;
  creatorId?: number;
  createdAt?: string;
  status?: string; 
}

@Injectable({
  providedIn: 'root'
})
export class ClubService {
  private apiUrl = getApiUrl(API_CONFIG.ENDPOINTS.CLUBS);

  constructor(private http: HttpClient) {}

  getAllClubs(): Observable<Club[]> {
    return this.http.get<Club[]>(this.apiUrl);
  }

  getClubById(id: number): Observable<Club> {
    return this.http.get<Club>(`${this.apiUrl}/${id}`);
  }

  searchClubsByInterest(interest: string): Observable<Club[]> {
    const params = new HttpParams().set('interest', interest);
    return this.http.get<Club[]>(`${this.apiUrl}/search`, { params });
  }

  createClub(club: Club): Observable<Club> {
    return this.http.post<Club>(this.apiUrl, club);
  }

  updateClub(id: number, club: Club): Observable<Club> {
    return this.http.put<Club>(`${this.apiUrl}/${id}`, club);
  }

  deleteClub(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  pauseClub(id: number): Observable<Club> {
    return this.http.put<Club>(`${this.apiUrl}/${id}/pause`, {});
  }

  unpauseClub(id: number): Observable<Club> {
    return this.http.put<Club>(`${this.apiUrl}/${id}/unpause`, {});
  }
}
