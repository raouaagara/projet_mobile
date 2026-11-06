import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { map, catchError, tap } from 'rxjs/operators';

const API = 'http://localhost:8085/User';

export interface User {
  id?: number;
  firstName: string;
  lastName: string;
  email: string;
  password?: string;
  role: 'FREELANCER' | 'CLIENT' | 'ADMIN';
  location?: string;
  bio?: string;
  profilePictureUrl?: string;
  coverPictureUrl?: string;
  linkedinUrl?: string;
  website?: string;
  competenceIds?: number[];
  cvFileName?: string;
  createdAt?: string;
}

export interface LoginResponse {
  token: string;
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    // Load user from localStorage on init
    const token = this.getToken();
    if (token) {
      const userData = this.getUserDataFromToken(token);
      if (userData) {
        this.currentUserSubject.next(userData);
      }
    }
  }

  // Authentication Methods
  register(user: User): Observable<User | null> {
    return this.http.post<User>(`${API}/register`, user).pipe(
      catchError((error) => {
        console.error('Registration error:', error);
        return of(null);
      })
    );
  }

  login(email: string, password: string): Observable<LoginResponse | null> {
    return this.http.post<LoginResponse>(`${API}/login`, { email, password }).pipe(
      tap((response) => {
        if (response && response.token) {
          this.setToken(response.token);
          const userData = this.getUserDataFromToken(response.token);
          if (userData) {
            this.currentUserSubject.next(userData);
          }
        }
      }),
      catchError((error) => {
        console.error('Login error:', error);
        return of(null);
      })
    );
  }

  logout(): void {
    localStorage.removeItem('jwt_token');
    this.currentUserSubject.next(null);
  }

  // User CRUD Methods
  getAllUsers(): Observable<User[]> {
    return this.http.get<User[]>(`${API}/all`).pipe(
      catchError(() => of([]))
    );
  }

  getUserById(id: number): Observable<User | null> {
    return this.http.get<User>(`${API}/${id}`).pipe(
      catchError(() => of(null))
    );
  }

  updateUser(id: number, user: Partial<User>): Observable<User | null> {
    return this.http.put<User>(`${API}/update/${id}`, user).pipe(
      tap((updatedUser) => {
        if (updatedUser && this.currentUserSubject.value?.id === id) {
          this.currentUserSubject.next({ ...this.currentUserSubject.value, ...updatedUser });
        }
      }),
      catchError(() => of(null))
    );
  }

  deleteUser(id: number): Observable<boolean> {
    return this.http.delete(`${API}/delete/${id}`).pipe(
      map(() => true),
      catchError(() => of(false))
    );
  }

  // Competences Management
  addCompetencesToUser(userId: number, competenceIds: number[]): Observable<any> {
    return this.http.post(`${API}/${userId}/competences`, competenceIds).pipe(
      catchError((error) => {
        console.error('Add competences error:', error);
        return of(null);
      })
    );
  }

  // CV Upload/Download
  uploadCV(userId: number, file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    
    return this.http.post(`${API}/${userId}/upload-cv`, formData).pipe(
      catchError((error) => {
        console.error('CV upload error:', error);
        return of(null);
      })
    );
  }

  downloadCV(filename: string): Observable<Blob> {
    return this.http.get(`${API}/download-cv/${filename}`, { 
      responseType: 'blob' 
    }).pipe(
      catchError((error) => {
        console.error('CV download error:', error);
        return of(new Blob());
      })
    );
  }

  // Token Management
  private setToken(token: string): void {
    localStorage.setItem('currentUser', token);
  }

  getToken(): string | null {
    return localStorage.getItem('currentUser');
  }

  isLoggedIn(): boolean {
    return !!this.getToken();
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  // Decode JWT token to get user data
  private getUserDataFromToken(token: string): User | null {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return {
        id: payload.id,
        email: payload.sub,
        role: payload.role,
        firstName: '',
        lastName: ''
      };
    } catch (error) {
      console.error('Error decoding token:', error);
      return null;
    }
  }

  // Get Authorization Headers
  getAuthHeaders(): HttpHeaders {
    const token = this.getToken();
    return new HttpHeaders({
      'Authorization': token ? `Bearer ${token}` : ''
    });
  }
}

