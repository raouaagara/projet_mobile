import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { GroupService } from '../group.service';
import { EventService } from '../event.service';
import { ClubService } from '../club.service';
import { PostService } from '../post.service';
import { GroupMemberService } from '../group-member.service';
import { NotificationService } from '../notification.service';
import { GroupType } from '../models';

interface DashboardStats {
  totalGroups: number;
  totalEvents: number;
  totalClubs: number;
  totalMembers: number;
  totalPosts: number;
  publicGroups: number;
  privateGroups: number;
  invitationOnlyGroups: number;
  recentGroups: any[];
  recentEvents: any[];
  groupsGrowth: number;
  eventsGrowth: number;
}

@Component({
  selector: 'app-admin-dashboard',
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.css']
})
export class AdminDashboardComponent implements OnInit {
  GroupType = GroupType; // Expose enum to template
  
  stats: DashboardStats = {
    totalGroups: 0,
    totalEvents: 0,
    totalClubs: 0,
    totalMembers: 0,
    totalPosts: 0,
    publicGroups: 0,
    privateGroups: 0,
    invitationOnlyGroups: 0,
    recentGroups: [],
    recentEvents: [],
    groupsGrowth: 0,
    eventsGrowth: 0
  };

  groups: any[] = [];
  events: any[] = [];
  filteredEventsAdmin: any[] = [];
  filteredGroupsAdmin: any[] = [];
  filteredClubsAdmin: any[] = [];
  clubs: any[] = [];
  loading = false;
  selectedTab: 'overview' | 'groups' | 'events' | 'clubs' = 'overview';
  eventSearchTerm = '';
  eventStatusFilter: 'all' | 'PENDING' | 'APPROVED' | 'REJECTED' = 'all';
  groupSearchTerm = '';
  groupTypeFilter: 'all' | 'PUBLIC' | 'PRIVATE' | 'INVITE_ONLY' = 'all';
  clubSearchTerm = '';

  // Modal states
  isGroupModalOpen = false;
  isEventModalOpen = false;
  editingGroup: any = null;
  editingEvent: any = null;

  groupForm = {
    name: '',
    description: '',
    type: GroupType.PUBLIC,
    bannerUrl: ''
  };

  eventForm = {
    title: '',
    description: '',
    location: '',
    startDate: '',
    endDate: '',
    groupId: 0
  };

  constructor(
    public router: Router,
    private route: ActivatedRoute,
    private groupService: GroupService,
    private eventService: EventService,
    private clubService: ClubService,
    private postService: PostService,
    private memberService: GroupMemberService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadDashboardData();
    
    // Check for tab query parameter
    this.route.queryParams.subscribe(params => {
      if (params['tab']) {
        this.selectedTab = params['tab'];
      }
    });
  }

  loadDashboardData(): void {
    this.loading = true;
    
    // Load all data
    this.groupService.getAllGroups().subscribe({
      next: (groups) => {
        this.groups = groups;
        this.stats.totalGroups = groups.length;
        this.stats.publicGroups = groups.filter(g => g.type === GroupType.PUBLIC).length;
        this.stats.privateGroups = groups.filter(g => g.type === GroupType.PRIVATE).length;
        this.stats.invitationOnlyGroups = groups.filter(g => g.type === GroupType.INVITE_ONLY).length;
        this.stats.recentGroups = groups.slice(0, 5);
        this.stats.groupsGrowth = this.calculateGrowth(groups.length);
        this.filterGroups();
      }
    });

    this.eventService.getAllEvents().subscribe({
      next: (events) => {
        this.events = events;
        this.stats.totalEvents = events.length;
        this.stats.recentEvents = events.slice(0, 5);
        this.stats.eventsGrowth = this.calculateGrowth(events.length);
        this.filterEvents();
      }
    });

    this.clubService.getAllClubs().subscribe({
      next: (clubs) => {
        this.clubs = clubs;
        this.stats.totalClubs = clubs.length;
        this.filterClubs();
      }
    });

    this.postService.getAllPosts().subscribe({
      next: (posts) => {
        this.stats.totalPosts = posts.length;
      }
    });

    this.memberService.getAllMembers().subscribe({
      next: (members) => {
        this.stats.totalMembers = members.length;
        this.loading = false;
      },
      error: () => {
        this.loading = false;
      }
    });
  }

