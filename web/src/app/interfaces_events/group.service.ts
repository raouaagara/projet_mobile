import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { getApiUrl, API_CONFIG } from './api.config';

export interface Group {
  id?: number;
  name: string;
  description: string;
  bannerUrl?: string;
  type: 'PUBLIC' | 'PRIVATE' | 'INVITE_ONLY';
  createdAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class GroupService {
  private apiUrl = getApiUrl(API_CONFIG.ENDPOINTS.GROUPS);

  constructor(private http: HttpClient) {}

  getAllGroups(): Observable<Group[]> {
    return this.http.get<Group[]>(this.apiUrl);
  }

  getGroupById(id: number): Observable<Group> {
    return this.http.get<Group>(`${this.apiUrl}/${id}`);
  }

  createGroup(group: Group): Observable<Group> {
    return this.http.post<Group>(this.apiUrl, group);
  }

  updateGroup(id: number, group: Group): Observable<Group> {
    return this.http.put<Group>(`${this.apiUrl}/${id}`, group);
  }

  deleteGroup(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  getGroups(): Observable<Group[]> {
    return this.getAllGroups();
  }
}
