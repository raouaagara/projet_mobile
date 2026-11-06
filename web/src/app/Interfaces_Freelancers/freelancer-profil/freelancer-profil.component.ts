import { Component, ElementRef, HostListener, OnInit } from '@angular/core';
import { UserService } from '../../Services/user.service';
import { CompetanceService } from '../../Services/competance.service';
import { ReviewService } from '../../Services/review.service'; 
import { ActivatedRoute, Router } from '@angular/router'; // 🟢 Ajout du Router
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-freelancer-profil',
  templateUrl: './freelancer-profil.component.html',
  styleUrls: ['./freelancer-profil.component.css']
})
export class FreelancerProfilComponent implements OnInit {
  currentTab: string = 'overview'; 

  freelancerId: string = ''; 
  currentViewerId: string = ''; 
  
  freelancerData: any = null;
  freelancerSkills: any[] = []; 
  freelancerReviews: any[] = []; 
  
  isLoading: boolean = true;

  // 🟢 VARIABLES POUR LA RECHERCHE (Dropdown)
  searchText: string = '';
  allUsers: any[] = [];
  filteredUsers: any[] = [];
  showSearchDropdown: boolean = false;

  // Variables pour le Messenger
  isMessagesOpen: boolean = false;
  selectedConversationUserId: string = ''; 

  newReview: any = {
    rating: 5,
    feedback: '' 
  };

  constructor(
    private userService: UserService,
    private competenceService: CompetanceService,
    private reviewService: ReviewService,
    private route: ActivatedRoute,
    private router: Router, // 🟢 Injection du Router
    private eRef: ElementRef,
    private http: HttpClient 
  ) {}

  ngOnInit(): void {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        const payload = token.split('.')[1];
        const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
        this.currentViewerId = String(decodedPayload.id);
      } catch (e) {
        console.error("Erreur lecture token", e);
      }
    }

    // 🟢 On s'abonne aux changements de paramètres d'URL pour que la recherche fonctionne
    // même si on est déjà sur la page profil
    this.route.paramMap.subscribe(params => {
        const urlId = params.get('id');
        this.freelancerId = urlId ? urlId : this.currentViewerId;
        this.loadProfile();
        this.loadReviews();
    });

    this.loadAllUsers(); // 🟢 Charger les utilisateurs pour la recherche
  }

  loadAllUsers() {
    this.userService.getAllUsers().subscribe({
      next: (users) => this.allUsers = users,
      error: (err) => console.error("Erreur chargement utilisateurs", err)
    });
  }

  onGlobalSearch() {
    const query = this.searchText.trim().toLowerCase();
    if (query.length > 0) {
      this.filteredUsers = this.allUsers.filter(u => 
        (u.firstName && u.firstName.toLowerCase().includes(query)) ||
        (u.lastName && u.lastName.toLowerCase().includes(query))
      );
      this.showSearchDropdown = true;
    } else {
      this.showSearchDropdown = false;
    }
  }

  hideSearchDropdown() {
    setTimeout(() => this.showSearchDropdown = false, 200);
  }

  goToProfile(user: any) {
    this.showSearchDropdown = false;
    this.searchText = '';
    const routeName = user.role === 'CLIENT' ? '/ClientProfil' : '/FreelancerProfil';
    this.router.navigate([routeName, user.id]);
  }

  openConversation(event: Event) {
    event.stopPropagation();
    const chatApiUrl = `http://localhost:8085/chat/conversation/create?user1=${this.currentViewerId}&user2=${this.freelancerId}`;
    this.http.post(chatApiUrl, null).subscribe({
      next: (res: any) => {
        this.selectedConversationUserId = this.freelancerId;
        this.isMessagesOpen = true; 
      },
      error: (err: any) => {
        this.selectedConversationUserId = this.freelancerId;
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

  loadReviews() {
    this.reviewService.getReviewsByFreelancer(this.freelancerId).subscribe({
      next: (data) => this.freelancerReviews = data.reverse(),
      error: (err) => console.error("Erreur reviews", err)
    });
  }

  loadProfile() {
    this.isLoading = true;
    this.userService.getUserById(Number(this.freelancerId)).subscribe({
      next: (user) => {
        this.freelancerData = user;
        this.competenceService.getAllCompetances().subscribe({
          next: (skills) => {
            const adminSkills = skills.filter(s => String(s.userId) === '5');
            const userSkillIds = user.competenceIds || [];
            this.freelancerSkills = adminSkills.filter(s => userSkillIds.includes(Number(s.id)));
            this.isLoading = false;
          },
          error: () => this.isLoading = false
        });
      },
      error: (err) => { this.isLoading = false; }
    });
  }

  setTab(tabName: string) { this.currentTab = tabName; }

  get isMyProfile(): boolean { return this.freelancerId === this.currentViewerId; }

  submitReview() {
    if (!this.newReview.feedback.trim()) return;
    const reviewPayload: any = {
      clientId: this.currentViewerId, 
      freelancerId: this.freelancerId, 
      rating: this.newReview.rating,
      description: this.newReview.feedback 
    };
    this.reviewService.addReview(reviewPayload).subscribe({
      next: () => {
        this.newReview.feedback = ''; 
        this.loadReviews();           
      }
    });
  }
}
