import { Component, ElementRef, HostListener, OnInit, OnDestroy } from '@angular/core';
import { Project } from '../../models/project.model';
import { ProjectServiceService } from '../../Services/project-service.service';
import { UserService } from '../../Services/user.service';
import { Router } from '@angular/router'; 
import { NotificationService } from '../../Services/notification.service'; 

@Component({
  selector: 'app-freelancer-feed',
  templateUrl: './freelancer-feed.component.html',
  styleUrls: ['./freelancer-feed.component.css']
})
export class FreelancerFeedComponent implements OnInit, OnDestroy {
  
  isMessagesOpen: boolean = false;
  allProjects: Project[] = [];
  filteredProjects: Project[] = [];
  savedProjects: Project[] = [];
  currentUser: any = null;
  clientDetailsMap: { [key: number]: any } = {};

  searchText: string = '';
  sortBy: string = 'Best Match'; 
  selectedBudget: string = 'Any';

  notifications: any[] = [];
  unreadCount: number = 0;
  isNotifOpen: boolean = false;
  previousUnreadCount: number = -1;
  notifInterval: any;

  categories = [
    { label: 'Web Development', value: 'WEB_DEVELOPMENT', selected: false },
    { label: 'Mobile Apps', value: 'MOBILE_DEVELOPMENT', selected: false },
    { label: 'UI/UX Design', value: 'UI_UX_DESIGN', selected: false },
    { label: 'Digital Marketing', value: 'DIGITAL_MARKETING', selected: false },
    { label: 'Data & AI', value: 'DATA_SCIENCE_AI', selected: false }
  ];

  jobTypes = [
    { label: 'Hourly', value: 'HOURLY', selected: false },
    { label: 'Fixed Price', value: 'FIXED_PRICE', selected: false }
  ];

  constructor(
    private projectService: ProjectServiceService,
    private userService: UserService,
    private router: Router,
    private notificationService: NotificationService,
    private eRef: ElementRef
  ) { }

  ngOnInit(): void {
    this.loadUserData(); 

    this.notifInterval = setInterval(() => {
      if (this.currentUser) {
        this.loadNotifications();
      }
    }, 10000);
  }

  ngOnDestroy(): void {
    if (this.notifInterval) {
      clearInterval(this.notifInterval);
    }
  }

  playNotifSound() {
    try {
      const context = new (window.AudioContext || (window as any).webkitAudioContext)();
      const oscillator = context.createOscillator();
      const gainNode = context.createGain();

      oscillator.type = 'sine';
      oscillator.frequency.setValueAtTime(880, context.currentTime); 
      oscillator.frequency.exponentialRampToValueAtTime(440, context.currentTime + 0.1); 

      gainNode.gain.setValueAtTime(1, context.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.001, context.currentTime + 0.5); 

      oscillator.connect(gainNode);
      gainNode.connect(context.destination);

      oscillator.start();
      oscillator.stop(context.currentTime + 0.5); 
    } catch (e) {
      console.error("Audio Web API bloquée :", e);
    }
  }


  loadNotifications() {
    if(this.currentUser) {
      this.notificationService.getNotifications(this.currentUser.id).subscribe({
        next: (data) => {
          this.notifications = data;
          this.unreadCount = this.notifications.filter(n => n.read === false || n.isRead === false).length;

          
          if (this.previousUnreadCount !== -1 && this.unreadCount > this.previousUnreadCount) {
            this.playNotifSound();
          }
          this.previousUnreadCount = this.unreadCount;
        },
        error: (err) => console.error("Erreur chargement notifications", err)
      });
    }
  }

  toggleNotifMenu(event: Event) {
    event.stopPropagation();
    this.isNotifOpen = !this.isNotifOpen;
    this.isMessagesOpen = false;
  }

  markNotifRead(notif: any, event: Event) {
    event.stopPropagation(); 
    this.isNotifOpen = false;

    if (notif.read === false || notif.isRead === false) {
      this.notificationService.markAsRead(notif.id).subscribe(() => {
        notif.read = true;
        notif.isRead = true;
        this.unreadCount = this.notifications.filter(n => n.read === false || n.isRead === false).length;
        
        this.router.navigate(['/FreelancerContracts']);
      });
    } else {
      this.router.navigate(['/FreelancerContracts']);
    }
  }

  toggleMessages() {
    this.isMessagesOpen = !this.isMessagesOpen;
    this.isNotifOpen = false;
  }

