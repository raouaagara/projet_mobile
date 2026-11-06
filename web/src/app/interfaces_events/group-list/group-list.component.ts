import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import {
  NotificationService,
  NotificationGroup,
  NotificationItem
} from '../notification.service';
import { GroupService } from '../group.service';
import { GroupMemberService } from '../group-member.service';
import { EventService } from '../event.service';
import { ClubService } from '../club.service';
import { Club } from '../models';
import { forkJoin } from 'rxjs';

type GroupType = 'Public' | 'Private' | 'Invitation only';

interface GroupDisplay {
  id: number;
  name: string;
  description: string;
  type: GroupType;
  bannerUrl?: string;
  memberCount?: number;
  isJoined?: boolean;
}

const TYPE_TO_DISPLAY: Record<string, GroupType> = {
  PUBLIC: 'Public',
  PRIVATE: 'Private',
  INVITE_ONLY: 'Invitation only'
};
const TYPE_TO_API: Record<GroupType, string> = {
  Public: 'PUBLIC',
  Private: 'PRIVATE',
  'Invitation only': 'INVITE_ONLY'
};

@Component({
  selector: 'app-group-list',
  templateUrl: './group-list.component.html',
  styleUrls: ['./group-list.component.css']
})
export class GroupListComponent implements OnInit {
  groups: GroupDisplay[] = [];
  loading = false;
  saveError: string | null = null;

  searchTerm = '';
  selectedGroupType: string = 'All';
  isNotificationsOpen = false;
  upcomingEvents: any[] = [];
  showAllGroups = false;
  currentUserId: number = 1; // Simulated user ID - in real app, get from auth service
  
  // Clubs data
  clubs: Club[] = [];
  filteredClubs: Club[] = [];
  loadingClubs = false;
  selectedInterest = 'all';
  showAllClubs = false;
  
  interests = [
    { value: 'all', label: 'All Interests', icon: 'fa-th' },
    { value: 'technology', label: 'Technology', icon: 'fa-laptop-code' },
    { value: 'sports', label: 'Sports', icon: 'fa-futbol' },
    { value: 'arts', label: 'Arts & Culture', icon: 'fa-palette' },
    { value: 'music', label: 'Music', icon: 'fa-music' },
    { value: 'business', label: 'Business', icon: 'fa-briefcase' },
    { value: 'science', label: 'Science', icon: 'fa-flask' },
    { value: 'gaming', label: 'Gaming', icon: 'fa-gamepad' },
    { value: 'photography', label: 'Photography', icon: 'fa-camera' }
  ];

  constructor(
    private router: Router,
    public notificationService: NotificationService,
    private groupService: GroupService,
    private groupMemberService: GroupMemberService,
    private eventService: EventService,
    private clubService: ClubService
  ) {}

  ngOnInit(): void {
    this.loadGroups();
    this.loadUpcomingEvents();
    this.loadClubs();
    this.generateCalendar();
  }

  loadGroups(): void {
    this.loading = true;
    this.saveError = null;
    this.groupService.getGroups().subscribe({
      next: (list) => {
        const groups = (list || []).map(api => this.apiToDisplay(api));
        
        // Load member counts and check if user is already a member
        if (groups.length > 0) {
          const memberCountRequests = groups.map(group => 
            this.groupMemberService.countMembersByGroupId(group.id)
          );
          
          const membershipRequests = groups.map(group =>
            this.groupMemberService.getMembersByGroupId(group.id)
          );
          
          forkJoin([
            forkJoin(memberCountRequests),
            forkJoin(membershipRequests)
          ]).subscribe({
            next: ([counts, memberships]) => {
              groups.forEach((group, index) => {
                group.memberCount = counts[index] || 0;
                // Check if current user is already a member
                group.isJoined = memberships[index].some(m => m.userId === this.currentUserId);
              });
              this.groups = groups;
              this.loading = false;
            },
            error: () => {
              // If member count/check fails, still show groups
              this.groups = groups;
              this.loading = false;
            }
          });
        } else {
          this.groups = groups;
          this.loading = false;
        }
      },
      error: () => {
        this.loading = false;
        this.saveError = 'Impossible de charger les groupes. Vérifiez que le backend tourne sur http://localhost:8089.';
      }
    });
  }

  private apiToDisplay(api: { id?: number; name: string; description?: string; type?: string; bannerUrl?: string }): GroupDisplay {
    return {
      id: api.id ?? 0,
      name: api.name,
      description: api.description || '',
      type: TYPE_TO_DISPLAY[api.type || ''] ?? 'Public',
      bannerUrl: api.bannerUrl || ''
    };
  }

  openGroup(id: number): void {
    this.router.navigate(['/groups', id]);
  }

  navigateToEvents(): void {
    this.router.navigate(['/events']);
  }

  // Notifications avancées
  get unreadNotificationsCount(): number {
    return this.notificationService.unreadCount;
  }

  get notificationGroups(): NotificationGroup[] {
    return this.notificationService.getGroups();
  }

  toggleNotifications(): void {
    this.isNotificationsOpen = !this.isNotificationsOpen;
  }

