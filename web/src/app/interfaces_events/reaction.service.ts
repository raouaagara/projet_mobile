import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Reaction, ReactionForm, ReactionType } from './models';
import { API_CONFIG } from './api.config';

@Injectable({
  providedIn: 'root'
})
export class ReactionService {
  private apiUrl = `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.REACTIONS}`;

  constructor(private http: HttpClient) {}

  addOrUpdateReaction(reactionForm: ReactionForm): Observable<Reaction> {
    return this.http.post<Reaction>(this.apiUrl, reactionForm);
  }

  getReactionCounts(postId: number): Observable<{ [key in ReactionType]: number }> {
    return this.http.get<{ [key in ReactionType]: number }>(`${this.apiUrl}/post/${postId}/counts`);
  }

  getUserReaction(postId: number, authorId: number): Observable<{ hasReaction: boolean; reactionType: ReactionType | null }> {
    return this.http.get<{ hasReaction: boolean; reactionType: ReactionType | null }>(`${this.apiUrl}/post/${postId}/user/${authorId}`);
  }

  removeReaction(postId: number, authorId: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/post/${postId}/user/${authorId}`);
  }
}