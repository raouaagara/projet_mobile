import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

const API = 'http://localhost:8089/SkillTests';

export interface SkillTest {
  id?: number;
  title: string;
  description: string;
  category: string;
  durationMinutes: number;
  passScore: number;
  active?: boolean;
  scheduledStartDate?: string;
  expiryDate?: string;
}

export interface Question {
  id?: number;
  questionText: string;
  optionA: string;
  optionB: string;
  optionC: string;
  optionD: string;
  correctOption?: string; // Only used when creating/updating
}

export interface Certification {
  id: number;
  userId: number;
  userName?: string;
  skillTestId: number;
  testTitle: string;
  category: string;
  score: number;
  passed: boolean;
  completedAt: string;
}

@Injectable({ providedIn: 'root' })
export class SkillTestService {
  constructor(private http: HttpClient) {}

  getTests(): Observable<SkillTest[]> {
    return this.http.get<SkillTest[]>(`${API}/tests`);
  }

  getTest(id: number): Observable<SkillTest> {
    return this.http.get<SkillTest>(`${API}/tests/${id}`);
  }

  getQuestions(testId: number): Observable<Question[]> {
    return this.http.get<Question[]>(`${API}/tests/${testId}/questions`);
  }

  getCategories(): Observable<string[]> {
    return this.http.get<string[]>(`${API}/categories`);
  }

  generateAiTest(userId: number, category: string, hasAiAccess: boolean, userName?: string): Observable<SkillTest> {
    return this.http.post<SkillTest>(`${API}/ai/generate`, {
      userId,
      category,
      hasAiAccess,
      userName
    });
  }

  submitTest(userId: number, testId: number, answers: Record<number, string>, userName?: string): Observable<Certification> {
    if (userName) {
      return this.http.post<Certification>(
        `${API}/submit-with-name?userId=${userId}&testId=${testId}&userName=${encodeURIComponent(userName)}`,
        answers
      );
    }
    return this.http.post<Certification>(`${API}/submit?userId=${userId}&testId=${testId}`, answers);
  }

  getUserCertifications(userId: number): Observable<Certification[]> {
    return this.http.get<Certification[]>(`${API}/certifications/user/${userId}`);
  }

  getAllCertifications(): Observable<Certification[]> {
    return this.http.get<Certification[]>(`${API}/admin/all-certifications`);
  }

  getPassedCertifications(): Observable<Certification[]> {
    return this.http.get<Certification[]>(`${API}/admin/passed-certifications`);
  }

  getStatsByCategory(): Observable<Record<string, number>> {
    return this.http.get<Record<string, number>>(`${API}/admin/stats-by-category`);
  }

  // Admin Test Management
  getAllTestsAdmin(): Observable<SkillTest[]> {
    return this.http.get<SkillTest[]>(`${API}/admin/tests`);
  }

  createTest(test: SkillTest): Observable<SkillTest> {
    return this.http.post<SkillTest>(`${API}/admin/tests`, test);
  }

  updateTest(id: number, test: SkillTest): Observable<SkillTest> {
    return this.http.put<SkillTest>(`${API}/admin/tests/${id}`, test);
  }

  deleteTest(id: number): Observable<void> {
    return this.http.delete<void>(`${API}/admin/tests/${id}`);
  }

  // Question Management
  getTestQuestions(testId: number): Observable<Question[]> {
    return this.http.get<Question[]>(`${API}/tests/${testId}/questions`);
  }

  createQuestion(testId: number, question: Question): Observable<Question> {
    return this.http.post<Question>(`${API}/admin/tests/${testId}/questions`, question);
  }

  updateQuestion(questionId: number, question: Question): Observable<Question> {
    return this.http.put<Question>(`${API}/admin/questions/${questionId}`, question);
  }

  deleteQuestion(questionId: number): Observable<void> {
    return this.http.delete<void>(`${API}/admin/questions/${questionId}`);
  }

  getCertification(id: number): Observable<Certification> {
    return this.http.get<Certification>(`${API}/admin/certifications/${id}`);
  }

  deleteCertification(id: number): Observable<void> {
    return this.http.delete<void>(`${API}/admin/certifications/${id}`);
  }

  // Test Statistics
  getTestStatistics(testId: number): Observable<any> {
    return this.http.get<any>(`${API}/admin/tests/${testId}/statistics`);
  }
}

