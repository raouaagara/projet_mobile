import { Component, OnInit } from '@angular/core';
import { SkillTestService, SkillTest, Question } from '../../services-ayoub/skill-test.service';

@Component({
  selector: 'app-admin-skill-tests',
  templateUrl: './admin-skill-tests.component.html',
  styleUrl: './admin-skill-tests.component.css'
})
export class AdminSkillTestsComponent implements OnInit {
  tests: SkillTest[] = [];
  loading = true;
  loadError = false;
  
  // Filters
  categoryFilter = 'ALL';
  statusFilter = 'ALL';
  searchQuery = '';
  
  // Pagination
  currentPage = 1;
  pageSize = 10;
  
  // Modal states
  showCreateModal = false;
  showEditModal = false;
  showDeleteModal = false;
  showQuestionsModal = false;
  showStatisticsModal = false;
  
  // Current test being edited/deleted
  selectedTest: SkillTest | null = null;
  testQuestions: Question[] = [];
  testStatistics: any = null;
  
  // Form data for create/edit
  testForm: Partial<SkillTest> = {
    title: '',
    description: '',
    category: '',
    durationMinutes: 30,
    passScore: 70,
    active: true,
    scheduledStartDate: undefined,
    expiryDate: undefined
  };
  
  // Question form
  questionForm: Partial<Question> = {
    questionText: '',
    optionA: '',
    optionB: '',
    optionC: '',
    optionD: '',
    correctOption: 'A'
  };
  
  showAddQuestionForm = false;
  editingQuestionId: number | null = null;
  Math = Math;

  constructor(private skillTestService: SkillTestService) {}

  ngOnInit(): void {
    this.loadTests();
  }

  loadTests(): void {
    this.loading = true;
    this.loadError = false;
    this.skillTestService.getAllTestsAdmin().subscribe({
      next: (tests) => {
        this.tests = tests;
        this.loading = false;
      },
      error: () => {
        this.loadError = true;
        this.loading = false;
      }
    });
  }

  get filteredTests(): SkillTest[] {
    return this.tests.filter(test => {
      const matchesCategory = this.categoryFilter === 'ALL' || test.category === this.categoryFilter;
      const matchesStatus = this.statusFilter === 'ALL' || 
        (this.statusFilter === 'ACTIVE' && test.active) ||
        (this.statusFilter === 'INACTIVE' && !test.active);
      const matchesSearch = !this.searchQuery || 
        test.title.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
        test.description?.toLowerCase().includes(this.searchQuery.toLowerCase());
      
      return matchesCategory && matchesStatus && matchesSearch;
    });
  }

  get paginatedTests(): SkillTest[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.filteredTests.slice(start, start + this.pageSize);
  }

  get totalPages(): number {
    return Math.ceil(this.filteredTests.length / this.pageSize);
  }

  get categories(): string[] {
    return [...new Set(this.tests.map(t => t.category))];
  }

  // Create Test
  openCreateModal(): void {
    this.testForm = {
      title: '',
      description: '',
      category: '',
      durationMinutes: 30,
      passScore: 70,
      active: true,
      scheduledStartDate: undefined,
      expiryDate: undefined
    };
    this.showCreateModal = true;
  }

  createTest(): void {
    if (!this.testForm.title || !this.testForm.category) {
      alert('Please fill in all required fields');
      return;
    }

    this.skillTestService.createTest(this.testForm as SkillTest).subscribe({
      next: () => {
        this.showCreateModal = false;
        this.loadTests();
      },
      error: (err) => {
        alert('Failed to create test: ' + err.message);
      }
    });
  }

  // Edit Test
  openEditModal(test: SkillTest): void {
    this.selectedTest = test;
    this.testForm = { ...test };
    this.showEditModal = true;
  }

  updateTest(): void {
    if (!this.selectedTest || !this.testForm.title) return;

    this.skillTestService.updateTest(this.selectedTest.id!, this.testForm as SkillTest).subscribe({
      next: () => {
        this.showEditModal = false;
        this.loadTests();
      },
      error: (err) => {
        alert('Failed to update test: ' + err.message);
      }
    });
  }

  // Delete Test
  openDeleteModal(test: SkillTest): void {
    this.selectedTest = test;
    this.showDeleteModal = true;
  }

  deleteTest(): void {
    if (!this.selectedTest) return;

    this.skillTestService.deleteTest(this.selectedTest.id!).subscribe({
      next: () => {
        this.showDeleteModal = false;
        this.loadTests();
      },
      error: (err) => {
        alert('Failed to delete test: ' + err.message);
      }
    });
  }

  // Manage Questions
  openQuestionsModal(test: SkillTest): void {
    this.selectedTest = test;
    this.showQuestionsModal = true;
    this.loadQuestions(test.id!);
  }

  loadQuestions(testId: number): void {
    this.skillTestService.getTestQuestions(testId).subscribe({
      next: (questions) => {
        this.testQuestions = questions;
      },
      error: () => {
        this.testQuestions = [];
      }
    });
  }

  openAddQuestionForm(): void {
    this.questionForm = {
      questionText: '',
      optionA: '',
      optionB: '',
      optionC: '',
      optionD: '',
      correctOption: 'A'
    };
    this.editingQuestionId = null;
    this.showAddQuestionForm = true;
  }

  saveQuestion(): void {
    if (!this.selectedTest || !this.questionForm.questionText) return;

    if (this.editingQuestionId) {
      // Update existing question
      this.skillTestService.updateQuestion(this.editingQuestionId, this.questionForm as Question).subscribe({
        next: () => {
          this.showAddQuestionForm = false;
          this.loadQuestions(this.selectedTest!.id!);
        },
        error: (err) => alert('Failed to update question: ' + err.message)
      });
    } else {
      // Create new question
      this.skillTestService.createQuestion(this.selectedTest.id!, this.questionForm as Question).subscribe({
        next: () => {
          this.showAddQuestionForm = false;
          this.loadQuestions(this.selectedTest!.id!);
        },
        error: (err) => alert('Failed to create question: ' + err.message)
      });
    }
  }

  editQuestion(question: Question): void {
    this.questionForm = { ...question };
    this.editingQuestionId = question.id!;
    this.showAddQuestionForm = true;
  }

  deleteQuestion(questionId: number): void {
    if (!confirm('Delete this question?')) return;

    this.skillTestService.deleteQuestion(questionId).subscribe({
      next: () => {
        this.loadQuestions(this.selectedTest!.id!);
      },
      error: (err) => alert('Failed to delete question: ' + err.message)
    });
  }

  closeModal(): void {
    this.showCreateModal = false;
    this.showEditModal = false;
    this.showDeleteModal = false;
    this.showQuestionsModal = false;
    this.showStatisticsModal = false;
    this.showAddQuestionForm = false;
    this.selectedTest = null;
  }

  // Statistics Modal
  openStatisticsModal(test: SkillTest): void {
    this.selectedTest = test;
    this.showStatisticsModal = true;
    this.loadStatistics(test.id!);
  }

  loadStatistics(testId: number): void {
    this.skillTestService.getTestStatistics(testId).subscribe({
      next: (stats) => {
        this.testStatistics = stats;
      },
      error: () => {
        this.testStatistics = null;
      }
    });
  }

  goToPage(page: number): void {
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
    }
  }
}
