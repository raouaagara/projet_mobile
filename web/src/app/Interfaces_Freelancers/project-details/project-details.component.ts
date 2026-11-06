import { Component, OnInit } from '@angular/core';
import { Project } from '../../models/project.model';
import { ActivatedRoute } from '@angular/router';
import { ProjectServiceService } from '../../Services/project-service.service';
import { Proposal } from '../../models/proposal';
import { UserService } from '../../Services/user.service';
import { CompetanceService } from '../../Services/competance.service';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-project-details',
  templateUrl: './project-details.component.html',
  styleUrls: ['./project-details.component.css']
})
export class ProjectDetailsComponent implements OnInit {

  // --- ÉTAT GLOBAL ---
  project: Project | null = null;
  isLoading: boolean = true;
  activeTab: 'job' | 'proposals' | 'reviews' = 'job';
  isSaved: boolean = false;
  currentUrl: string = window.location.href;

  // --- ÉTAT DES OFFRES (PROPOSALS) ---
  proposals: Proposal[] = [];
  lowestBid: number = 0;
  highestBid: number = 0;
  averageBid: number = 0;
  isProposalModalOpen: boolean = false;
  newProposal: Proposal = { bidAmount: 0, estimationEndDate: '', status: 'PENDING', freelancerId: 0 };

  // --- ÉTAT DES REVIEWS & IA ---
  projectReviews: any[] = [];
  showReviewModal: boolean = false;
  reviewText: string = '';
  rating: number = 5;
  isEnhancing: boolean = false;
  isSubmittingReview: boolean = false;

  // ?? Rejection state
  reviewRejectionMsg: string = '';
  reviewWasRejected: boolean = false;

  // --- UTILISATEUR & COMPÉTENCES ---
  currentUser: any = null;
  currentFreelancerId: number | null = null;
  allSkills: any[] = [];
  projectSkills: any[] = [];

  constructor(
    private route: ActivatedRoute,
    private projectService: ProjectServiceService,
    private userService: UserService,
    private competenceService: CompetanceService,
    private http: HttpClient
  ) { }

