import { Component, OnInit } from '@angular/core';
import { SkillTestService, Certification } from '../../services-ayoub/skill-test.service';

@Component({
  selector: 'app-admin-certifications',
  templateUrl: './admin-certifications.component.html',
  styleUrl: './admin-certifications.component.css'
})
export class AdminCertificationsComponent implements OnInit {
  certifications: Certification[] = [];
  statsByCategory: Record<string, number> = {};
  loading = true;
  filterPassedOnly = false;
  categoryFilter = 'ALL';
  loadError = false;
  currentPage = 1;
  pageSize = 10;
  pageSizeOptions = [5, 10, 25, 50];

  constructor(private skillTestService: SkillTestService) {}

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    this.loading = true;
    this.loadError = false;
    this.skillTestService.getAllCertifications().subscribe({
      next: (c: Certification[]) => {
        this.certifications = Array.isArray(c) ? c : [];
        this.loading = false;
      },
      error: () => {
        this.certifications = [];
        this.loading = false;
        this.loadError = true;
      }
    });
    this.skillTestService.getStatsByCategory().subscribe({
      next: (s: Record<string, number>) => {
        this.statsByCategory = s && typeof s === 'object' ? s : {};
      },
      error: () => {
        this.statsByCategory = {};
      }
    });
  }

  get displayCerts(): Certification[] {
    if (!Array.isArray(this.certifications)) return [];
    let list = this.filterPassedOnly ? this.certifications.filter(c => c && c.passed) : this.certifications;
    if (this.categoryFilter !== 'ALL') {
      list = list.filter(c => c && c.category === this.categoryFilter);
    }
    return list;
  }

  get categories(): string[] {
    if (!Array.isArray(this.certifications)) return [];
    const cats = this.certifications.map(c => c?.category).filter(Boolean) as string[];
    return [...new Set(cats)];
  }

  formatDate(s: string | undefined): string {
    if (!s) return '—';
    try {
      const d = new Date(s);
      return isNaN(d.getTime()) ? '—' : d.toLocaleDateString();
    } catch {
      return '—';
    }
  }

  safeChar(str: string | undefined, fallback: string): string {
    if (!str) return fallback.charAt(0);
    return str.charAt(0) || fallback.charAt(0);
  }

  get hasStats(): boolean {
    return this.statsByCategory != null && Object.keys(this.statsByCategory).length > 0;
  }

  get paginatedCerts(): Certification[] {
    const list = this.displayCerts;
    const start = (this.currentPage - 1) * this.pageSize;
    return list.slice(start, start + this.pageSize);
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.displayCerts.length / this.pageSize));
  }

  goToPage(p: number): void {
    if (p >= 1 && p <= this.totalPages) this.currentPage = p;
  }

  onPageSizeChange(): void {
    this.currentPage = 1;
  }

  get pageNumbers(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i + 1);
  }

  paginationEnd(): number {
    return Math.min(this.currentPage * this.pageSize, this.displayCerts.length);
  }

  paginationStart(): number {
    return this.displayCerts.length === 0 ? 0 : (this.currentPage - 1) * this.pageSize + 1;
  }
}
