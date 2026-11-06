import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

const API = 'http://localhost:8092/Referral/availability';

export type AvailabilityStatus = 'ONLINE' | 'AVAILABLE' | 'AVAILABLE_TOMORROW' | 'OFFLINE' | 'DO_NOT_DISTURB' | 'CUSTOM';

export interface AvailabilityProfile {
  id?: number;
  userId: number;
  timezone: string;
  timezoneOffsetMinutes?: number;
  status: AvailabilityStatus;
  customStatusMessage?: string;
  lastSeenAt?: string;
  slots?: AvailableSlot[];
}

export interface AvailableSlot {
  id?: number;
  dayOfWeek: string;
  startTime: string;
  endTime: string;
}

export interface WorldViewItem {
  userId: number;
  profileId: number;
  timezone: string;
  timezoneOffsetMinutes: number;
  status: string;
  customStatusMessage: string;
  lastSeenAt: string;
}

@Injectable({ providedIn: 'root' })
export class AvailabilityService {
  constructor(private http: HttpClient) {}

  getProfile(userId: number): Observable<AvailabilityProfile> {
    return this.http.get<AvailabilityProfile>(`${API}/profile/${userId}`).pipe(
      catchError(() => of(null as any))
    );
  }

  getOrCreateProfile(userId: number, timezone = 'UTC'): Observable<AvailabilityProfile> {
    return this.http.get<AvailabilityProfile>(`${API}/profile/${userId}/or-create?timezone=${encodeURIComponent(timezone)}`).pipe(
      catchError(() => of(null as any))
    );
  }

  getAllProfiles(): Observable<AvailabilityProfile[]> {
    return this.http.get<AvailabilityProfile[]>(`${API}/profiles`).pipe(
      catchError(() => of([]))
    );
  }

  getProfilesByStatus(status: AvailabilityStatus): Observable<AvailabilityProfile[]> {
    return this.http.get<AvailabilityProfile[]>(`${API}/profiles/status/${status}`).pipe(
      catchError(() => of([]))
    );
  }

  getWorldView(): Observable<WorldViewItem[]> {
    console.log('?? Availability Service: Fetching world view');
    return this.http.get<WorldViewItem[]>(`${API}/world-view`).pipe(
      catchError((error) => {
        console.error('? Availability Service: Error fetching world view:', error);
        return of([]);
      })
    );
  }

  createProfile(profile: Partial<AvailabilityProfile>): Observable<AvailabilityProfile> {
    return this.http.post<AvailabilityProfile>(`${API}/profiles`, profile).pipe(
      catchError(() => of(null as any))
    );
  }

  updateProfile(id: number, profile: Partial<AvailabilityProfile>): Observable<AvailabilityProfile> {
    console.log('?? Availability Service: Updating profile', id, profile);
    return this.http.put<AvailabilityProfile>(`${API}/profiles/${id}`, profile).pipe(
      catchError((error) => {
        console.error('? Availability Service: Error updating profile:', error);
        return of(null as any);
      })
    );
  }

  updateHeartbeat(userId: number): Observable<AvailabilityProfile> {
    return this.http.put<AvailabilityProfile>(`${API}/profiles/heartbeat/${userId}`, {}).pipe(
      catchError(() => of(null as any))
    );
  }

  deleteProfile(id: number): Observable<void> {
    return this.http.delete<void>(`${API}/profiles/${id}`).pipe(
      catchError(() => of(undefined))
    );
  }

  getSlots(profileId: number): Observable<AvailableSlot[]> {
    return this.http.get<AvailableSlot[]>(`${API}/profiles/${profileId}/slots`).pipe(
      catchError(() => of([]))
    );
  }

  getSlotsByUserId(userId: number): Observable<AvailableSlot[]> {
    return this.http.get<AvailableSlot[]>(`${API}/users/${userId}/slots`).pipe(
      catchError(() => of([]))
    );
  }

  addSlot(profileId: number, slot: AvailableSlot): Observable<AvailableSlot> {
    return this.http.post<AvailableSlot>(`${API}/profiles/${profileId}/slots`, slot).pipe(
      catchError(() => of(null as any))
    );
  }

  updateSlot(id: number, slot: Partial<AvailableSlot>): Observable<AvailableSlot> {
    return this.http.put<AvailableSlot>(`${API}/slots/${id}`, slot).pipe(
      catchError(() => of(null as any))
    );
  }

  deleteSlot(id: number): Observable<void> {
    return this.http.delete<void>(`${API}/slots/${id}`).pipe(
      catchError(() => of(undefined))
    );
  }

  findCompatibleSlots(userIds: number[]): Observable<Array<{ dayOfWeek: string; startTime: string; endTime: string }>> {
    if (!userIds.length) return of([]);
    const params = userIds.map(id => `userIds=${id}`).join('&');
    return this.http.get<any[]>(`${API}/compatible-slots?${params}`).pipe(
      catchError(() => of([]))
    );
  }

  /** Get browser timezone (e.g. Europe/Paris) */
  getBrowserTimezone(): string {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
  }

  /** Get formatted local time for a timezone */
  getLocalTimeInTimezone(tz: string): Date {
    return new Date(new Date().toLocaleString('en-US', { timeZone: tz }));
  }
}