  @HostListener('document:click', ['$event'])
  clickout(event: any) {
    if (!this.eRef.nativeElement.contains(event.target)) {
      this.isMessagesOpen = false;
      this.isNotifOpen = false; 
    }
  }

  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        if (token) {
          const payload = token.split('.')[1];
          const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
          const currentUserId = decodedPayload.id;

          if (currentUserId) {
            this.userService.getUserById(currentUserId).subscribe({
              next: (user) => {
                this.currentUser = user;
                this.loadSavedProjects(); 
                this.loadProjects(); 
                this.loadNotifications(); // 🟢 On charge les notifs au démarrage
              },
              error: (err) => {
                console.error("Erreur Backend Profil :", err);
                this.loadProjects();
              }
            });
          }
        }
      } catch (e) {
        console.error("Erreur de décodage du token :", e);
        this.loadProjects();
      }
    } else {
      this.loadProjects();
    }
  }

  loadProjects() {
    this.projectService.getAllProjects().subscribe({
      next: (data) => {
        this.allProjects = data.filter(p => !p.status || p.status === 'OPEN').reverse();
        
        const uniqueClientIds = [...new Set(this.allProjects.map(p => p.clientId).filter(id => id != null))];
        uniqueClientIds.forEach(id => {
          if (id && !this.clientDetailsMap[id]) {
            this.userService.getUserById(id).subscribe({
              next: (user) => this.clientDetailsMap[id] = user
            });
          }
        });

        this.applyFilters();
      },
      error: (err) => console.error("Error loading projects", err)
    });
  }

  getMatchPercentage(project: any): number {
    const reqSkills = project.requiredCompetenceIds || [];
    if (reqSkills.length === 0) return 0; 
    const mySkillIds = this.currentUser?.competenceIds || [];
    if (mySkillIds.length === 0) return 0; 

    const projectSkillNumbers = reqSkills.map((id: any) => Number(id));
    const freelancerSkillNumbers = mySkillIds.map((id: any) => Number(id));

    const matchedCount = projectSkillNumbers.filter((reqId: number) => 
      freelancerSkillNumbers.includes(reqId)
    ).length;

    return Math.round((matchedCount / projectSkillNumbers.length) * 100);
  }

  getMatchColor(percentage: number): string {
    if (percentage >= 80) return '#10b981'; 
    if (percentage >= 50) return '#f59e0b'; 
    return '#ef4444'; 
  }

  applyFilters() {
    let temp = [...this.allProjects];

    if (this.searchText.trim() !== '') {
      const query = this.searchText.toLowerCase();
      temp = temp.filter(p => p.title.toLowerCase().includes(query) || p.description.toLowerCase().includes(query));
    }

    const selectedCats = this.categories.filter(c => c.selected).map(c => c.value);
    if (selectedCats.length > 0) { 
      temp = temp.filter(p => p.category && selectedCats.includes(p.category)); 
    }

    const selectedTypes = this.jobTypes.filter(t => t.selected).map(t => t.value);
    if (selectedTypes.length > 0) { 
      temp = temp.filter(p => p.jobType && selectedTypes.includes(p.jobType)); 
    }

    if (this.selectedBudget !== 'Any') {
      temp = temp.filter(p => {
        if (!p.budget) return false;
        if (this.selectedBudget === '100-500') return p.budget >= 100 && p.budget <= 500;
        if (this.selectedBudget === '500-1000') return p.budget > 500 && p.budget <= 1000;
        if (this.selectedBudget === '1000+') return p.budget > 1000;
        return true;
      });
    }

    if (this.sortBy === 'Best Match') {
      temp.sort((a, b) => {
        const matchDiff = this.getMatchPercentage(b) - this.getMatchPercentage(a);
        if (matchDiff === 0) return (b.id || 0) - (a.id || 0);
        return matchDiff;
      });
    } else if (this.sortBy === 'Newest') {
      temp.sort((a, b) => (b.id || 0) - (a.id || 0));
    } else if (this.sortBy === 'Budget (High-Low)') {
      temp.sort((a, b) => (b.budget || 0) - (a.budget || 0));
    }

    this.filteredProjects = temp;
  }

  formatEnumText(value: string | undefined): string {
    if (!value) return 'General';
    return value.replace(/_/g, ' ').replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substring(1).toLowerCase());
  }

  clearFilters() {
    this.searchText = '';
    this.selectedBudget = 'Any';
    this.sortBy = 'Best Match'; 
    this.categories.forEach(c => c.selected = false);
    this.jobTypes.forEach(t => t.selected = false);
    this.applyFilters();
  }

  loadSavedProjects() {
    if (this.currentUser && this.currentUser.id) {
      const saved = localStorage.getItem(`saved_jobs_${this.currentUser.id}`);
      if (saved) {
        this.savedProjects = JSON.parse(saved);
      }
    }
  }

  isSaved(projectId: number | undefined): boolean {
    if (!projectId) return false;
    return this.savedProjects.some(p => p.id === projectId);
  }

  toggleSave(project: Project, event: Event) {
    event.stopPropagation(); 
    
    if (!this.currentUser) {
        alert("Please log in to save jobs.");
        return;
    }

    if (this.isSaved(project.id)) {
      this.savedProjects = this.savedProjects.filter(p => p.id !== project.id);
    } else {
      this.savedProjects.push(project);
    }
 
    localStorage.setItem(`saved_jobs_${this.currentUser.id}`, JSON.stringify(this.savedProjects));
  }
}