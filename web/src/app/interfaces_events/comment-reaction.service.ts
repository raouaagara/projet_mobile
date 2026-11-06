import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ReactionType } from './models';
import { API_CONFIG } from './api.config';

@Injectable({
  providedIn: 'root'
})
export class CommentReactionService {
  private apiUrl = `${API_CONFIG.BASE_URL}/api/comment-reactions`;

  constructor(private http: HttpClient) {}

  addOrUpdateReaction(reactionForm: { commentId: number; authorId: number; type: ReactionType }): Observable<any> {
    return this.http.post(this.apiUrl, reactionForm);
  }

  getReactionCounts(commentId: number): Observable<{ [key in ReactionType]: number }> {
    return this.http.get<{ [key in ReactionType]: number }>(`${this.apiUrl}/comment/${commentId}/counts`);
  }

  getUserReaction(commentId: number, authorId: number): Observable<{ hasReaction: boolean; reactionType: ReactionType | null }> {
    return this.http.get<{ hasReaction: boolean; reactionType: ReactionType | null }>(`${this.apiUrl}/comment/${commentId}/user/${authorId}`);
  }

  removeReaction(commentId: number, authorId: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/comment/${commentId}/user/${authorId}`);
  }
}
