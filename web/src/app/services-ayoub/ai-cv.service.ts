import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

export interface CVAnalysisRequest {
  cvText: string;
  targetDomain: string;
  currentSkills?: string[];
}

export interface CVAnalysisResponse {
  improvedCV: string;
  suggestions: string[];
  missingSkills: string[];
  strengthAreas: string[];
  summary: string;
}

@Injectable({
  providedIn: 'root'
})
export class AiCvService {
  // Backend API (using SkillTests microservice)
  private readonly API_URL = 'http://localhost:8089/SkillTests/ai/cv';

  constructor(private http: HttpClient) {}

  /**
   * Analyze and improve CV using backend API (text input)
   */
  analyzeAndImproveCV(request: CVAnalysisRequest): Observable<CVAnalysisResponse> {
    return this.http.post<CVAnalysisResponse>(`${this.API_URL}/analyze-text`, {
      cvText: request.cvText,
      targetDomain: request.targetDomain
    }).pipe(
      catchError(error => {
        console.error('Backend API Error:', error);
        return throwError(() => new Error('Failed to analyze CV. Please try again.'));
      })
    );
  }

  /**
   * Analyze and improve CV from image using backend API
   */
  analyzeAndImproveCVFromImage(imageBase64: string, mimeType: string, targetDomain: string): Observable<CVAnalysisResponse> {
    return this.http.post<CVAnalysisResponse>(`${this.API_URL}/analyze-image`, {
      imageBase64,
      mimeType,
      targetDomain
    }).pipe(
      catchError(error => {
        console.error('Backend API Error:', error);
        return throwError(() => new Error('Failed to analyze CV image. Please try again.'));
      })
    );
  }

  /**
   * Extract text from uploaded CV file
   */
  extractTextFromFile(file: File): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = (e: any) => {
        const text = e.target.result;
        resolve(text);
      };
      
      reader.onerror = () => {
        reject(new Error('Failed to read file'));
      };
      
      if (file.type === 'text/plain' || file.name.endsWith('.txt')) {
        reader.readAsText(file);
      } else {
        reject(new Error('Please paste your CV text or upload a .txt file'));
      }
    });
  }

  /**
   * Convert image file to base64 for backend API
   */
  convertImageToBase64(file: File): Promise<{ base64: string; mimeType: string }> {
    return new Promise((resolve, reject) => {
      // Check if file is an image
      if (!file.type.startsWith('image/')) {
        reject(new Error('Please upload an image file (PNG, JPG, JPEG, WebP)'));
        return;
      }

      const reader = new FileReader();
      
      reader.onload = (e: any) => {
        const base64String = e.target.result.split(',')[1]; // Remove data:image/...;base64, prefix
        resolve({
          base64: base64String,
          mimeType: file.type
        });
      };
      
      reader.onerror = () => {
        reject(new Error('Failed to read image file'));
      };
      
      reader.readAsDataURL(file);
    });
  }

  /**
   * Check if file is an image
   */
  isImageFile(file: File): boolean {
    return file.type.startsWith('image/');
  }

  /**
   * Get popular job domains
   */
  getJobDomains(): string[] {
    return [
      'Software Development',
      'Web Development',
      'Mobile Development',
      'Data Science',
      'Machine Learning / AI',
      'DevOps / Cloud Engineering',
      'Cybersecurity',
      'UI/UX Design',
      'Graphic Design',
      'Digital Marketing',
      'Content Writing',
      'Project Management',
      'Business Analysis',
      'Quality Assurance',
      'Database Administration',
      'Network Engineering',
      'System Administration',
      'Frontend Development',
      'Backend Development',
      'Full Stack Development'
    ];
  }
}

