import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Comment, CommentForm } from './models';
import { API_CONFIG } from './api.config';

@Injectable({
  providedIn: 'root'
})
export class CommentService {
  private apiUrl = `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.COMMENTS}`;

  constructor(private http: HttpClient) {}

  addComment(commentForm: CommentForm): Observable<Comment> {
    return this.http.post<Comment>(this.apiUrl, commentForm);
  }

  getCommentsByPost(postId: number): Observable<Comment[]> {
    return this.http.get<Comment[]>(`${this.apiUrl}/post/${postId}`);
  }

  getCommentsCount(postId: number): Observable<number> {
    return this.http.get<number>(`${this.apiUrl}/post/${postId}/count`);
  }

  updateComment(commentId: number, content: string): Observable<Comment> {
    return this.http.put<Comment>(`${this.apiUrl}/${commentId}`, { content });
  }

  deleteComment(commentId: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${commentId}`);
  }
}