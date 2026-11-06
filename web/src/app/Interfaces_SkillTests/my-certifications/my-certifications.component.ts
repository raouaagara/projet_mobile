import { Component, OnInit } from '@angular/core';
import { SkillTestService, Certification } from '../../services-ayoub/skill-test.service';

@Component({
  selector: 'app-my-certifications',
  templateUrl: './my-certifications.component.html',
  styleUrl: './my-certifications.component.css'
})
export class MyCertificationsComponent implements OnInit {
  certs: Certification[] = [];
  loading = true;
  currentUserId = 1;  // Mock - integrate with auth

  constructor(private skillTestService: SkillTestService) {}

  ngOnInit(): void {
    this.skillTestService.getUserCertifications(this.currentUserId).subscribe({
      next: (c: Certification[]) => {
        this.certs = c;
        this.loading = false;
      },
      error: () => {
        this.certs = [];
        this.loading = false;
      }
    });
  }

  formatDate(s: string | undefined): string {
    if (!s) return '—';
    try {
      return new Date(s).toLocaleDateString();
    } catch {
      return '—';
    }
  }
}
