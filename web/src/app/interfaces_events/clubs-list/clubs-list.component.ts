import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ClubService, Club } from '../club.service';
import { EventService } from '../event.service';
import { NotificationService } from '../notification.service';

@Component({
  selector: 'app-clubs-list',
  templateUrl: './clubs-list.component.html',
  styleUrls: ['./clubs-list.component.css']
})
export class ClubsListComponent implements OnInit {
  clubs: Club[] = [];
  filteredClubs: Club[] = [];
  upcomingEvents: any[] = [];
  loading = false;
  searchTerm = '';
  selectedInterest = 'all';
  showAllClubs = false;

  // Mock data
  mockClubs: Club[] = [
    {
      name: 'Tech Innovators',
      description: 'A community of developers and tech enthusiasts passionate about innovation',
      interests: 'Technology, Programming, AI',
      id: 1
    },
    {
      name: 'Design Masters',
      description: 'Creative designers sharing ideas and inspiration',
      interests: 'Design, UI/UX, Graphics',
      id: 2
    },
    {
      name: 'Business Network',
      description: 'Professional networking for entrepreneurs',
      interests: 'Business, Networking, Startups',
      id: 3
    },
    {
      name: 'Marketing Pros',
      description: 'Digital marketing strategies and best practices',
      interests: 'Marketing, Social Media, SEO',
      id: 4
    }
  ];

  mockEvents = [
    {
      id: 1,
      title: 'Tech Meetup 2026',
      location: 'Conference Hall A',
      startDate: new Date('2026-03-15')
    },
    {
      id: 2,
      title: 'Design Workshop',
      location: 'Room 101',
      startDate: new Date('2026-03-25')
    }
  ];

  popularInterests = [
    { name: 'Technology', icon: 'fa fa-laptop-code' },
    { name: 'Design', icon: 'fa fa-palette' },
    { name: 'Business', icon: 'fa fa-briefcase' },
    { name: 'Marketing', icon: 'fa fa-bullhorn' },
    { name: 'Programming', icon: 'fa fa-code' },
    { name: 'Networking', icon: 'fa fa-handshake' }
  ];

  // Calendar
  currentMonth = new Date();
  calendarDays: any[] = [];

  constructor(
    private router: Router,
    private clubService: ClubService,
    private eventService: EventService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadClubs();
    this.loadUpcomingEvents();
    this.generateCalendar();
  }

  loadClubs(): void {
    this.loading = true;
    this.clubService.getAllClubs().subscribe({
      next: (data) => {
        this.clubs = data;
        this.filterClubs();
        this.loading = false;
      },
      error: () => {
        this.clubs = this.mockClubs;
        this.filterClubs();
        this.loading = false;
      }
    });
  }

  loadUpcomingEvents(): void {
    this.eventService.getAllEvents().subscribe({
      next: (data) => {
        const now = new Date();
        this.upcomingEvents = data
          .filter(e => new Date(e.startDate) >= now)
          .slice(0, 3);
      },
      error: () => {
        this.upcomingEvents = this.mockEvents;
      }
    });
  }

  filterClubs(): void {
    let filtered = [...this.clubs]; // Create a copy

    // Filter by search term
    if (this.searchTerm.trim()) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(club =>
        club.name.toLowerCase().includes(term) ||
        (club.description && club.description.toLowerCase().includes(term)) ||
        (club.interests && club.interests.toLowerCase().includes(term))
      );
    }

    // Filter by interest
    if (this.selectedInterest && this.selectedInterest !== 'all') {
      filtered = filtered.filter(club =>
        club.interests && club.interests.toLowerCase().includes(this.selectedInterest.toLowerCase())
      );
    }

    // Limit to display count if not showing all
    if (!this.showAllClubs) {
      filtered = filtered.slice(0, 6);
    }

    this.filteredClubs = filtered;
  }

  onSearchChange(): void {
    this.filterClubs();
  }

  onInterestChange(interest: string): void {
    this.selectedInterest = interest;
    this.filterClubs();
  }

  toggleShowAllClubs(): void {
    this.showAllClubs = !this.showAllClubs;
    this.filterClubs();
  }

  viewClub(clubId: number | undefined): void {
    if (clubId) {
      this.router.navigate(['/clubs', clubId]);
    }
  }

  joinClub(club: Club, event?: MouseEvent): void {
    if (event) {
      event.stopPropagation();
    }
    alert(`Join club: ${club.name} - Coming soon!`);
  }

  createClub(): void {
    alert('Create club functionality - Coming soon!');
  }

  navigateToEvents(): void {
    this.router.navigate(['/events']);
  }

  navigateToGroups(): void {
    this.router.navigate(['/groups']);
  }

  filterByInterest(interest: any): void {
    this.selectedInterest = interest.name;
    this.filterClubs();
  }

  getClubIcon(interests: string | undefined): string {
    if (!interests) return 'fa-users-cog';
    const lower = interests.toLowerCase();
    if (lower.includes('tech') || lower.includes('programming')) return 'fa-laptop-code';
    if (lower.includes('design')) return 'fa-palette';
    if (lower.includes('business')) return 'fa-briefcase';
    if (lower.includes('marketing')) return 'fa-bullhorn';
    return 'fa-users-cog';
  }

  getInterestBadges(interests: string | undefined): string[] {
    if (!interests) return [];
    return interests.split(',').map(i => i.trim()).slice(0, 3);
  }

  // Calendar methods
  previousMonth(): void {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() - 1);
    this.generateCalendar();
  }

  nextMonth(): void {
    this.currentMonth = new Date(this.currentMonth.getFullYear(), this.currentMonth.getMonth() + 1);
    this.generateCalendar();
  }

  generateCalendar(): void {
    const year = this.currentMonth.getFullYear();
    const month = this.currentMonth.getMonth();
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const today = new Date();

    this.calendarDays = [];

    // Previous month days
    const prevMonthDays = new Date(year, month, 0).getDate();
    for (let i = firstDay - 1; i >= 0; i--) {
      this.calendarDays.push({
        date: prevMonthDays - i,
        isOtherMonth: true,
        isToday: false,
        hasEvent: false
      });
    }

    // Current month days
    for (let i = 1; i <= daysInMonth; i++) {
      const isToday = today.getDate() === i && 
                      today.getMonth() === month && 
                      today.getFullYear() === year;
      this.calendarDays.push({
        date: i,
        isOtherMonth: false,
        isToday,
        hasEvent: false
      });
    }

    // Next month days
    const remainingDays = 42 - this.calendarDays.length;
    for (let i = 1; i <= remainingDays; i++) {
      this.calendarDays.push({
        date: i,
        isOtherMonth: true,
        isToday: false,
        hasEvent: false
      });
    }
  }

  // Notifications (placeholder)
  isNotificationsOpen = false;
  unreadNotificationsCount = 0;

  toggleNotifications(): void {
    this.isNotificationsOpen = !this.isNotificationsOpen;
  }
}
