import { Component, ElementRef, HostListener, OnInit } from '@angular/core';
import { UserService } from '../../Services/user.service';
import { ActivatedRoute, Router } from '@angular/router'; 
import { HttpClient } from '@angular/common/http'; // 🟢 Ajout pour le chat
import { ReviewService } from '../../Services/review.service'; // 🟢 Ajout pour les avis

@Component({
  selector: 'app-client-profile',
  templateUrl: './client-profile.component.html',
  styleUrls: ['./client-profile.component.css'] 
})
export class ClientProfileComponent implements OnInit {

  currentTab: string = 'about'; 
  
  clientId: string = ''; 
  currentViewerId: string = ''; 
  clientProfile: any = null;

  clientReviews: any[] = [];
  newReview: any = {
    rating: 5,
    description: '' 
  };

  isMessagesOpen: boolean = false;
  selectedConversationUserId: string = ''; 

  searchText: string = '';
  allFreelancers: any[] = [];
  filteredFreelancers: any[] = [];
  showFreelancerDropdown: boolean = false;

  constructor(
    private userService: UserService,
    private reviewService: ReviewService,
    private route: ActivatedRoute,
    private router: Router,
    private http: HttpClient,
    private eRef: ElementRef
  ) {}



  isGenerating: boolean = false;

enhanceWithAI() {
  if (!this.newReview.description || this.newReview.description.length < 5) {
    alert("Please write a small draft first!");
    return;
  }

  this.isGenerating = true;
  
  const payload = {
    text: this.newReview.description,
    rating: this.newReview.rating
  };

  this.http.post('http://localhost:8085/Review/enhance', payload).subscribe({
    next: (res: any) => {
      this.newReview.description = res.enhancedText;
      this.isGenerating = false;
    },
    error: (err) => {
      console.error("Backend error:", err);
      this.isGenerating = false;
    }
  });
}
  ngOnInit(): void {
    // 1. Qui regarde le profil ?
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        const payload = token.split('.')[1];
        const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
        this.currentViewerId = String(decodedPayload.id);
      } catch (e) {
        console.error("🔴 Erreur Token :", e);
      }
    }

    // 2. De qui regarde-t-on le profil ?
    const urlId = this.route.snapshot.paramMap.get('id');
    if (urlId) {
      this.clientId = urlId;
    } else {
      this.clientId = this.currentViewerId;
    }

    this.fetchUser(Number(this.clientId));
    this.loadReviews();
    this.loadAllFreelancers(); 
  }

  // ==========================================
  // 🟢 GESTION DES REVIEWS (AVIS)
  // ==========================================
  loadReviews() {
    this.reviewService.getReviewsByClient(this.clientId).subscribe({
      next: (data) => {
        this.clientReviews = data.reverse(); 
      },
      error: (err) => console.error("Erreur chargement des avis :", err)
    });
  }

  submitReview() {
    if (!this.newReview.description.trim()) {
      alert("Please write a feedback.");
      return;
    }

    const reviewPayload: any = {
      clientId: this.clientId,           // Le profil qu'on commente
      freelancerId: this.currentViewerId, // Celui qui laisse le commentaire
      rating: this.newReview.rating,
      description: this.newReview.description 
    };

    this.reviewService.addReview(reviewPayload).subscribe({
      next: (response) => {
        alert("Review submitted successfully! 🎉");
        this.newReview.description = ''; 
        this.newReview.rating = 5;    
        this.loadReviews();           
      },
      error: (err) => {
        console.error("Erreur envoi review :", err);
        alert("Server error while submitting review.");
      }
    });
  }

  // ==========================================
  // 🟢 GESTION DU CHAT (MESSENGER)
  // ==========================================
  openConversation(event: Event) {
    event.stopPropagation();
    
    // Création de la conversation en base de données
    const chatApiUrl = `http://localhost:8085/chat/conversation/create?user1=${this.currentViewerId}&user2=${this.clientId}`;

    this.http.post(chatApiUrl, null).subscribe({
      next: (res: any) => {
        this.selectedConversationUserId = this.clientId;
        this.isMessagesOpen = true; 
      },
      error: (err: any) => {
        console.error("Erreur création conversation", err);
        this.selectedConversationUserId = this.clientId;
        this.isMessagesOpen = true; 
      }
    });
  }

  @HostListener('document:click', ['$event'])
  clickout(event: any) {
    if (this.isMessagesOpen && !this.eRef.nativeElement.querySelector('.messenger-wrapper')?.contains(event.target)) {
      this.isMessagesOpen = false;
    }
  }

  // ==========================================
  // AUTRES MÉTHODES EXISTANTES
  // ==========================================
  get isMyProfile(): boolean {
    return this.clientId === this.currentViewerId;
  }

  fetchUser(id: number) {
    this.userService.getUserById(id).subscribe({
      next: (user) => this.clientProfile = user,
      error: (err: any) => console.error("🔴 Erreur chargement profil :", err)
    });
  }

  setTab(tabName: string) {
    this.currentTab = tabName;
  }

  loadAllFreelancers() {
    this.userService.getAllUsers().subscribe({
      next: (users: any[]) => this.allFreelancers = users.filter(u => u.role === 'FREELANCER'),
      error: (err: any) => console.error("Erreur freelancers", err)
    });
  }

  onGlobalSearch() {
    const query = this.searchText.trim().toLowerCase();
    if (query.length > 0) {
      this.filteredFreelancers = this.allFreelancers.filter(f => 
        (f.firstName && f.firstName.toLowerCase().includes(query)) ||
        (f.lastName && f.lastName.toLowerCase().includes(query)) ||
        (f.bio && f.bio.toLowerCase().includes(query))
      );
      this.showFreelancerDropdown = true;
    } else {
      this.showFreelancerDropdown = false;
    }
  }

  hideFreelancerDropdown() {
    setTimeout(() => this.showFreelancerDropdown = false, 200);
  }

  goToFreelancerProfile(freelancerId: number) {
    this.router.navigate(['/FreelancerProfil', freelancerId]);
  }
}