  openFromNotification(n: NotificationItem, event?: MouseEvent): void {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }
    this.notificationService.markAsRead(n.id);
    if (n.relatedRoute) {
      this.router.navigate([n.relatedRoute]);
    }
  }

  get filteredGroups(): GroupDisplay[] {
    let filtered = this.groups;

    // Apply search filter
    if (this.searchTerm.trim()) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(g =>
        g.name.toLowerCase().includes(term) ||
        g.description.toLowerCase().includes(term)
      );
    }

    // Apply group type filter
    if (this.selectedGroupType && this.selectedGroupType !== 'All' && this.selectedGroupType !== 'all') {
      // Handle both display format and API format
      if (this.selectedGroupType === 'PUBLIC' || this.selectedGroupType === 'Public') {
        filtered = filtered.filter(g => g.type === 'Public');
      } else if (this.selectedGroupType === 'PRIVATE' || this.selectedGroupType === 'Private') {
        filtered = filtered.filter(g => g.type === 'Private');
      } else if (this.selectedGroupType === 'INVITE_ONLY' || this.selectedGroupType === 'Invitation only') {
        filtered = filtered.filter(g => g.type === 'Invitation only');
      }
    }

    // Limit to 4 groups if not showing all
    if (!this.showAllGroups) {
      filtered = filtered.slice(0, 4);
    }

    return filtered;
  }

  onGroupTypeChange(event: any): void {
    this.selectedGroupType = event.target.value;
    // Trigger filtering
    this.filterGroups();
  }

  toggleShowAllGroups(): void {
    this.showAllGroups = !this.showAllGroups;
  }

  filterGroups(): void {
    // This method is called to trigger change detection
    // The actual filtering happens in the filteredGroups getter
  }

  viewGroup(groupId: number): void {
    this.openGroup(groupId);
  }

  createGroup(): void {
    alert('Create group functionality - Coming soon!');
  }

  handleNotificationClick(notification: any): void {
    this.openFromNotification(notification);
  }

  // Calendar methods
  currentMonth = new Date();
  calendarDays: any[] = [];

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

  loadUpcomingEvents(): void {
    this.eventService.getAllEvents().subscribe({
      next: (events) => {
        const now = new Date();
        // Filter approved and upcoming events
        this.upcomingEvents = events
          .filter(e => e.status === 'APPROVED' || !e.status)
          .filter(e => new Date(e.startDate) >= now)
          .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime())
          .slice(0, 2); // Show only 2 upcoming events
      },
      error: (err) => {
        console.error('Error loading events:', err);
      }
    });
  }

  formatEventDate(dateString: string): { day: string, month: string } {
    const date = new Date(dateString);
    return {
      day: date.getDate().toString(),
      month: date.toLocaleDateString('en-US', { month: 'short' }).toUpperCase()
    };
  }

  formatEventTime(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  }

  joinGroup(group: GroupDisplay, event?: MouseEvent): void {
    if (event) {
      event.stopPropagation();
    }

    if (group.type === 'Invitation only') {
      alert('This group is invitation only. You need an invitation to join.');
      return;
    }

    // Create new member
    const newMember = {
      group: { id: group.id },
      userId: this.currentUserId,
      role: 'MEMBER' as const
    };

    this.groupMemberService.addMember(newMember).subscribe({
      next: () => {
        // Update member count
        if (group.memberCount !== undefined) {
          group.memberCount++;
        } else {
          group.memberCount = 1;
        }
        group.isJoined = true;
        
        // Show success message
        alert(`Successfully joined ${group.name}!`);
      },
      error: (err) => {
        console.error('Error joining group:', err);
        alert('Error joining group. Please try again.');
      }
    });
  }

  // Clubs methods
  loadClubs(): void {
    this.loadingClubs = true;
    this.clubService.getAllClubs().subscribe({
      next: (data) => {
        this.clubs = data;
        this.filterClubs();
        this.loadingClubs = false;
      },
      error: (error) => {
        console.error('Error loading clubs:', error);
        this.loadingClubs = false;
      }
    });
  }

  filterClubs(): void {
    let filtered = this.clubs;

    // Filter by interest
    if (this.selectedInterest !== 'all') {
      filtered = filtered.filter(club => 
        club.interests?.toLowerCase().includes(this.selectedInterest.toLowerCase())
      );
    }

    // Filter by search term
    if (this.searchTerm.trim()) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(club =>
        club.name.toLowerCase().includes(term) ||
        club.description.toLowerCase().includes(term) ||
        club.interests?.toLowerCase().includes(term)
      );
    }

    // Limit to 4 clubs if not showing all
    if (!this.showAllClubs) {
      filtered = filtered.slice(0, 4);
    }

    this.filteredClubs = filtered;
  }

  onInterestChange(interest: string): void {
    this.selectedInterest = interest;
    this.filterClubs();
  }

  toggleShowAllClubs(): void {
    this.showAllClubs = !this.showAllClubs;
    this.filterClubs();
  }

  viewClubDetails(clubId: number, event?: MouseEvent): void {
    if (event) {
      event.stopPropagation();
    }
    this.router.navigate(['/clubs', clubId]);
  }

  joinClub(club: Club, event?: MouseEvent): void {
    if (event) {
      event.stopPropagation();
    }
    
    const confirmed = confirm(`Do you want to join "${club.name}"?`);
    
    if (confirmed) {
      // Navigate to club details after joining
      this.router.navigate(['/clubs', club.id]);
    }
  }

  getClubIcon(interests: string | undefined): string {
    if (!interests) return 'fa-users';
    
    const interest = interests.toLowerCase();
    if (interest.includes('tech')) return 'fa-laptop-code';
    if (interest.includes('sport')) return 'fa-futbol';
    if (interest.includes('art') || interest.includes('culture')) return 'fa-palette';
    if (interest.includes('music')) return 'fa-music';
    if (interest.includes('business')) return 'fa-briefcase';
    if (interest.includes('science')) return 'fa-flask';
    if (interest.includes('gaming') || interest.includes('game')) return 'fa-gamepad';
    if (interest.includes('photo')) return 'fa-camera';
    
    return 'fa-users';
  }

  getInterestBadges(interests: string | undefined): string[] {
    if (!interests) return [];
    return interests.split(',').map(i => i.trim()).filter(i => i.length > 0);
  }
}

