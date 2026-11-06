import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { Router } from '@angular/router';
import { ClubService } from '../club.service';
import { EventService } from '../event.service';
import { GroupService, Group } from '../group.service';
import { PostService } from '../post.service';
import { NotificationService } from '../notification.service';
import { Club, Post } from '../models';

@Component({
  selector: 'app-club-dashboard',
  templateUrl: './club-dashboard.component.html',
  styleUrls: ['./club-dashboard.component.css']
})
export class ClubDashboardComponent implements OnInit {
  activeSection: string = 'dashboard';
  
  // Groups data
  groups: Group[] = [];
  showGroupModal = false;
  editingGroup: Group | null = null;
  groupForm: Group = {
    name: '',
    description: '',
    type: 'PUBLIC',
    bannerUrl: ''
  };
  
  // Clubs data
  clubs: any[] = [];
  filteredClubs: any[] = [];
  selectedClub: any = null;
  showClubModal = false;
  editingClub: any = null;
  clubForm: any = {
    name: '',
    description: '',
    interests: '',
    bannerUrl: ''
  };
  
  // Events data
  events: any[] = [];
  allEvents: any[] = [];
  upcomingEvents: any[] = [];
  showEventModal = false;
  editingEvent: any = null;
  eventForm: any = {
    title: '',
    description: '',
    location: '',
    startDate: '',
    endDate: '',
    groupId: null
  };
  loading = false;
  
  // Recent activities
  recentActivities: any[] = [];
  maxActivities = 10; // Maximum number of activities to keep
  
  // Calendar
  currentMonth: string = '';
  currentDate: Date = new Date();
  weekDays: string[] = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  calendarDays: any[] = [];
  selectedDate: Date | null = null;
  selectedDayEvents: any[] = [];
  calendarView: 'month' | 'week' | 'list' = 'month';
  eventTypeFilter: string = 'all';
  
  // Groups filtering and view
  groupSearchQuery: string = '';
  groupFilter: string = 'all';
  filteredGroupsList: Group[] = [];
  viewMode: 'grid' | 'list' = 'grid';
  
  // Clubs filtering and view
  clubSearchQuery: string = '';
  clubFilter: string = 'all';
  filteredClubsList: any[] = [];
  clubViewMode: 'grid' | 'list' = 'grid';
  
  // Overview/Statistics
  dateRange: string = 'week';
  
  // Announcements
  announcements: any[] = [];
  showAnnouncementModal = false;
  editingAnnouncement: any = null;
  announcementForm: any = {
    title: '',
    content: '',
    author: '',
    targetGroup: null
  };
  announcementTab: 'announcements' | 'posts' = 'announcements';
  announcementSearchQuery: string = '';
  announcementFilter: string = 'all';
  filteredAnnouncements: any[] = [];
  
  // Posts
  posts: any[] = [];
  showPostModal = false;
  editingPost: any = null;
  postForm: any = {
    author: '',
    title: '',
    content: '',
    imageUrl: '',
    groupId: null
  };
  postSearchQuery: string = '';
  postFilter: string = 'all';
  postSortBy: string = 'recent';
  filteredPosts: any[] = [];
  
  // Trending & Members
  trendingTopics: any[] = [];
  topPosts: any[] = [];
  
  // Stats
  stats = {
    activeGroups: 0,
    totalClubs: 0,
    eventsThisMonth: 0
  };

  // Dashboard filtering and sorting
  dashboardSearchQuery: string = '';
  dashboardFilter: string = 'all';
  dashboardSortBy: string = 'recent';
  dashboardDateRange: string = 'all';
  filteredGroups: Group[] = [];
  filteredEvents: any[] = [];
  filteredActivities: any[] = [];

  // Mock data
  mockClubs = [
    {
      id: 1,
      name: 'sou',
      description: 'aloooooooooooooooooooo',
      interests: 'oooooo',
      membersCount: 0,
      eventsCount: 0,
      createdAt: '2026-02-18T21:59:25'
    },
    {
      id: 2,
      name: 'coucou',
      description: 'tqyqfghjklm',
      interests: 'dfghjklm',
      membersCount: 0,
      eventsCount: 0,
      createdAt: '2026-02-18T21:59:25'
    }
  ];

  mockEvents = [
    {
      id: 1,
      title: 'Live Freelance Coaching',
      description: 'Online coaching session',
      location: 'Online',
      startDate: new Date('2026-05-15T16:00:00'),
      endDate: new Date('2026-05-15T18:00:00'),
      status: 'APPROVED',
      attendees: 120
    },
    {
      id: 2,
      title: 'Community Afterwork',
      description: 'Networking event',
      location: 'Collegium',
      startDate: new Date('2026-05-22T19:00:00'),
      endDate: new Date('2026-05-22T22:00:00'),
      status: 'APPROVED',
      attendees: 45
    }
  ];

  mockActivities = [
    {
      groupName: 'Web Developers',
      description: 'New post: "Share your best Angular tips"',
      time: 'il y a 2 h',
      type: 'post'
    },
    {
      groupName: 'Designers',
      description: '2 new members joined the group',
      time: 'il y a 4 h',
      type: 'member'
    }
  ];

  constructor(
    private router: Router,
    private clubService: ClubService,
    private eventService: EventService,
    private groupService: GroupService,
    private postService: PostService,
    private cdr: ChangeDetectorRef,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadData();
    this.initializeActivities();
    this.generateCalendar();
    this.loadAnnouncements();
    this.loadPosts();
    this.filterGroups();
    this.filterClubs();
    this.loadTrendingTopics();
    this.loadTopPosts();
    this.initializeDashboardFilters();
  }

  initializeActivities(): void {
    // Initialize with mock activities if empty
    if (this.recentActivities.length === 0) {
      this.recentActivities = [...this.mockActivities];
    }
  }

  addActivity(groupName: string, description: string, type: string = 'general'): void {
    const activity = {
      groupName,
      description,
      time: 'Just now',
      type
    };
    
    // Add to beginning of array
    this.recentActivities.unshift(activity);
    
    // Keep only the last maxActivities
    if (this.recentActivities.length > this.maxActivities) {
      this.recentActivities = this.recentActivities.slice(0, this.maxActivities);
    }
    
    // Update timestamps
    this.updateActivityTimestamps();
  }

  updateActivityTimestamps(): void {
    // This would be called periodically to update "time ago" strings
    // For now, we'll keep it simple
  }

  getRelativeTime(timestamp: Date): string {
    const now = new Date();
    const diff = now.getTime() - timestamp.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `il y a ${minutes} min`;
    if (hours < 24) return `il y a ${hours} h`;
    return `il y a ${days} j`;
  }

