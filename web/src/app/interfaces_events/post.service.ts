import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
export type { Post } from './models';
import { API_CONFIG } from './api.config';
import { Post } from './models';

@Injectable({
  providedIn: 'root'
})
export class PostService {
  private apiUrl = `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.POSTS}`;

  constructor(private http: HttpClient) {}

  // Get all posts
  getAllPosts(): Observable<Post[]> {
    return this.http.get<Post[]>(this.apiUrl);
  }

  // Get post by ID
  getPostById(id: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/${id}`);
  }

  // Get posts by group ID
  getPostsByGroupId(groupId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/group/${groupId}`);
  }

  // Get posts by group ID with user reactions
  getPostsByGroupIdWithUserReactions(groupId: number, userId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/group/${groupId}/user/${userId}`);
  }

  // Get posts by group ID (simple version for testing)
  getPostsByGroupIdSimple(groupId: number): Observable<Post[]> {
    return this.http.get<Post[]>(`${this.apiUrl}/group/${groupId}/simple`);
  }

  // Get posts by club ID
  getPostsByClubId(clubId: number): Observable<Post[]> {
    return this.http.get<Post[]>(`${this.apiUrl}/club/${clubId}`);
  }

  // Create new post
  createPost(post: Post): Observable<Post> {
    return this.http.post<Post>(this.apiUrl, post);
  }

  // Update existing post
  updatePost(id: number, post: Post): Observable<Post> {
    return this.http.put<Post>(`${this.apiUrl}/${id}`, post);
  }

  // Delete post
  deletePost(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  // Get posts with engagement metrics (reactions + comments counts)
  getPostsWithEngagement(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/with-engagement`);
  }
}
