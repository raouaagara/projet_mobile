import { Injectable } from '@angular/core';
import { User } from '../models/user';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class UserService {


  private apiUrl = 'http://localhost:8085/users'; 

  constructor(private http: HttpClient) { }


  getAllUsers() {
    return this.http.get<any[]>(`${this.apiUrl}/all`); // ?? N'oublie pas le /all ici !
  }
  register(user: User): Observable<User> {
    return this.http.post<User>(`${this.apiUrl}/register`, user);
  }
  updateUserCompetences(userId: string, competenceIds: number[]) {
    return this.http.post(`${this.apiUrl}/${userId}/competences`, competenceIds, { responseType: 'text' });
  }

  uploadCv(userId: string, file: File) {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${this.apiUrl}/${userId}/upload-cv`, formData);
  }


  login(credentials: {email: string, password: string}): Observable<User> {
    return this.http.post<User>(`${this.apiUrl}/login`, credentials);
  }
  getUserById(id: number): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/${id}`);
  }

  updateUser(id: number, user: any): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/update/${id}`, user);
  }
}


