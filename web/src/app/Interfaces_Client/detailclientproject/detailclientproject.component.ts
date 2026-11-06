import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { Project } from '../../models/project.model';
import { ProjectServiceService } from '../../Services/project-service.service';
import { CompetanceService } from '../../Services/competance.service';

@Component({
  selector: 'app-detailclientproject',
  templateUrl: './detailclientproject.component.html',
  styleUrls: ['./detailclientproject.component.css']
})
export class DetailclientprojectComponent implements OnInit {

  // --- GLOBAL STATE ---
  currentTab: string = 'details';
  project!: Project;
  isLoading: boolean = true;
  allSkills: any[] = [];
  projectSkills: any[] = [];
  currentUrl: string = window.location.href;

  // --- REVIEWS LIST ---
  projectReviews: any[] = [];

  // --- OWNERSHIP & USER ---
  currentUserId: number | null = null;
  isOwner: boolean = false;

  // --- REVIEW MODAL STATE ---
  showReviewModal: boolean = false;
  reviewText: string = '';
  rating: number = 5;
  isEnhancing: boolean = false;
  isSubmittingReview: boolean = false;

  // ?? Rejection state (same as freelancer view)
  reviewRejectionMsg: string = '';
  reviewWasRejected: boolean = false;

  constructor(
    private route: ActivatedRoute,
    private projectService: ProjectServiceService,
    private competenceService: CompetanceService,
    private http: HttpClient
  ) {}

  ngOnInit(): void {
    this.loadCurrentUser();
    const idParam = this.route.snapshot.paramMap.get('id');

    if (idParam) {
      const projectId = Number(idParam);

      // Load Skills
      this.competenceService.getAllCompetances().subscribe(skills => {
        this.allSkills = skills;
        this.resolveProjectSkills();
      });

      // Load Project
      this.projectService.getProjectById(projectId).subscribe({
        next: (data) => {
          this.project = data;
          this.checkOwnership();
          this.resolveProjectSkills();
          this.fetchProjectReviews();
          this.isLoading = false;
        },
        error: () => this.isLoading = false
      });
    }
  }

  // --- USER & OWNERSHIP ---
  loadCurrentUser() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        const parsed = JSON.parse(storedData);
        const token = parsed.token || storedData;
        const payload = JSON.parse(window.atob(token.split('.')[1]));
        this.currentUserId = payload.id;
      } catch (e) { console.error(e); }
    }
  }

  checkOwnership() {
    if (this.project && this.currentUserId) {
      this.isOwner = Number(this.project.clientId) === Number(this.currentUserId);
    }
  }

  resolveProjectSkills() {
    if (this.project?.requiredCompetenceIds && this.allSkills.length > 0) {
      this.projectSkills = this.allSkills.filter(s =>
        this.project.requiredCompetenceIds!.includes(s.id)
      );
    }
  }

  setTab(tab: string) { this.currentTab = tab; }

  // --- REVIEWS ---
  fetchProjectReviews() {
    this.http.get<any[]>(`http://localhost:8085/Review/GetReviewsByProject/${this.project.id}`)
      .subscribe(res => this.projectReviews = res);
  }

  // --- REVIEW MODAL ---
  openReviewModal() {
    this.showReviewModal = true;
    document.body.style.overflow = 'hidden';
  }

  closeReviewModal() {
    this.showReviewModal = false;
    this.reviewText = '';
    this.rating = 5;
    this.reviewRejectionMsg = '';   // ? clear rejection on close
    this.reviewWasRejected = false;
    document.body.style.overflow = 'auto';
  }

  // --- AI ENHANCE ---
  enhanceWithAI() {
    if (!this.reviewText) return;
    this.isEnhancing = true;

    // Clear rejection state when user tries to improve
    this.reviewRejectionMsg = '';
    this.reviewWasRejected = false;

    this.http.post<any>('http://localhost:8085/Review/enhance', {
      text: this.reviewText,
      rating: this.rating
    }).subscribe({
      next: (res) => {
        this.reviewText = res.enhancedText;
        this.isEnhancing = false;
      },
      error: () => {
        alert("Erreur avec l'IA. Réessayez.");
        this.isEnhancing = false;
      }
    });
  }

  // --- SUBMIT REVIEW ---
  submitReview() {
    if (!this.reviewText || this.isSubmittingReview) return;

    this.isSubmittingReview = true;

    // Clear previous rejection state
    this.reviewRejectionMsg = '';
    this.reviewWasRejected = false;

    const reviewData = {
      description: this.reviewText,
      rating: this.rating,
      projectId: this.project.id,
      clientId: this.currentUserId?.toString(),
      freelancerId: null,
      reviewerRole: 'CLIENT',
      createdAt: new Date().toISOString()
    };

    this.http.post('http://localhost:8085/Review/AjouterReview', reviewData).subscribe({
      next: () => {
        this.isSubmittingReview = false;
        this.reviewRejectionMsg = '';
        this.reviewWasRejected = false;
        this.fetchProjectReviews();
        this.closeReviewModal();
        this.currentTab = 'reviews';
      },
      error: (err) => {
        this.isSubmittingReview = false;

        // ?? Keep modal open — show rejection banner instead of alert
        let rawMsg =
          err.error?.reason ||
          err.error?.message ||
          err.error?.error ||
          'Your review contains inappropriate content.';

        // Strip "REJECTED: " prefix if present (sent from backend)
        rawMsg = rawMsg.replace(/^REJECTED:\s*/i, '').trim();

        this.reviewRejectionMsg = rawMsg;
        this.reviewWasRejected = true;
      }
    });
  }

  // --- UTILS ---
  copyLink() {
    navigator.clipboard.writeText(this.currentUrl);
    alert('Link copied! ??');
  }

  formatEnumText(value: string | undefined): string {
    if (!value) return 'General';
    return value.replace(/_/g, ' ').replace(/\w\S*/g, (txt) =>
      txt.charAt(0).toUpperCase() + txt.substring(1).toLowerCase()
    );
  }

  getStarArray(count: number): number[] {
    return Array.from({ length: count }, (_, i) => i + 1);
  }

  getAverageRating(): number {
    if (this.projectReviews.length === 0) return 0;
    const sum = this.projectReviews.reduce((acc, r) => acc + r.rating, 0);
    return Math.round((sum / this.projectReviews.length) * 10) / 10;
  }
}
