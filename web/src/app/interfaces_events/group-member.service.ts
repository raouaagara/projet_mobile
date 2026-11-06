import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface GroupMember {
  id?: number;
  group?: { id: number };
  userId: number;
  role: 'ADMIN' | 'MODERATOR' | 'MEMBER';
  joinedAt?: string;
}

@Injectable({
  providedIn: 'root'
})
export class GroupMemberService {
  private apiUrl = 'http://localhost:8090/api/group-members';

  constructor(private http: HttpClient) {}

  // Get all members
  getAllMembers(): Observable<GroupMember[]> {
    return this.http.get<GroupMember[]>(this.apiUrl);
  }

  // Get member by ID
  getMemberById(id: number): Observable<GroupMember> {
    return this.http.get<GroupMember>(`${this.apiUrl}/${id}`);
  }

  // Get members by group ID
  getMembersByGroupId(groupId: number): Observable<GroupMember[]> {
    return this.http.get<GroupMember[]>(`${this.apiUrl}/group/${groupId}`);
  }

  // Get members by user ID
  getMembersByUserId(userId: number): Observable<GroupMember[]> {
    return this.http.get<GroupMember[]>(`${this.apiUrl}/user/${userId}`);
  }

  // Add new member
  addMember(member: GroupMember): Observable<GroupMember> {
    return this.http.post<GroupMember>(this.apiUrl, member);
  }

  // Update member role
  updateMemberRole(id: number, member: GroupMember): Observable<GroupMember> {
    return this.http.put<GroupMember>(`${this.apiUrl}/${id}`, member);
  }

  // Remove member
  removeMember(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  // Count members by group ID
  countMembersByGroupId(groupId: number): Observable<number> {
    return this.http.get<number>(`${this.apiUrl}/group/${groupId}/count`);
  }
}