  loadData(): void {
    this.loading = true;
    
    // Load groups
    this.groupService.getAllGroups().subscribe({
      next: (data) => {
        this.groups = data;
        this.updateStats();
        this.generateGroupActivities();
        this.filterGroups();
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error loading groups:', err);
        this.groups = [];
        this.filterGroups();
        this.cdr.detectChanges();
      }
    });
    
    // Load clubs
    this.clubService.getAllClubs().subscribe({
      next: (data) => {
        this.clubs = data;
        this.filteredClubs = data;
        this.filterClubs();
        if (data.length > 0) {
          this.selectedClub = data[0];
        }
        this.updateStats();
        this.loadEvents();
        this.cdr.detectChanges();
      },
      error: () => {
        this.clubs = this.mockClubs;
        this.filteredClubs = this.mockClubs;
        this.filterClubs();
        this.selectedClub = this.mockClubs[0];
        this.recentActivities = this.mockActivities;
        this.loadEvents();
        this.cdr.detectChanges();
      }
    });
  }

  generateGroupActivities(): void {
    // Generate activities from existing groups
    if (this.groups.length > 0) {
      // Clear existing activities
      this.recentActivities = [];
      
      // Add activities for the most recent groups (up to 5)
      const recentGroups = [...this.groups]
        .sort((a, b) => {
          const dateA = a.createdAt ? new Date(a.createdAt).getTime() : 0;
          const dateB = b.createdAt ? new Date(b.createdAt).getTime() : 0;
          return dateB - dateA;
        })
        .slice(0, 5);
      
      recentGroups.forEach((group, index) => {
        const timeAgo = this.calculateTimeAgo(group.createdAt);
        this.recentActivities.push({
          groupName: group.name,
          description: `Group created - ${group.type}`,
          time: timeAgo,
          type: 'create'
        });
      });
    } else {
      // Use mock activities if no groups
      this.recentActivities = [...this.mockActivities];
    }
  }

  calculateTimeAgo(dateString: string | undefined): string {
    if (!dateString) return 'Recently';
    
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `il y a ${diffMins} min`;
    if (diffHours < 24) return `il y a ${diffHours} h`;
    if (diffDays < 7) return `il y a ${diffDays} j`;
    return date.toLocaleDateString();
  }

  loadEvents(): void {
    this.eventService.getAllEvents().subscribe({
      next: (data) => {
        this.events = data;
        this.allEvents = [...data].sort((a: any, b: any) => 
          new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
        );
        this.updateUpcomingEvents();
        this.updateStats();
        this.generateCalendar(); // Regenerate calendar with new events
        this.loading = false;
      },
      error: () => {
        this.events = this.mockEvents;
        this.allEvents = [...this.mockEvents].sort((a: any, b: any) => 
          new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
        );
        this.updateUpcomingEvents();
        this.updateStats();
        this.generateCalendar(); // Regenerate calendar with mock events
        this.loading = false;
      }
    });
  }

  updateStats(): void {
    this.stats.activeGroups = this.groups.length;
    this.stats.totalClubs = this.clubs.length;
    
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    
    this.stats.eventsThisMonth = this.events.filter(e => {
      const eventDate = new Date(e.startDate);
      return eventDate >= startOfMonth && eventDate <= endOfMonth;
    }).length;
  }

  // Group CRUD Methods
  openGroupModal(group?: Group): void {
    this.showGroupModal = true;
    if (group) {
      this.editingGroup = group;
      this.groupForm = { ...group };
    } else {
      this.editingGroup = null;
      this.groupForm = {
        name: '',
        description: '',
        type: 'PUBLIC',
        bannerUrl: ''
      };
    }
  }

  closeGroupModal(): void {
    this.showGroupModal = false;
    this.editingGroup = null;
    this.groupForm = {
      name: '',
      description: '',
      type: 'PUBLIC',
      bannerUrl: ''
    };
  }

  saveGroup(): void {
    if (!this.groupForm.name || !this.groupForm.description) {
      alert('Please fill in all required fields');
      return;
    }

    if (this.editingGroup && this.editingGroup.id) {
      // Update existing group
      this.groupService.updateGroup(this.editingGroup.id, this.groupForm).subscribe({
        next: (updated) => {
          const index = this.groups.findIndex(g => g.id === updated.id);
          if (index !== -1) {
            this.groups[index] = updated;
          }
          this.closeGroupModal();
          this.updateStats();
          this.addActivity(updated.name, `Group updated - ${updated.type}`, 'update');
          alert('Group updated successfully!');
        },
        error: (err) => {
          console.error('Error updating group:', err);
          alert('Failed to update group. Please try again.');
        }
      });
    } else {
      // Create new group
      this.groupService.createGroup(this.groupForm).subscribe({
        next: (created) => {
          this.groups.push(created);
          this.closeGroupModal();
          this.updateStats();
          this.addActivity(created.name, `Group created - ${created.type}`, 'create');
          alert('Group created successfully!');
        },
        error: (err) => {
          console.error('Error creating group:', err);
          alert('Failed to create group. Please try again.');
        }
      });
    }
  }

  deleteGroup(groupId: number): void {
    if (!confirm('Are you sure you want to delete this group?')) {
      return;
    }

    const group = this.groups.find(g => g.id === groupId);
    const groupName = group ? group.name : 'Group';

    this.groupService.deleteGroup(groupId).subscribe({
      next: () => {
        this.groups = this.groups.filter(g => g.id !== groupId);
        this.updateStats();
        this.addActivity(groupName, 'Group deleted', 'delete');
        alert('Group deleted successfully!');
      },
      error: (err) => {
        console.error('Error deleting group:', err);
        alert('Failed to delete group. Please try again.');
      }
    });
  }

  // Club CRUD Methods
  openClubModal(club?: any): void {
    this.showClubModal = true;
    if (club) {
      this.editingClub = club;
      this.clubForm = { ...club };
    } else {
      this.editingClub = null;
      this.clubForm = {
        name: '',
        description: '',
        interests: '',
        bannerUrl: ''
      };
    }
  }

  closeClubModal(): void {
    this.showClubModal = false;
    this.editingClub = null;
    this.clubForm = {
      name: '',
      description: '',
      interests: '',
      bannerUrl: ''
    };
  }