  calculateGrowth(total: number): number {
    // Simulate growth percentage (in real app, compare with previous period)
    return Math.floor(Math.random() * 30) + 5;
  }

  selectTab(tab: 'overview' | 'groups' | 'events' | 'clubs'): void {
    this.selectedTab = tab;
  }

  // Group Management
  openCreateGroupModal(): void {
    this.editingGroup = null;
    this.groupForm = {
      name: '',
      description: '',
      type: GroupType.PUBLIC,
      bannerUrl: ''
    };
    this.isGroupModalOpen = true;
  }

  openEditGroupModal(group: any): void {
    this.editingGroup = group;
    this.groupForm = {
      name: group.name,
      description: group.description,
      type: group.type,
      bannerUrl: group.bannerUrl || ''
    };
    this.isGroupModalOpen = true;
  }

  closeGroupModal(): void {
    this.isGroupModalOpen = false;
  }

  saveGroup(): void {
    const groupData = {
      name: this.groupForm.name.trim(),
      description: this.groupForm.description.trim(),
      type: this.groupForm.type,
      bannerUrl: this.groupForm.bannerUrl.trim() || undefined
    };

    if (!groupData.name || !groupData.description) {
      return;
    }

    if (this.editingGroup) {
      this.groupService.updateGroup(this.editingGroup.id, groupData).subscribe({
        next: () => {
          this.loadDashboardData();
          this.closeGroupModal();
        }
      });
    } else {
      this.groupService.createGroup(groupData).subscribe({
        next: (created) => {
          // Send notification about new group
          this.notificationService.addNotification({
            type: 'group',
            title: 'New Group Created',
            message: `"${created.name}" group is now available to join`,
            importance: 'normal',
            relatedRoute: `/groups/${created.id}`
          });
          
          this.loadDashboardData();
          this.closeGroupModal();
        }
      });
    }
  }

  deleteGroup(group: any): void {
    if (confirm(`Are you sure you want to delete "${group.name}"? This will also delete all posts, events, and members associated with this group.`)) {
      this.groupService.deleteGroup(group.id).subscribe({
        next: () => {
          alert(`Group "${group.name}" deleted successfully!`);
          this.loadDashboardData();
        },
        error: (err) => {
          console.error('Error deleting group:', err);
          alert('Failed to delete group. Please try again.');
        }
      });
    }
  }

  viewGroup(groupId: number): void {
    this.router.navigate(['/groups', groupId]);
  }

  navigateToClubDashboard(): void {
    this.router.navigate(['/ClubDashboard']);
  }

  getTypeLabel(type: string): string {
    const labels: any = {
      'PUBLIC': 'Public',
      'PRIVATE': 'Private',
      'INVITE_ONLY': 'Invitation Only'
    };
    return labels[type] || type;
  }

  getTypeClass(type: string): string {
    const classes: any = {
      'PUBLIC': 'badge-public',
      'PRIVATE': 'badge-private',
      'INVITE_ONLY': 'badge-invitation'
    };
    return classes[type] || '';
  }

  // Event Management
  openCreateEventModal(): void {
    this.editingEvent = null;
    this.eventForm = {
      title: '',
      description: '',
      location: '',
      startDate: '',
      endDate: '',
      groupId: this.groups.length > 0 ? this.groups[0].id : 0
    };
    this.isEventModalOpen = true;
  }

  openEditEventModal(event: any): void {
    this.editingEvent = event;
    this.eventForm = {
      title: event.title,
      description: event.description,
      location: event.location,
      startDate: this.formatDateForInput(event.startDate),
      endDate: this.formatDateForInput(event.endDate),
      groupId: event.group?.id || 0
    };
    this.isEventModalOpen = true;
  }

  closeEventModal(): void {
    this.isEventModalOpen = false;
  }

