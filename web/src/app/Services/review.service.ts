import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Review } from '../models/Review';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ReviewService {private apiUrl = 'http://localhost:8085/Review'; 

  constructor(private http: HttpClient) { }

  getReviewsByFreelancer(freelancerId: string): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.apiUrl}/GetReviewsByFreelancer/${freelancerId}`);
  }

  getReviewsByClient(clientId: string): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.apiUrl}/GetReviewsByClient/${clientId}`);
  }

  getAllReviews(): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.apiUrl}/GetAllReview`);
  }

  addReview(review: Review): Observable<Review> {
    return this.http.post<Review>(`${this.apiUrl}/AjouterReview`, review);
  }

  deleteReview(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/SupprimerReview/${id}`);
  }
}

