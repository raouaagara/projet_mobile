import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { SkillTestService, SkillTest, Question, Certification } from '../../services-ayoub/skill-test.service';

@Component({
  selector: 'app-skill-test-take',
  templateUrl: './skill-test-take.component.html',
  styleUrl: './skill-test-take.component.css'
})
export class SkillTestTakeComponent implements OnInit {
  testId = 0;
  testTitle = '';
  currentIndex = 0;
  answers: Record<number, string> = {};
  questions: Question[] = [];
  loading = true;
  submitting = false;
  currentUserId = 1;   // Mock - integrate with auth
  currentUserName = 'Freelancer';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private skillTestService: SkillTestService
  ) {}

  ngOnInit(): void {
    this.testId = +this.route.snapshot.paramMap.get('id')!;
    this.loadTestAndQuestions();
  }

  loadTestAndQuestions(): void {
    this.loading = true;
    this.skillTestService.getTest(this.testId).subscribe({
      next: (test: SkillTest) => {
        this.testTitle = test.title;
        this.skillTestService.getQuestions(this.testId).subscribe({
          next: (q: Question[]) => {
            this.questions = q;
            this.loading = false;
          },
          error: () => {
            this.questions = [];
            this.loading = false;
          }
        });
      },
      error: () => {
        this.testTitle = 'Skill Test';
        this.questions = [];
        this.loading = false;
      }
    });
  }

  selectAnswer(qId: number, option: string): void {
    this.answers[qId] = option;
  }

  next(): void {
    if (this.currentIndex < this.questions.length - 1) this.currentIndex++;
  }

  prev(): void {
    if (this.currentIndex > 0) this.currentIndex--;
  }

  submit(): void {
    if (this.questions.length === 0) return;
    this.submitting = true;
    this.skillTestService.submitTest(
      this.currentUserId,
      this.testId,
      this.answers,
      this.currentUserName
    ).subscribe({
      next: (cert: Certification) => {
        this.submitting = false;
        this.router.navigate(['/SkillTestResult', this.testId], {
          queryParams: { score: cert.score, passed: cert.passed, title: this.testTitle }
        });
      },
      error: () => {
        this.submitting = false;
      }
    });
  }

  get progress(): number {
    return this.questions.length ? ((this.currentIndex + 1) / this.questions.length) * 100 : 0;
  }
}