  saveEvent(): void {
    const eventData = {
      title: this.eventForm.title.trim(),
      description: this.eventForm.description.trim(),
      location: this.eventForm.location.trim(),
      startDate: this.eventForm.startDate,
      endDate: this.eventForm.endDate,
      group: { id: this.eventForm.groupId }
    };

    if (!eventData.title || !eventData.description || !eventData.location || !eventData.startDate || !eventData.endDate) {
      alert('All fields are required');
      return;
    }

    if (this.editingEvent) {
      this.eventService.updateEvent(this.editingEvent.id, eventData).subscribe({
        next: () => {
          this.loadDashboardData();
          this.closeEventModal();
        },
        error: (err) => {
          console.error('Update event error:', err);
          alert('Error updating event');
        }
      });
    } else {
      this.eventService.createEvent(eventData).subscribe({
        next: (created) => {
          // Send notification about new event
          this.notificationService.addNotification({
            type: 'event',
            title: 'New Event Created',
            message: `"${created.title}" has been scheduled at ${created.location}`,
            importance: 'high',
            relatedRoute: `/events`
          });
          
          this.loadDashboardData();
          this.closeEventModal();
        },
        error: (err) => {
          console.error('Create event error:', err);
          alert('Error creating event');
        }
      });
    }
  }

  deleteEvent(event: any): void {
    if (confirm(`Are you sure you want to delete "${event.title}"?`)) {
      this.eventService.deleteEvent(event.id).subscribe({
        next: () => {
          this.loadDashboardData();
        },
        error: (err) => {
          console.error('Delete event error:', err);
          alert('Error deleting event');
        }
      });
    }
  }

  formatDateForInput(dateString: string): string {
    if (!dateString) return '';
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
  }

  approveEvent(event: any): void {
    if (confirm(`Approve event "${event.title}"?`)) {
      this.eventService.approveEvent(event.id).subscribe({
        next: () => {
          this.loadDashboardData();
          alert('Event approved successfully!');
        },
        error: (err) => {
          console.error('Error approving event:', err);
          alert('Error approving event');
        }
      });
    }
  }

  rejectEvent(event: any): void {
    if (confirm(`Reject event "${event.title}"? This will hide it from users.`)) {
      this.eventService.rejectEvent(event.id).subscribe({
        next: () => {
          this.loadDashboardData();
          alert('Event rejected');
        },
        error: (err) => {
          console.error('Error rejecting event:', err);
          alert('Error rejecting event');
        }
      });
    }
  }

  filterEvents(): void {
    let filtered = this.events;

    // Filter by status
    if (this.eventStatusFilter !== 'all') {
      filtered = filtered.filter(e => e.status === this.eventStatusFilter);
    }

    // Filter by search term
    if (this.eventSearchTerm) {
      const term = this.eventSearchTerm.toLowerCase();
      filtered = filtered.filter(e =>
        e.title.toLowerCase().includes(term) ||
        e.location.toLowerCase().includes(term) ||
        (e.description && e.description.toLowerCase().includes(term))
      );
    }

    this.filteredEventsAdmin = filtered;
  }

  setEventFilter(filter: 'all' | 'PENDING' | 'APPROVED' | 'REJECTED'): void {
    this.eventStatusFilter = filter;
    this.filterEvents();
  }

  formatDay(dateString: string): string {
    return new Date(dateString).getDate().toString();
  }

  formatMonth(dateString: string): string {
    return new Date(dateString).toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
  }

  filterGroups(): void {
    let filtered = this.groups;

    // Filter by type
    if (this.groupTypeFilter !== 'all') {
      filtered = filtered.filter(g => g.type === this.groupTypeFilter);
    }

    // Filter by search term
    if (this.groupSearchTerm) {
      const term = this.groupSearchTerm.toLowerCase();
      filtered = filtered.filter(g =>
        g.name.toLowerCase().includes(term) ||
        (g.description && g.description.toLowerCase().includes(term))
      );
    }

    this.filteredGroupsAdmin = filtered;
  }

  setGroupFilter(filter: 'all' | 'PUBLIC' | 'PRIVATE' | 'INVITE_ONLY'): void {
    this.groupTypeFilter = filter;
    this.filterGroups();
  }

  filterClubs(): void {
    let filtered = this.clubs;

    // Filter by search term
    if (this.clubSearchTerm) {
      const term = this.clubSearchTerm.toLowerCase();
      filtered = filtered.filter(c =>
        c.name.toLowerCase().includes(term) ||
        (c.description && c.description.toLowerCase().includes(term)) ||
        (c.interests && c.interests.toLowerCase().includes(term))
      );
    }

    this.filteredClubsAdmin = filtered;
  }
}