  ngOnInit(): void {
    this.loadUserData();

    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      const projectId = Number(idParam);

      this.competenceService.getAllCompetances().subscribe({
        next: (skills) => {
          this.allSkills = skills;
          this.resolveProjectSkills();
        }
      });

      this.projectService.getProjectById(projectId).subscribe({
        next: (data) => {
          this.project = data;
          this.resolveProjectSkills();
          this.checkIfSaved();
          this.fetchProjectReviews(projectId);
          this.loadProposals(projectId);
          this.isLoading = false;
        },
        error: (err) => { console.error(err); this.isLoading = false; }
      });
    } else {
      this.isLoading = false;
    }
  }

  // --- MÉTHODES GLOBALES ---
  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        const payload = JSON.parse(window.atob(token.split('.')[1]));
        this.currentFreelancerId = payload.id;

        this.userService.getUserById(this.currentFreelancerId!).subscribe({
          next: (user) => {
            this.currentUser = user;
            this.checkIfSaved();
          }
        });
      } catch (e) { console.error("Erreur Auth", e); }
    }
  }

  resolveProjectSkills() {
    if (this.project && this.allSkills.length > 0 && this.project.requiredCompetenceIds) {
      this.projectSkills = this.allSkills.filter(skill =>
        this.project!.requiredCompetenceIds!.includes(skill.id)
      );
    }
  }

  setTab(tab: 'job' | 'proposals' | 'reviews') {
    this.activeTab = tab;
  }

  // --- LOGIQUE DES PROPOSALS ---
  loadProposals(projectId: number) {
    this.projectService.getProposalsForProject(projectId).subscribe({
      next: (data) => {
        this.proposals = data.reverse();
        this.calculateBidStats();
      }
    });
  }

  calculateBidStats() {
    if (this.proposals.length === 0) return;
    const bids = this.proposals.map(p => p.bidAmount);
    this.lowestBid = Math.min(...bids);
    this.highestBid = Math.max(...bids);
    this.averageBid = Math.round(bids.reduce((a, b) => a + b, 0) / bids.length);
  }

  get hasAlreadyApplied(): boolean {
    if (!this.currentFreelancerId) return false;
    return this.proposals.some(p => p.freelancerId === this.currentFreelancerId);
  }

  submitProposal() {
    if (!this.project?.id || !this.newProposal.bidAmount || !this.newProposal.estimationEndDate) {
      this.showToast("Please fill all fields, including the delivery date.", "error");
      return;
    }
    this.projectService.submitProposal(this.project.id, this.newProposal).subscribe({
      next: () => {
        this.showToast("Proposal submitted successfully! ??", "success");
        this.closeModal();
        this.loadProposals(this.project!.id!);
        this.activeTab = 'proposals';
      },
      error: () => this.showToast("Error submitting your proposal. Please try again.", "error")
    });
  }

  // --- CUSTOM TOAST NOTIFICATIONS ---
  toastMessage: string = '';
  toastType: 'success' | 'error' | '' = '';
  
  showToast(msg: string, type: 'success' | 'error') {
    this.toastMessage = msg;
    this.toastType = type;
    setTimeout(() => {
      if (this.toastMessage === msg) {
        this.toastMessage = '';
      }
    }, 4000);
  }

  // --- CUSTOM DATE PICKER LOGIC ---
  showDatePicker = false;
  currentDate = new Date();
  selectedDate: Date | null = null;
  calendarWeeks: any[][] = [];
  months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  toggleDatePicker() {
    this.showDatePicker = !this.showDatePicker;
    if (this.showDatePicker) {
      if (this.selectedDate) {
        this.currentDate = new Date(this.selectedDate);
      } else {
        this.currentDate = new Date();
      }
      this.generateCalendar();
    }
  }

  generateCalendar() {
    const year = this.currentDate.getFullYear();
    const month = this.currentDate.getMonth();
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    
    let date = 1;
    this.calendarWeeks = [];
    for (let i = 0; i < 6; i++) {
      let week = [];
      let hasDays = false;
      for (let j = 0; j < 7; j++) {
        if (i === 0 && j < firstDay) {
          week.push(null);
        } else if (date > daysInMonth) {
          week.push(null);
        } else {
          week.push(new Date(year, month, date));
          date++;
          hasDays = true;
        }
      }
      if (hasDays) {
        this.calendarWeeks.push(week);
      }
    }
  }

  prevMonth(event: Event) {
    event.stopPropagation();
    this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() - 1, 1);
    this.generateCalendar();
  }

  nextMonth(event: Event) {
    event.stopPropagation();
    this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 1);
    this.generateCalendar();
  }

  selectDate(d: Date, event: Event) {
    event.stopPropagation();
    this.selectedDate = d;
    const pad = (n: number) => n < 10 ? '0' + n : n;
    this.newProposal.estimationEndDate = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
    this.showDatePicker = false;
  }

  isSameDate(d1: Date, d2: Date | null): boolean {
    if (!d1 || !d2) return false;
    return d1.getFullYear() === d2.getFullYear() && 
           d1.getMonth() === d2.getMonth() && 
           d1.getDate() === d2.getDate();
  }

  // --- LOGIQUE DES REVIEWS & IA GEMINI ---
  fetchProjectReviews(projectId: number) {
    this.http.get<any[]>(`http://localhost:8085/Review/GetReviewsByProject/${projectId}`)
      .subscribe(res => this.projectReviews = res);
  }

  enhanceWithAI() {
    if (!this.reviewText) return;
    this.isEnhancing = true;

    // Clear rejection state when user tries to improve
    this.reviewRejectionMsg = '';
    this.reviewWasRejected = false;

    this.http.post<any>('http://localhost:8085/Review/enhance', { text: this.reviewText, rating: this.rating })
      .subscribe({
        next: (res) => {
          this.reviewText = res.enhancedText;
          this.isEnhancing = false;
        },
        error: () => {
          this.showToast("Erreur avec l'IA. Réessayez.", "error");
          this.isEnhancing = false;
        }
      });
  }

  submitReview() {
    if (!this.reviewText || this.isSubmittingReview) return;

    this.isSubmittingReview = true;

    // Clear previous rejection state
    this.reviewRejectionMsg = '';
    this.reviewWasRejected = false;

    const reviewData = {
      description: this.reviewText,
      rating: this.rating,
      projectId: this.project?.id,
      clientId: this.project?.clientId,
      freelancerId: this.currentFreelancerId,
      reviewerRole: 'FREELANCER',
      createdAt: new Date().toISOString()
    };

    this.http.post('http://localhost:8085/Review/AjouterReview', reviewData).subscribe({
      next: () => {
        this.isSubmittingReview = false;
        this.reviewRejectionMsg = '';
        this.reviewWasRejected = false;
        this.fetchProjectReviews(this.project!.id!);
        this.closeReviewModal();
        this.activeTab = 'reviews';
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

  // --- GESTION DES MODALS ET BOUTONS ---
  openModal() {
    if (!this.currentFreelancerId) return this.showToast("Vous devez être connecté.", "error");
    this.newProposal.freelancerId = this.currentFreelancerId;
    this.isProposalModalOpen = true;
    document.body.style.overflow = 'hidden';
  }

  closeModal() {
    this.isProposalModalOpen = false;
    document.body.style.overflow = 'auto';
  }

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

  checkIfSaved() {
    if (this.currentUser && this.project?.id) {
      const savedStr = localStorage.getItem(`saved_jobs_${this.currentUser.id}`);
      if (savedStr) {
        const savedArr: any[] = JSON.parse(savedStr);
        this.isSaved = savedArr.some(p => p.id === this.project!.id);
      }
    }
  }

  toggleSave() {
    if (!this.currentUser || !this.project) return;
    this.isSaved = !this.isSaved;
    let savedArr: Project[] = [];
    const savedStr = localStorage.getItem(`saved_jobs_${this.currentUser.id}`);
    if (savedStr) savedArr = JSON.parse(savedStr);

    if (this.isSaved) {
      if (!savedArr.some(p => p.id === this.project!.id)) savedArr.push(this.project);
    } else {
      savedArr = savedArr.filter(p => p.id !== this.project!.id);
    }
    localStorage.setItem(`saved_jobs_${this.currentUser.id}`, JSON.stringify(savedArr));
  }

  formatEnumText(value: string | undefined): string {
    if (!value) return 'General';
    return value.replace(/_/g, ' ').replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substring(1).toLowerCase());
  }

  copyLink() {
    navigator.clipboard.writeText(this.currentUrl);
    this.showToast("Lien copié ! ??", "success");
  }
}
