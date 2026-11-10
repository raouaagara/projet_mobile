import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { SkillTestService, SkillTest } from '../../services-ayoub/skill-test.service';

@Component({
  selector: 'app-skill-tests-list',
  templateUrl: './skill-tests-list.component.html',
  styleUrl: './skill-tests-list.component.css'
})
export class SkillTestsListComponent implements OnInit {
  categoryFilter = 'ALL';
  selectedCategory = 'Web Development';
  categories = ['Web Development', 'Design', 'Marketing', 'Data Science', 'Mobile Development'];
  tests: SkillTest[] = [];
  loading = false;
  generating = false;
  error = '';
  hasAiAccess = true;
  currentUserId = 1;
  currentUserName = 'Freelancer';

  constructor(
    private skillTestService: SkillTestService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadTests();
    this.loadCategories();
  }

  loadTests(): void {
    this.loading = true;
    this.skillTestService.getTests().subscribe({
      next: (t: SkillTest[]) => {
        this.tests = t;
        this.loading = false;
      },
      error: () => {
        this.tests = [];
        this.loading = false;
      }
    });
  }

  loadCategories(): void {
    this.skillTestService.getCategories().subscribe({
      next: (c: string[]) => { if (c && c.length) this.categories = c; },
      error: () => {}
    });
  }

  get filteredTests(): SkillTest[] {
    if (this.categoryFilter === 'ALL') return this.tests;
    return this.tests.filter(t => t.category === this.categoryFilter);
  }

  generateAiTest(): void {
    if (!this.hasAiAccess) {
      this.error = 'Premium or Enterprise subscription required for AI-generated tests.';
      return;
    }
    this.error = '';
    this.generating = true;
    this.skillTestService.generateAiTest(
      this.currentUserId,
      this.selectedCategory,
      this.hasAiAccess,
      this.currentUserName
    ).subscribe({
      next: (test: SkillTest) => {
        this.generating = false;
        this.router.navigate(['/SkillTestTake', test.id]);
      },
      error: (err: unknown) => {
        this.generating = false;
        const e = err as { error?: { message?: string }; message?: string };
        this.error = e?.error?.message || e?.message || 'Failed to generate test.';
      }
    });
  }

  get questionsCount(): number {
    return 5;  // AI generates 5 questions
  }
}
