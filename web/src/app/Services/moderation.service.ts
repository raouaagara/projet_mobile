import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

interface ModerationResult {
  isHarmful: boolean;
  categories: string[];
  scores: { [key: string]: number };
  message?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ModerationService {
  private apiUrl = 'https://api-inference.huggingface.co/models/KoalaAI/Text-Moderation';
  
  // DEMO MODE: Set to true to test without API token
  // Set to false and add real token for production use
  private demoMode = true;
  
  // IMPORTANT: Get your API token from https://huggingface.co/settings/tokens
  // 1. Go to https://huggingface.co/settings/tokens
  // 2. Create a new token with "Read" access
  // 3. Replace the value below with your token
  // 4. Set demoMode = false to use real API
  private apiToken = 'hf_YOUR_TOKEN_HERE'; // Replace with your actual Hugging Face token!

  constructor(private http: HttpClient) {}

  checkMessage(text: string): Observable<ModerationResult> {
    if (!text || text.trim().length === 0) {
      return of({ isHarmful: false, categories: [], scores: {} });
    }

    // DEMO MODE: Use mock responses for testing
    if (this.demoMode) {
      return this.mockModerationCheck(text);
    }

    const headers = new HttpHeaders({
      'Authorization': `Bearer ${this.apiToken}`,
      'Content-Type': 'application/json'
    });

    const body = {
      inputs: text
    };

    return this.http.post<any>(this.apiUrl, body, { headers }).pipe(
      map(response => {
        console.log('Moderation API response:', response);
        
        // Parse the response from Hugging Face API
        // The API returns an array with classification results
        if (Array.isArray(response) && response.length > 0) {
          const results = response[0];
          
          // Check for harmful categories
          const harmfulCategories = [
            'sexual', 'hate', 'harassment', 'self-harm', 
            'sexual/minors', 'hate/threatening', 'violence/graphic',
            'self-harm/intent', 'self-harm/instructions', 'harassment/threatening',
            'violence'
          ];
          
          const detectedCategories: string[] = [];
          const scores: { [key: string]: number } = {};
          let isHarmful = false;
          const threshold = 0.5; // 50% confidence threshold
          
          // Process each label
          if (Array.isArray(results)) {
            results.forEach((item: any) => {
              const label = item.label.toLowerCase();
              const score = item.score;
              
              scores[label] = score;
              
              // Check if this is a harmful category with high confidence
              if (harmfulCategories.some(cat => label.includes(cat)) && score > threshold) {
                isHarmful = true;
                detectedCategories.push(label);
              }
            });
          }
          
          return {
            isHarmful,
            categories: detectedCategories,
            scores,
            message: isHarmful 
              ? `This message contains inappropriate content (${detectedCategories.join(', ')})` 
              : undefined
          };
        }
        
        // If response format is unexpected, allow the message
        return { isHarmful: false, categories: [], scores: {} };
      }),
      catchError(error => {
        console.error('Moderation API error:', error);
        
        // If API fails, allow the message but log the error
        // You can change this to block messages if API fails for security
        return of({ 
          isHarmful: false, 
          categories: [], 
          scores: {},
          message: 'Moderation check failed, message allowed'
        });
      })
    );
  }

  // Simple local check for common harmful patterns (fallback)
  simpleCheck(text: string): boolean {
    const harmfulPatterns = [
      /\b(kill|murder|die|death)\s+(you|yourself|him|her)\b/i,
      /\b(hate|stupid|idiot|dumb)\s+(you|people|person)\b/i,
      /\b(fuck|shit|damn|bitch|asshole)\b/i,
      // Add more patterns as needed
    ];
    
    return harmfulPatterns.some(pattern => pattern.test(text));
  }

  // DEMO MODE: Mock moderation check for testing without API token
  private mockModerationCheck(text: string): Observable<ModerationResult> {
    console.log('🧪 DEMO MODE: Simulating moderation check for:', text);
    
    // Simulate API delay (500ms)
    return new Observable(observer => {
      setTimeout(() => {
        const lowerText = text.toLowerCase();
        
        // Define test patterns for harmful content
        const harmfulTests = [
          { pattern: /\b(hate|hatred)\b/i, category: 'hate', score: 0.85 },
          { pattern: /\b(kill|murder|die|death)\s+(you|yourself|him|her|them)\b/i, category: 'violence', score: 0.92 },
          { pattern: /\b(stupid|idiot|dumb|moron)\s+(you|person|people)\b/i, category: 'harassment', score: 0.75 },
          { pattern: /\b(fuck|shit|bitch|asshole|damn)\b/i, category: 'harassment', score: 0.68 },
          { pattern: /\b(hurt|harm|attack)\s+(you|yourself|him|her|them)\b/i, category: 'violence', score: 0.88 },
          { pattern: /\b(suicide|self-harm|cut yourself)\b/i, category: 'self-harm', score: 0.95 },
          { pattern: /\b(sexual|nude|naked|porn)\b/i, category: 'sexual', score: 0.78 }
        ];
        
        const detectedCategories: string[] = [];
        const scores: { [key: string]: number } = {};
        let isHarmful = false;
        
        // Check each pattern
        harmfulTests.forEach(test => {
          if (test.pattern.test(text)) {
            detectedCategories.push(test.category);
            scores[test.category] = test.score;
            isHarmful = true;
          }
        });
        
        const result: ModerationResult = {
          isHarmful,
          categories: detectedCategories,
          scores,
          message: isHarmful 
            ? `⚠️ DEMO MODE: This message contains inappropriate content (${detectedCategories.join(', ')})` 
            : undefined
        };
        
        console.log('🧪 DEMO MODE: Moderation result:', result);
        observer.next(result);
        observer.complete();
      }, 500); // Simulate 500ms API delay
    });
  }
}
