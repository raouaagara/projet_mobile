import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { delay, map } from 'rxjs/operators';

export interface AiInsight {
  type: 'payment' | 'deadline' | 'requirement' | 'general';
  text: string;
  confidence: number;
}

@Injectable({
  providedIn: 'root'
})
export class AiExtractorService {

  constructor() {}

  /**
   * Analyzes the contract text and extracts important key points.
   * This simulates an AI reading the text and identifying crucial clauses.
   */
  extractKeyPoints(text: string): Observable<AiInsight[]> {
    if (!text) {
      return of([]);
    }

    // Simulate API call delay
    return of(text).pipe(
      delay(1500),
      map(content => this.simulateAiAnalysis(content))
    );
  }

  private simulateAiAnalysis(text: string): AiInsight[] {
    const insights: AiInsight[] = [];
    const lowerText = text.toLowerCase();

    // 1. Look for payment terms (percentages, amounts)
    // Extract any mentions of percentages and their context (up to 40 characters)
    const percentageRegex = /(\d{1,3}%)\s+([^.,:;0-9]{3,40})/gi;
    let match;
    let foundPercentage = false;
    while ((match = percentageRegex.exec(text)) !== null) {
      foundPercentage = true;
      insights.push({
        type: 'payment',
        text: `Payment milestone: ${match[1]} ${match[2].trim()}`,
        confidence: 0.95
      });
    }

    if (!foundPercentage) {
      if (lowerText.includes('40%') || lowerText.includes('au debut') || lowerText.includes('avance')) {
        insights.push({
          type: 'payment',
          text: `Includes upfront payment terms.`,
          confidence: 0.88
        });
      }
    }

    // Money amounts
    const amountMatch = text.match(/(\$|€|£|TND|MAD)\s*\d+(,\d{3})*(\.\d{2})?/i) || text.match(/\d+(,\d{3})*(\.\d{2})?\s*(\$|€|£|TND|MAD|USD|EUR)/i);
    if (amountMatch) {
       insights.push({
         type: 'payment',
         text: `Specific monetary amounts mentioned: ${amountMatch[0]}`,
         confidence: 0.92
       });
    }

    // 2. Look for deadlines
    // Handle 'moins' typo as 'mois'
    const deadlineMatch = text.match(/(\d+)\s*(days|jours|weeks|semaines|months|mois|moins)/i);
    if (deadlineMatch) {
      const unit = deadlineMatch[2].toLowerCase() === 'moins' ? 'mois' : deadlineMatch[2];
      insights.push({
        type: 'deadline',
        text: `Estimated timeframe: ${deadlineMatch[1]} ${unit}.`,
        confidence: 0.90
      });
    }

    // 3. Look for requirements / revisions
    if (lowerText.includes('revision') || lowerText.includes('révision')) {
      insights.push({
        type: 'requirement',
        text: `Contains clauses regarding project revisions.`,
        confidence: 0.85
      });
    }

    if (lowerText.includes('urgent') || lowerText.includes('asap')) {
      insights.push({
        type: 'deadline',
        text: `High priority/Urgent delivery requested.`,
        confidence: 0.98
      });
    }
    
    if (lowerText.includes('tache validée') || lowerText.includes('tâche validée')) {
      insights.push({
        type: 'requirement',
        text: `Payment is tied to task validation/approval.`,
        confidence: 0.95
      });
    }
    
    // If we didn't find much, add some generic AI insights to show the feature works
    if (insights.length === 0) {
      if (text.length > 50) {
        insights.push({
          type: 'general',
          text: `Standard contract terms identified. No specific unusual conditions detected.`,
          confidence: 0.75
        });
      } else {
        insights.push({
          type: 'general',
          text: `Description is brief. Advise requesting more detailed terms.`,
          confidence: 0.80
        });
      }
    }

    return insights;
  }
}