  saveClub(): void {
    if (!this.clubForm.name || !this.clubForm.description) {
      alert('Please fill in all required fields');
      return;
    }

    if (this.editingClub && this.editingClub.id) {
      // Update existing club
      this.clubService.updateClub(this.editingClub.id, this.clubForm).subscribe({
        next: (updated) => {
          const index = this.clubs.findIndex(c => c.id === updated.id);
          if (index !== -1) {
            this.clubs[index] = updated;
            this.filteredClubs = [...this.clubs];
          }
          this.filterClubs();
          this.closeClubModal();
          this.updateStats();
          const interests = updated.interests ? ` - ${updated.interests.split(',')[0].trim()}` : '';
          this.addActivity(updated.name, `Club updated${interests}`, 'update');
          alert('Club updated successfully!');
        },
        error: (err) => {
          console.error('Error updating club:', err);
          alert('Failed to update club. Please try again.');
        }
      });
    } else {
      // Create new club
      this.clubService.createClub(this.clubForm).subscribe({
        next: (created) => {
          this.clubs.push(created);
          this.filteredClubs = [...this.clubs];
          this.filterClubs();
          
          // Send notification about new club
          this.notificationService.addNotification({
            type: 'club',
            title: 'New Club Available',
            message: `"${created.name}" club has been created. Join now!`,
            importance: 'normal',
            relatedRoute: `/clubs/${created.id}`
          });
          
          this.closeClubModal();
          this.updateStats();
          const interests = created.interests ? ` - ${created.interests.split(',')[0].trim()}` : '';
          this.addActivity(created.name, `New club created${interests}`, 'create');
          alert('Club created successfully!');
        },
        error: (err) => {
          console.error('Error creating club:', err);
          alert('Failed to create club. Please try again.');
        }
      });
    }
  }

  deleteClub(clubId: number): void {
    if (!confirm('Are you sure you want to delete this club?')) {
      return;
    }

    const club = this.clubs.find(c => c.id === clubId);
    const clubName = club ? club.name : 'Club';

    this.clubService.deleteClub(clubId).subscribe({
      next: () => {
        this.clubs = this.clubs.filter(c => c.id !== clubId);
        this.filteredClubs = [...this.clubs];
        this.filterClubs();
        this.updateStats();
        this.addActivity(clubName, 'Club deleted', 'delete');
        alert('Club deleted successfully!');
      },
      error: (err) => {
        console.error('Error deleting club:', err);
        alert('Failed to delete club. Please try again.');
      }
    });
  }

  setSection(section: string): void {
    this.activeSection = section;
    if (section === 'calendar') {
      this.generateCalendar();
    }
  }

  getPageTitle(): string {
    switch (this.activeSection) {
      case 'groups': return 'Groups & Communities';
      case 'calendar': return 'Calendar';
      case 'announcements': return 'Announcements';
      case 'overview': return 'Statistics & Overview';
      case 'clubs': return 'Clubs Management';
      default: return 'Clubs dashboard';
    }
  }

  getPageSubtitle(): string {
    if (this.activeSection === 'dashboard' && (this.dashboardFilter !== 'all' || this.dashboardSearchQuery || this.dashboardDateRange !== 'all')) {
      const totalResults = this.getFilteredGroupsForDisplay().length + 
                          this.getFilteredEventsForDisplay().length + 
                          this.getFilteredClubsForDisplay().length;
      return `Showing ${totalResults} filtered results - Track activity across your groups, events and members.`;
    }
    
    switch (this.activeSection) {
      case 'groups': return 'Manage all your groups and communities';
      case 'calendar': return 'View and manage all events';
      case 'announcements': return 'Create and manage announcements for your community';
      case 'overview': return 'Comprehensive analytics and insights for your community';
      case 'clubs': return 'Manage all specialized clubs and their activities';
      default: return 'Track activity across your groups, events and members.';
    }
  }

  // Calendar Methods
  generateCalendar(): void {
    const year = this.currentDate.getFullYear();
    const month = this.currentDate.getMonth();
    
    this.currentMonth = this.currentDate.toLocaleDateString('en-US', { 
      month: 'long', 
      year: 'numeric' 
    });
    
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const prevLastDay = new Date(year, month, 0);
    
    const firstDayOfWeek = firstDay.getDay();
    const lastDateOfMonth = lastDay.getDate();
    const prevLastDate = prevLastDay.getDate();
    
    this.calendarDays = [];
    
    // Previous month days
    for (let i = firstDayOfWeek; i > 0; i--) {
      const day = prevLastDate - i + 1;
      const date = new Date(year, month - 1, day);
      this.calendarDays.push({
        day,
        date,
        isCurrentMonth: false,
        isToday: false,
        events: this.getEventsForDate(date)
      });
    }
    
    // Current month days
    const today = new Date();
    for (let day = 1; day <= lastDateOfMonth; day++) {
      const date = new Date(year, month, day);
      const isToday = date.toDateString() === today.toDateString();
      this.calendarDays.push({
        day,
        date,
        isCurrentMonth: true,
        isToday,
        events: this.getEventsForDate(date)
      });
    }
    
    // Next month days
    const remainingDays = 42 - this.calendarDays.length;
    for (let day = 1; day <= remainingDays; day++) {
      const date = new Date(year, month + 1, day);
      this.calendarDays.push({
        day,
        date,
        isCurrentMonth: false,
        isToday: false,
        events: this.getEventsForDate(date)
      });
    }
  }

  getEventsForDate(date: Date): any[] {
    const filteredEvents = this.getFilteredEvents();
    return filteredEvents.filter(event => {
      const eventDate = new Date(event.startDate);
      return eventDate.toDateString() === date.toDateString();
    });
  }

  previousMonth(): void {
    this.currentDate = new Date(
      this.currentDate.getFullYear(),
      this.currentDate.getMonth() - 1,
      1
    );
    this.generateCalendar();
  }

  nextMonth(): void {
    this.currentDate = new Date(
      this.currentDate.getFullYear(),
      this.currentDate.getMonth() + 1,
      1
    );
    this.generateCalendar();
  }

  selectDay(day: any): void {
    this.selectedDate = day.date;
    this.selectedDayEvents = day.events;
  }

  setCalendarView(view: 'month' | 'week' | 'list'): void {
    this.calendarView = view;
  }

  goToToday(): void {
    this.currentDate = new Date();
    this.generateCalendar();
  }

  getEventColor(event: any): string {
    if (event.group) return '#198754'; // Green for group events
    if (event.clubId || event.club) return '#0d6efd'; // Blue for club events
    return '#fd7e14'; // Orange for general events
  }

  setEventTypeFilter(type: string): void {
    this.eventTypeFilter = type;
    this.generateCalendar();
  }

  getFilteredEvents(): any[] {
    if (this.eventTypeFilter === 'all') {
      return this.events;
    } else if (this.eventTypeFilter === 'group') {
      return this.events.filter(e => e.group);
    } else if (this.eventTypeFilter === 'club') {
      return this.events.filter(e => e.clubId || e.club);
    } else if (this.eventTypeFilter === 'general') {
      return this.events.filter(e => !e.group && !e.clubId && !e.club);
    }
    return this.events;
  }

  getGroupEventsCount(): number {
    return this.events.filter(e => e.group).length;
  }

  getClubEventsCount(): number {
    return this.events.filter(e => e.clubId || e.club).length;
  }

  getGeneralEventsCount(): number {
    return this.events.filter(e => !e.group && !e.clubId && !e.club).length;
  }

