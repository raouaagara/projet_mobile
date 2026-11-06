import { Component } from '@angular/core';

interface Freelancer {
  rank: number;
  name: string;
  role: string;
  score: number;
  avatar: string;
  isTop3?: boolean;
}

@Component({
  selector: 'app-leaderboard-freelancer',
  templateUrl: './leaderboard-freelancer.component.html',
  styleUrl: './leaderboard-freelancer.component.css'
})
export class LeaderboardFreelancerComponent {

  topFreelancers: Freelancer[] = [
    { rank: 1, name: 'Sarah Jenkins', role: 'Senior Angular Dev', score: 99.8, avatar: 'https://placehold.co/100x100/f59e0b/ffffff?text=SJ', isTop3: true },
    { rank: 2, name: 'David Kim', role: 'Full Stack Engineer', score: 98.5, avatar: 'https://placehold.co/100x100/94a3b8/ffffff?text=DK', isTop3: true },
    { rank: 3, name: 'Elena Lou', role: 'UI/UX Designer', score: 97.2, avatar: 'https://placehold.co/100x100/b45309/ffffff?text=EL', isTop3: true },
    { rank: 4, name: 'Michael Chen', role: 'Backend (Node.js)', score: 96.0, avatar: 'https://placehold.co/60x60/198754/ffffff?text=MC' },
    { rank: 5, name: 'Jessica Blue', role: 'Mobile Dev (Flutter)', score: 95.4, avatar: 'https://placehold.co/60x60/3b82f6/ffffff?text=JB' },
    { rank: 6, name: 'Tom Hardy', role: 'DevOps Engineer', score: 94.1, avatar: 'https://placehold.co/60x60/6366f1/ffffff?text=TH' },
    { rank: 7, name: 'Alice Smith', role: 'React Developer', score: 93.8, avatar: 'https://placehold.co/60x60/ec4899/ffffff?text=AS' },
    { rank: 8, name: 'Bob Martin', role: 'Data Scientist', score: 92.5, avatar: 'https://placehold.co/60x60/14b8a6/ffffff?text=BM' },
    { rank: 9, name: 'Chris Evans', role: 'QA Engineer', score: 91.0, avatar: 'https://placehold.co/60x60/f97316/ffffff?text=CE' },
    { rank: 10, name: 'Diana Prince', role: 'Project Manager', score: 90.5, avatar: 'https://placehold.co/60x60/8b5cf6/ffffff?text=DP' },
    // Below Top 10 (Restricted Access)
    { rank: 11, name: 'Ethan Hunt', role: 'Security Analyst', score: 89.2, avatar: 'https://placehold.co/60x60/64748b/ffffff?text=EH' },
    { rank: 12, name: 'Fiona Gallagher', role: 'Content Writer', score: 88.0, avatar: 'https://placehold.co/60x60/64748b/ffffff?text=FG' },
    { rank: 13, name: 'George RR', role: 'Copywriter', score: 87.5, avatar: 'https://placehold.co/60x60/64748b/ffffff?text=GR' },
    { rank: 14, name: 'Harry Potter', role: 'Magical Dev', score: 86.1, avatar: 'https://placehold.co/60x60/64748b/ffffff?text=HP' },
    { rank: 15, name: 'Ian McKellen', role: 'Legacy Code Wizard', score: 85.0, avatar: 'https://placehold.co/60x60/64748b/ffffff?text=IM' },
  ];

  get listFreelancers() {
    return this.topFreelancers.filter(f => f.rank > 3);
  }

}
