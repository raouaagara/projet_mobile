import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { getApiUrl, API_CONFIG } from './api.config';

export interface EventItem {
  id?: number;
  title: string;
  description: string;
  location: string;
  startDate: string;
  endDate: string;
  group?: { id: number };
  creatorId?: number;
  createdAt?: string;
  status?: string;
}

@Injectable({ providedIn: 'root' })
export class EventService {
  private apiUrl = getApiUrl(API_CONFIG.ENDPOINTS.EVENTS);

  constructor(private http: HttpClient) {}

  getAllEvents(): Observable<EventItem[]> {
    return this.http.get<EventItem[]>(this.apiUrl);
  }

  getEventById(id: number): Observable<EventItem> {
    return this.http.get<EventItem>(`${this.apiUrl}/${id}`);
  }

  getEventsByGroupId(groupId: number): Observable<EventItem[]> {
    return this.http.get<EventItem[]>(`${this.apiUrl}/group/${groupId}`);
  }

  getEventsByClubId(clubId: number): Observable<EventItem[]> {
    return this.http.get<EventItem[]>(`${this.apiUrl}/club/${clubId}`);
  }

  createEvent(event: EventItem): Observable<EventItem> {
    return this.http.post<EventItem>(this.apiUrl, event);
  }

  updateEvent(id: number, event: EventItem): Observable<EventItem> {
    return this.http.put<EventItem>(`${this.apiUrl}/${id}`, event);
  }

  deleteEvent(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  getEvents(): Observable<EventItem[]> {
    return this.getAllEvents();
  }

  getPendingEvents(): Observable<EventItem[]> {
    return this.http.get<EventItem[]>(`${this.apiUrl}/pending`);
  }

  approveEvent(id: number): Observable<EventItem> {
    return this.http.put<EventItem>(`${this.apiUrl}/${id}/approve`, {});
  }

  rejectEvent(id: number): Observable<EventItem> {
    return this.http.put<EventItem>(`${this.apiUrl}/${id}/reject`, {});
  }
}