  getClubEvents(): any[] {
    return this.events
      .filter(e => e.clubId || e.club)
      .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime())
      .slice(0, 5);
  }

  getClubName(clubId: number): string {
    const club = this.clubs.find(c => c.id === clubId);
    return club ? club.name : 'Unknown Club';
  }

  getCurrentWeekDays(): any[] {
    const weekDays = [];
    const startOfWeek = new Date(this.currentDate);
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay());
    
    for (let i = 0; i < 7; i++) {
      const date = new Date(startOfWeek);
      date.setDate(date.getDate() + i);
      const today = new Date();
      
      weekDays.push({
        date,
        dayName: this.weekDays[i],
        dayNumber: date.getDate(),
        isToday: date.toDateString() === today.toDateString(),
        events: this.getEventsForDate(date)
      });
    }
    
    return weekDays;
  }

  getAverageEventDuration(): number {
    if (this.events.length === 0) return 2;
    const totalHours = this.events.reduce((sum: number, event: any) => {
      const start = new Date(event.startDate);
      const end = new Date(event.endDate);
      const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
      return sum + hours;
    }, 0);
    return Math.round(totalHours / this.events.length);
  }

  // Announcements Methods
  loadAnnouncements(): void {
    // Mock data for now
    this.announcements = [
      {
        id: 1,
        title: 'Welcome to CatchOPP Community',
        content: 'We are excited to have you here! Join our groups and participate in upcoming events.',
        author: 'Admin',
        createdAt: new Date(),
        targetGroup: null,
        views: 245
      }
    ];
    this.filteredAnnouncements = [...this.announcements];
  }

  setAnnouncementTab(tab: 'announcements' | 'posts'): void {
    this.announcementTab = tab;
  }

  filterAnnouncements(): void {
    let filtered = [...this.announcements];
    
    // Apply group filter
    if (this.announcementFilter !== 'all') {
      filtered = filtered.filter(a => a.targetGroup === parseInt(this.announcementFilter));
    }
    
    // Apply search filter
    if (this.announcementSearchQuery) {
      const query = this.announcementSearchQuery.toLowerCase();
      filtered = filtered.filter(a => 
        a.title.toLowerCase().includes(query) || 
        a.content.toLowerCase().includes(query)
      );
    }
    
    this.filteredAnnouncements = filtered;
  }

  openAnnouncementModal(announcement?: any): void {
    this.showAnnouncementModal = true;
    if (announcement) {
      this.editingAnnouncement = announcement;
      this.announcementForm = { ...announcement };
    } else {
      this.editingAnnouncement = null;
      this.announcementForm = {
        title: '',
        content: '',
        author: '',
        targetGroup: null
      };
    }
  }

  closeAnnouncementModal(): void {
    this.showAnnouncementModal = false;
    this.editingAnnouncement = null;
    this.announcementForm = {
      title: '',
      content: '',
      author: '',
      targetGroup: null
    };
  }

  saveAnnouncement(): void {
    if (!this.announcementForm.title || !this.announcementForm.content || !this.announcementForm.author) {
      alert('Please fill in all required fields');
      return;
    }

    if (this.editingAnnouncement) {
      // Update existing announcement
      const index = this.announcements.findIndex(a => a.id === this.editingAnnouncement.id);
      if (index !== -1) {
        this.announcements[index] = {
          ...this.editingAnnouncement,
          ...this.announcementForm,
          updatedAt: new Date()
        };
      }
      alert('Announcement updated successfully!');
    } else {
      // Create new announcement
      const newAnnouncement = {
        id: this.announcements.length + 1,
        ...this.announcementForm,
        createdAt: new Date(),
        views: 0
      };
      this.announcements.unshift(newAnnouncement);
      
      const targetName = this.announcementForm.targetGroup 
        ? this.getGroupName(this.announcementForm.targetGroup)
        : 'All groups';
      this.addActivity(targetName, `New announcement: "${newAnnouncement.title}"`, 'general');
      
      alert('Announcement created successfully!');
    }
    
    this.filterAnnouncements();
    this.closeAnnouncementModal();
  }

  deleteAnnouncement(id: number): void {
    if (!confirm('Are you sure you want to delete this announcement?')) {
      return;
    }

    const announcement = this.announcements.find(a => a.id === id);
    this.announcements = this.announcements.filter(a => a.id !== id);
    
    if (announcement) {
      this.addActivity('Announcements', `Announcement "${announcement.title}" deleted`, 'delete');
    }
    
    this.filterAnnouncements();
    alert('Announcement deleted successfully!');
  }

  // Posts Methods
  loadPosts(): void {
    this.postService.getAllPosts().subscribe({
      next: (posts) => {
        // Enrichir les posts avec les données d'affichage
        this.posts = posts.map(post => ({
          ...post,
          author: `User ${post.authorId || 'Unknown'}`,
          title: '',
          imageUrl: '',
          likes: 0,
          comments: 0,
          shares: 0,
          isLiked: false
        }));
        this.filteredPosts = [...this.posts];
        this.loadTopPosts();
      },
      error: (error) => {
        console.error('Error loading posts:', error);
        // Fallback to mock data if API fails
        this.loadMockPosts();
      }
    });
  }

  loadMockPosts(): void {
    // Mock data as fallback
    this.posts = [
      {
        id: 1,
        author: 'John Doe',
        title: 'Welcome to our community!',
        content: 'Hello everyone! Excited to be part of this amazing community. Looking forward to connecting with you all.',
        imageUrl: '',
        groupId: null,
        createdAt: new Date(),
        likes: 24,
        comments: 5,
        shares: 2,
        isLiked: false
      },
      {
        id: 2,
        author: 'Jane Smith',
        title: 'Upcoming Workshop',
        content: 'Don\'t miss our upcoming workshop on web development. Register now!',
        imageUrl: '',
        groupId: this.groups[0]?.id,
        createdAt: new Date(Date.now() - 3600000),
        likes: 18,
        comments: 3,
        shares: 1,
        isLiked: false
      },
      {
        id: 3,
        author: 'Mike Johnson',
        title: 'Great Networking Event',
        content: 'Had an amazing time at yesterday\'s networking event. Met so many talented people!',
        imageUrl: '',
        groupId: null,
        createdAt: new Date(Date.now() - 7200000),
        likes: 32,
        comments: 8,
        shares: 4,
        isLiked: false
      }
    ];
    this.filteredPosts = [...this.posts];
    this.loadTopPosts();
  }

  filterPosts(): void {
    let filtered = [...this.posts];
    
    // Apply group filter
    if (this.postFilter !== 'all') {
      filtered = filtered.filter(p => p.groupId === parseInt(this.postFilter));
    }
    
    // Apply search filter
    if (this.postSearchQuery) {
      const query = this.postSearchQuery.toLowerCase();
      filtered = filtered.filter(p => 
        (p.title && p.title.toLowerCase().includes(query)) || 
        p.content.toLowerCase().includes(query) ||
        p.author.toLowerCase().includes(query)
      );
    }
    
    // Apply sorting
    if (this.postSortBy === 'recent') {
      filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    } else if (this.postSortBy === 'popular') {
      filtered.sort((a, b) => (b.comments + b.shares) - (a.comments + a.shares));
    } else if (this.postSortBy === 'likes') {
      filtered.sort((a, b) => b.likes - a.likes);
    }
    
    this.filteredPosts = filtered;
  }

  openPostModal(post?: any): void {
    this.showPostModal = true;
    if (post) {
      this.editingPost = post;
      this.postForm = { ...post };
    } else {
      this.editingPost = null;
      this.postForm = {
        author: '',
        title: '',
        content: '',
        imageUrl: '',
        groupId: null
      };
    }
  }

  closePostModal(): void {
    this.showPostModal = false;
    this.editingPost = null;
    this.postForm = {
      author: '',
      title: '',
      content: '',
      imageUrl: '',
      groupId: null
    };
  }

  savePost(): void {
    if (!this.postForm.author || !this.postForm.content) {
      alert('Please fill in all required fields');
      return;
    }

    const postData: Post = {
      content: this.postForm.content,
      authorId: 1, // À remplacer par l'ID utilisateur réel
      isAnnouncement: false,
      group: this.postForm.groupId ? { id: this.postForm.groupId } : undefined
    };

    if (this.editingPost) {
      // Update existing post
      this.postService.updatePost(this.editingPost.id, postData).subscribe({
        next: (updatedPost) => {
          const index = this.posts.findIndex(p => p.id === this.editingPost.id);
          if (index !== -1) {
            this.posts[index] = {
              ...updatedPost,
              author: this.postForm.author,
              title: this.postForm.title,
              imageUrl: this.postForm.imageUrl,
              likes: this.posts[index].likes,
              comments: this.posts[index].comments,
              shares: this.posts[index].shares,
              isLiked: this.posts[index].isLiked
            };
          }
          this.filterPosts();
          this.closePostModal();
          alert('Post updated successfully!');
        },
        error: (error) => {
          console.error('Error updating post:', error);
          alert('Error updating post. Please try again.');
        }
      });
    } else {
      // Create new post
      this.postService.createPost(postData).subscribe({
        next: (newPost) => {
          this.posts.unshift({
            ...newPost,
            author: this.postForm.author,
            title: this.postForm.title,
            imageUrl: this.postForm.imageUrl,
            likes: 0,
            comments: 0,
            shares: 0,
            isLiked: false
          });
          
          const groupName = this.postForm.groupId 
            ? this.getGroupName(this.postForm.groupId)
            : 'Community';
          this.addActivity(groupName, `New post by ${this.postForm.author}`, 'general');
          
          this.filterPosts();
          this.closePostModal();
          alert('Post created successfully!');
        },
        error: (error) => {
          console.error('Error creating post:', error);
          alert('Error creating post. Please try again.');
        }
      });
    }
  }

  deletePost(id: number): void {
    if (!confirm('Are you sure you want to delete this post?')) {
      return;
    }

    this.postService.deletePost(id).subscribe({
      next: () => {
        const post = this.posts.find(p => p.id === id);
        this.posts = this.posts.filter(p => p.id !== id);
        
        if (post) {
          this.addActivity('Posts', `Post by ${post.author} deleted`, 'delete');
        }
        
        this.filterPosts();
        alert('Post deleted successfully!');
      },
      error: (error) => {
        console.error('Error deleting post:', error);
        alert('Error deleting post. Please try again.');
      }
    });
  }

  toggleLike(post: any): void {
    post.isLiked = !post.isLiked;
    post.likes = post.isLiked ? post.likes + 1 : post.likes - 1;
  }

  getTotalViews(): number {
    return this.announcements.reduce((sum, a) => sum + (a.views || 0), 0);
  }

  getTotalLikes(): number {
    return this.posts.reduce((sum, p) => sum + (p.likes || 0), 0);
  }

  // Groups Enhanced Methods
  filterGroups(): void {
    let filtered = [...this.groups];
    
    // Apply type filter
    if (this.groupFilter !== 'all') {
      const filterType = this.groupFilter === 'public' ? 'PUBLIC' : 
                        this.groupFilter === 'private' ? 'PRIVATE' : 'INVITE_ONLY';
      filtered = filtered.filter(g => g.type === filterType);
    }
    
    // Apply search filter
    if (this.groupSearchQuery) {
      const query = this.groupSearchQuery.toLowerCase();
      filtered = filtered.filter(g => 
        g.name.toLowerCase().includes(query) || 
        g.description.toLowerCase().includes(query)
      );
    }
    
    this.filteredGroupsList = filtered;
  }

  setGroupFilter(filter: string): void {
    this.groupFilter = filter;
    this.filterGroups();
  }

  toggleViewMode(): void {
    this.viewMode = this.viewMode === 'grid' ? 'list' : 'grid';
  }

  getGroupGradient(group: Group): string {
    const gradients = [
      'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
      'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
      'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
      'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
      'linear-gradient(135deg, #30cfd0 0%, #330867 100%)',
      'linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)',
      'linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)'
    ];
    const index = (group.id || 0) % gradients.length;
    return gradients[index];
  }

  getRandomMembers(): number {
    return Math.floor(Math.random() * 150) + 10;
  }

  getRandomActivity(): string {
    const activities = ['High Activity', 'Growing', 'Trending', 'Popular'];
    return activities[Math.floor(Math.random() * activities.length)];
  }

  getGroupEventsCountById(groupId: number | undefined): number {
    if (!groupId) return 0;
    return this.events.filter(e => e.group?.id === groupId).length;
  }

  viewGroupDetails(group: Group): void {
    // Navigate to group details page
    this.router.navigate(['/groups', group.id]);
  }

  // Stats Methods
  getNewGroupsThisWeek(): number {
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    return this.groups.filter(g => {
      if (!g.createdAt) return false;
      return new Date(g.createdAt) > oneWeekAgo;
    }).length;
  }

  getTotalMembers(): number {
    return this.groups.length * 45; // Mock calculation
  }

  getNewMembersThisWeek(): number {
    return Math.floor(this.getTotalMembers() * 0.08);
  }

  getPublicGroupsCount(): number {
    return this.groups.filter(g => g.type === 'PUBLIC').length;
  }

  getPrivateGroupsCount(): number {
    return this.groups.filter(g => g.type === 'PRIVATE' || g.type === 'INVITE_ONLY').length;
  }

  getEngagementRate(): number {
    return Math.floor(Math.random() * 30) + 65; // Mock: 65-95%
  }

  // Overview Statistics Methods
  setDateRange(range: string): void {
    this.dateRange = range;
  }

  getTotalAttendees(): number {
    return this.events.length * 45; // Mock calculation
  }

  getNewEventsThisWeek(): number {
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    return this.events.filter(e => {
      if (!e.createdAt) return false;
      return new Date(e.createdAt) > oneWeekAgo;
    }).length || Math.floor(Math.random() * 5) + 1;
  }

  getTotalInterests(): number {
    const allInterests = this.clubs
      .map(c => c.interests?.split(',').length || 0)
      .reduce((sum, count) => sum + count, 0);
    return allInterests || this.clubs.length * 3;
  }

  getClubMembers(): number {
    return this.clubs.length * 35; // Mock calculation
  }

  getTotalPosts(): number {
    return Math.floor(Math.random() * 500) + 200; // Mock: 200-700 posts
  }

  getPostsThisWeek(): number {
    return Math.floor(Math.random() * 50) + 20; // Mock: 20-70 posts
  }

  getTotalComments(): number {
    return this.getTotalPosts() * 3; // Mock: 3 comments per post average
  }

  // Dashboard Widgets Methods
  loadTrendingTopics(): void {
    this.trendingTopics = [
      { tag: '#WebDevelopment', count: 45, trending: 'up' },
      { tag: '#Design', count: 38, trending: 'up' },
      { tag: '#Networking', count: 32, trending: 'down' },
      { tag: '#Innovation', count: 28, trending: 'up' },
      { tag: '#Community', count: 24, trending: 'up' }
    ];
  }



  loadTopPosts(): void {
    // Fetch posts with reactions and comments data from backend
    this.postService.getPostsWithEngagement().subscribe({
      next: (postsWithEngagement) => {
        // Sort by engagement score and get top 5
        this.topPosts = postsWithEngagement
          .map(post => ({
            ...post,
            author: `User ${post.authorId || 'Unknown'}`,
            authorInitials: `User ${post.authorId || 'Unknown'}`.split(' ').map((n: string) => n[0]).join(''),
            authorColor: this.getRandomColor(),
            likes: post.totalReactions || 0,
            comments: post.totalComments || 0
          }))
          .sort((a, b) => (b.engagementScore || 0) - (a.engagementScore || 0))
          .slice(0, 5);
      },
      error: (error) => {
        console.error('Error loading top posts:', error);
        // Fallback to existing posts data
        this.topPosts = [...this.posts]
          .sort((a, b) => (b.likes || 0) - (a.likes || 0))
          .slice(0, 5)
          .map(post => ({
            ...post,
            authorInitials: post.author.split(' ').map((n: string) => n[0]).join(''),
            authorColor: this.getRandomColor()
          }));
      }
    });
  }

  getRandomColor(): string {
    const colors = [
      'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
      'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
      'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
      'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
      'linear-gradient(135deg, #30cfd0 0%, #330867 100%)',
      'linear-gradient(135deg, #ff9a9e 0%, #fad0c4 100%)',
      'linear-gradient(135deg, #fbc2eb 0%, #a6c1ee 100%)',
      'linear-gradient(135deg, #fdcbf1 0%, #e6dee9 100%)',
      'linear-gradient(135deg, #ff6e7f 0%, #bfe9ff 100%)',
      'linear-gradient(135deg, #e0c3fc 0%, #8ec5fc 100%)',
      'linear-gradient(135deg, #f77062 0%, #fe5196 100%)'
    ];
    return colors[Math.floor(Math.random() * colors.length)];
  }

  getCommunityScore(): number {
    return Math.floor(Math.random() * 20) + 75; // Mock: 75-95%
  }

  getGrowthRate(): number {
    return Math.floor(Math.random() * 15) + 10; // Mock: 10-25%
  }

  viewStatistics(): void {
    alert('Statistics view - Coming soon!');
  }

  viewEvents(): void {
    this.router.navigate(['/events']);
  }

  createGroup(): void {
    this.openGroupModal();
  }

  viewAllEvents(): void {
    this.router.navigate(['/events']);
  }

  editClub(clubId: number): void {
    const club = this.clubs.find(c => c.id === clubId);
    if (club) {
      this.openClubModal(club);
    }
  }

  createClub(): void {
    this.openClubModal();
  }

  pauseClub(): void {
    if (!this.selectedClub) return;
    
    if (!confirm(`Are you sure you want to pause "${this.selectedClub.name}"?\n\nMembers will not be able to access this club while it's paused.`)) {
      return;
    }

    this.clubService.pauseClub(this.selectedClub.id).subscribe({
      next: (updated) => {
        // Update the club in the list
        const index = this.clubs.findIndex(c => c.id === updated.id);
        if (index !== -1) {
          this.clubs[index] = updated;
        }
        this.selectedClub = updated;
        this.filteredClubs = [...this.clubs];
        this.filterClubs();
        
        this.notificationService.addNotification({
          type: 'club',
          title: 'Club Paused',
          message: `"${updated.name}" has been paused successfully`,
          importance: 'normal'
        });
        
        this.addActivity(updated.name, 'Club paused by admin', 'update');
      },
      error: (err) => {
        console.error('Error pausing club:', err);
        alert('Failed to pause club. Please try again.');
      }
    });
  }

  unpauseClub(): void {
    if (!this.selectedClub) return;
    
    if (!confirm(`Are you sure you want to unpause "${this.selectedClub.name}"?\n\nMembers will be able to access this club again.`)) {
      return;
    }

    this.clubService.unpauseClub(this.selectedClub.id).subscribe({
      next: (updated) => {
        // Update the club in the list
        const index = this.clubs.findIndex(c => c.id === updated.id);
        if (index !== -1) {
          this.clubs[index] = updated;
        }
        this.selectedClub = updated;
        this.filteredClubs = [...this.clubs];
        this.filterClubs();
        
        this.notificationService.addNotification({
          type: 'club',
          title: 'Club Activated',
          message: `"${updated.name}" is now active again`,
          importance: 'normal'
        });
        
        this.addActivity(updated.name, 'Club activated by admin', 'update');
      },
      error: (err) => {
        console.error('Error unpausing club:', err);
        alert('Failed to unpause club. Please try again.');
      }
    });
  }

  pauseClubById(clubId: number): void {
    const club = this.clubs.find(c => c.id === clubId);
    if (!club) return;
    
    if (!confirm(`Are you sure you want to pause "${club.name}"?\n\nMembers will not be able to access this club while it's paused.`)) {
      return;
    }

    this.clubService.pauseClub(clubId).subscribe({
      next: (updated) => {
        // Update the club in the list
        const index = this.clubs.findIndex(c => c.id === updated.id);
        if (index !== -1) {
          this.clubs[index] = updated;
        }
        this.filteredClubs = [...this.clubs];
        this.filterClubs();
        
        this.notificationService.addNotification({
          type: 'club',
          title: 'Club Paused',
          message: `"${updated.name}" has been paused successfully`,
          importance: 'normal'
        });
        
        this.addActivity(updated.name, 'Club paused by admin', 'update');
      },
      error: (err) => {
        console.error('Error pausing club:', err);
        alert('Failed to pause club. Please try again.');
      }
    });
  }

  unpauseClubById(clubId: number): void {
    const club = this.clubs.find(c => c.id === clubId);
    if (!club) return;
    
    if (!confirm(`Are you sure you want to unpause "${club.name}"?\n\nMembers will be able to access this club again.`)) {
      return;
    }

    this.clubService.unpauseClub(clubId).subscribe({
      next: (updated) => {
        // Update the club in the list
        const index = this.clubs.findIndex(c => c.id === updated.id);
        if (index !== -1) {
          this.clubs[index] = updated;
        }
        this.filteredClubs = [...this.clubs];
        this.filterClubs();
        
        this.notificationService.addNotification({
          type: 'club',
          title: 'Club Activated',
          message: `"${updated.name}" is now active again`,
          importance: 'normal'
        });
        
        this.addActivity(updated.name, 'Club activated by admin', 'update');
      },
      error: (err) => {
        console.error('Error unpausing club:', err);
        alert('Failed to unpause club. Please try again.');
      }
    });
  }

  // Event CRUD Methods
  openEventModal(event?: any): void {
    this.showEventModal = true;
    if (event) {
      this.editingEvent = event;
      // Convert dates to datetime-local format
      const startDate = new Date(event.startDate);
      const endDate = new Date(event.endDate);
      this.eventForm = {
        title: event.title,
        description: event.description,
        location: event.location,
        startDate: this.formatDateTimeLocal(startDate),
        endDate: this.formatDateTimeLocal(endDate),
        groupId: event.group?.id || null
      };
    } else {
      this.editingEvent = null;
      this.eventForm = {
        title: '',
        description: '',
        location: '',
        startDate: '',
        endDate: '',
        groupId: null
      };
    }
  }

  closeEventModal(): void {
    this.showEventModal = false;
    this.editingEvent = null;
    this.eventForm = {
      title: '',
      description: '',
      location: '',
      startDate: '',
      endDate: '',
      groupId: null
    };
  }

  saveEvent(): void {
    if (!this.eventForm.title || !this.eventForm.description || 
        !this.eventForm.location || !this.eventForm.startDate || !this.eventForm.endDate) {
      alert('Please fill in all required fields');
      return;
    }

    // Validate dates
    const startDate = new Date(this.eventForm.startDate);
    const endDate = new Date(this.eventForm.endDate);
    
    if (endDate <= startDate) {
      alert('End date must be after start date');
      return;
    }

    const eventData: any = {
      title: this.eventForm.title,
      description: this.eventForm.description,
      location: this.eventForm.location,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      status: 'APPROVED' // Automatically approved
    };

    if (this.eventForm.groupId) {
      eventData.group = { id: this.eventForm.groupId };
    }

    if (this.editingEvent && this.editingEvent.id) {
      // Update existing event
      this.eventService.updateEvent(this.editingEvent.id, eventData).subscribe({
        next: (updated) => {
          const index = this.events.findIndex(e => e.id === updated.id);
          if (index !== -1) {
            this.events[index] = updated;
          }
          this.allEvents = [...this.events].sort((a: any, b: any) => 
            new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
          );
          this.updateUpcomingEvents();
          this.closeEventModal();
          this.updateStats();
          
          const groupName = this.eventForm.groupId ? this.getGroupName(this.eventForm.groupId) : 'General';
          this.addActivity(groupName, `Event "${updated.title}" updated`, 'event');
          
          alert('Event updated successfully!');
        },
        error: (err) => {
          console.error('Error updating event:', err);
          alert('Failed to update event. Please try again.');
        }
      });
    } else {
      // Create new event
      this.eventService.createEvent(eventData).subscribe({
        next: (created) => {
          this.events.push(created);
          this.allEvents = [...this.events].sort((a: any, b: any) => 
            new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
          );
          this.updateUpcomingEvents();
          this.closeEventModal();
          this.updateStats();
          
          const groupName = this.eventForm.groupId ? this.getGroupName(this.eventForm.groupId) : 'General';
          this.addActivity(groupName, `New event "${created.title}" created`, 'event');
          
          alert('Event created successfully!');
        },
        error: (err) => {
          console.error('Error creating event:', err);
          alert('Failed to create event. Please try again.');
        }
      });
    }
  }

  deleteEvent(eventId: number): void {
    if (!confirm('Are you sure you want to delete this event?')) {
      return;
    }

    const event = this.events.find(e => e.id === eventId);
    const eventTitle = event ? event.title : 'Event';
    const groupName = event?.group ? this.getGroupName(event.group.id) : 'General';

    this.eventService.deleteEvent(eventId).subscribe({
      next: () => {
        this.events = this.events.filter(e => e.id !== eventId);
        this.allEvents = [...this.events].sort((a: any, b: any) => 
          new Date(a.startDate).getTime() - new Date(b.startDate).getTime()
        );
        this.updateUpcomingEvents();
        this.updateStats();
        this.addActivity(groupName, `Event "${eventTitle}" deleted`, 'delete');
        alert('Event deleted successfully!');
      },
      error: (err) => {
        console.error('Error deleting event:', err);
        alert('Failed to delete event. Please try again.');
      }
    });
  }

  updateUpcomingEvents(): void {
    const now = new Date();
    this.upcomingEvents = this.events
      .filter((e: any) => new Date(e.startDate) > now)
      .sort((a: any, b: any) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime())
      .slice(0, 5);
  }

  getGroupName(groupId: number): string {
    const group = this.groups.find(g => g.id === groupId);
    return group ? group.name : 'Unknown Group';
  }

  formatDateTimeLocal(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
  }

  viewClub(clubId: number): void {
    const club = this.clubs.find(c => c.id === clubId);
    if (club) {
      this.selectedClub = club;
    }
  }

  viewEvent(eventId: number): void {
    this.router.navigate(['/events', eventId]);
  }

  createEvent(): void {
    this.openEventModal();
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'APPROVED': return 'status-approved';
      case 'PENDING': return 'status-pending';
      case 'REJECTED': return 'status-rejected';
      default: return '';
    }
  }

  isUpcoming(event: any): boolean {
    return new Date(event.startDate) > new Date();
  }

  // Dashboard Filtering and Sorting Methods
  initializeDashboardFilters(): void {
    this.filteredGroups = [...this.groups];
    this.filteredEvents = [...this.allEvents];
    this.filteredActivities = [...this.recentActivities];
  }

  filterDashboardContent(): void {
    // Filter groups
    this.filteredGroups = this.filterBySearchAndDate(this.groups, 'group');
    
    // Filter events
    this.filteredEvents = this.filterBySearchAndDate(this.allEvents, 'event');
    
    // Filter clubs - use existing filteredClubs
    const tempFilteredClubs = this.filterBySearchAndDate(this.clubs, 'club');
    this.filteredClubs = tempFilteredClubs;
    
    // Filter activities
    this.filteredActivities = this.filterActivities();
    
    // Apply sorting
    this.sortDashboardContent();
  }

  filterBySearchAndDate(items: any[], type: string): any[] {
    let filtered = [...items];
    
    // Apply type filter
    if (this.dashboardFilter !== 'all') {
      if (type === 'group' && this.dashboardFilter !== 'groups') return [];
      if (type === 'event' && this.dashboardFilter !== 'events') return [];
      if (type === 'club' && this.dashboardFilter !== 'clubs') return [];
    }
    
    // Apply search filter
    if (this.dashboardSearchQuery) {
      const query = this.dashboardSearchQuery.toLowerCase();
      filtered = filtered.filter(item => {
        const name = item.name || item.title || '';
        const description = item.description || '';
        return name.toLowerCase().includes(query) || 
               description.toLowerCase().includes(query);
      });
    }
    
    // Apply date range filter
    if (this.dashboardDateRange !== 'all') {
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      
      filtered = filtered.filter(item => {
        const itemDate = new Date(item.createdAt || item.startDate || now);
        
        switch (this.dashboardDateRange) {
          case 'today':
            return itemDate >= today;
          case 'week':
            const weekAgo = new Date(today);
            weekAgo.setDate(weekAgo.getDate() - 7);
            return itemDate >= weekAgo;
          case 'month':
            const monthAgo = new Date(today);
            monthAgo.setMonth(monthAgo.getMonth() - 1);
            return itemDate >= monthAgo;
          default:
            return true;
        }
      });
    }
    
    return filtered;
  }

  filterActivities(): any[] {
    let filtered = [...this.recentActivities];
    
    // Apply type filter
    if (this.dashboardFilter !== 'all' && this.dashboardFilter !== 'posts') {
      filtered = filtered.filter(activity => {
        if (this.dashboardFilter === 'groups') {
          return activity.type === 'create' || activity.type === 'update' || activity.type === 'delete';
        }
        if (this.dashboardFilter === 'events') {
          return activity.type === 'event';
        }
        if (this.dashboardFilter === 'clubs') {
          return activity.description.toLowerCase().includes('club');
        }
        return true;
      });
    }
    
    // Apply search filter
    if (this.dashboardSearchQuery) {
      const query = this.dashboardSearchQuery.toLowerCase();
      filtered = filtered.filter(activity => 
        activity.groupName.toLowerCase().includes(query) || 
        activity.description.toLowerCase().includes(query)
      );
    }
    
    return filtered;
  }

  sortDashboardContent(): void {
    // Sort groups
    this.filteredGroups = this.sortItems(this.filteredGroups, 'group');
    
    // Sort events
    this.filteredEvents = this.sortItems(this.filteredEvents, 'event');
    
    // Sort clubs - use existing filteredClubs
    const tempSortedClubs = this.sortItems(this.filteredClubs, 'club');
    this.filteredClubs = tempSortedClubs;
  }

  sortItems(items: any[], type: string): any[] {
    const sorted = [...items];
    
    switch (this.dashboardSortBy) {
      case 'recent':
        return sorted.sort((a, b) => {
          const dateA = new Date(a.createdAt || a.startDate || 0).getTime();
          const dateB = new Date(b.createdAt || b.startDate || 0).getTime();
          return dateB - dateA;
        });
      
      case 'oldest':
        return sorted.sort((a, b) => {
          const dateA = new Date(a.createdAt || a.startDate || 0).getTime();
          const dateB = new Date(b.createdAt || b.startDate || 0).getTime();
          return dateA - dateB;
        });
      
      case 'popular':
        return sorted.sort((a, b) => {
          const popularityA = (a.membersCount || 0) + (a.eventsCount || 0) + (a.attendees || 0);
          const popularityB = (b.membersCount || 0) + (b.eventsCount || 0) + (b.attendees || 0);
          return popularityB - popularityA;
        });
      
      case 'name':
        return sorted.sort((a, b) => {
          const nameA = (a.name || a.title || '').toLowerCase();
          const nameB = (b.name || b.title || '').toLowerCase();
          return nameA.localeCompare(nameB);
        });
      
      default:
        return sorted;
    }
  }

  resetDashboardFilters(): void {
    this.dashboardSearchQuery = '';
    this.dashboardFilter = 'all';
    this.dashboardSortBy = 'recent';
    this.dashboardDateRange = 'all';
    this.filterDashboardContent();
  }

  getFilteredGroupsForDisplay(): Group[] {
    return this.dashboardFilter === 'all' || this.dashboardFilter === 'groups' 
      ? this.filteredGroups.slice(0, 3) 
      : [];
  }

  getFilteredEventsForDisplay(): any[] {
    return this.dashboardFilter === 'all' || this.dashboardFilter === 'events' 
      ? this.filteredEvents.slice(0, 3) 
      : [];
  }

  getFilteredClubsForDisplay(): any[] {
    return this.dashboardFilter === 'all' || this.dashboardFilter === 'clubs' 
      ? this.filteredClubs.slice(0, 3) 
      : [];
  }

  getFilteredActivitiesForDisplay(): any[] {
    return this.filteredActivities.slice(0, 10);
  }

  // Clubs Section Methods
  filterClubs(): void {
    let filtered = [...this.clubs];
    
    // Apply status filter
    if (this.clubFilter === 'active') {
      // All clubs are active by default
      filtered = filtered;
    }
    
    // Apply search filter
    if (this.clubSearchQuery) {
      const query = this.clubSearchQuery.toLowerCase();
      filtered = filtered.filter(club => 
        club.name.toLowerCase().includes(query) || 
        club.description.toLowerCase().includes(query) ||
        (club.interests && club.interests.toLowerCase().includes(query))
      );
    }
    
    this.filteredClubsList = filtered;
  }

  setClubFilter(filter: string): void {
    this.clubFilter = filter;
    this.filterClubs();
  }

  toggleClubViewMode(): void {
    this.clubViewMode = this.clubViewMode === 'grid' ? 'list' : 'grid';
  }

  getClubGradient(club: any): string {
    const gradients = [
      'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
      'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
      'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
      'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
      'linear-gradient(135deg, #30cfd0 0%, #330867 100%)',
      'linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)',
      'linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)',
      'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
    ];
    const index = (club.id || 0) % gradients.length;
    return gradients[index];
  }
}
