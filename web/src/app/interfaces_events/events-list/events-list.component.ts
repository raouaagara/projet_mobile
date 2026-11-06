import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { EventService } from '../event.service';
import { GroupService } from '../group.service';
import { NotificationService } from '../notification.service';

@Component({
  selector: 'app-events-list',
  templateUrl: './events-list.component.html',
  styleUrls: ['./events-list.component.css']
})
export class EventsListComponent implements OnInit {
  events: any[] = [];
  filteredEvents: any[] = [];
  featuredEvents: any[] = [];
  availableGroups: any[] = [];
  loading = false;
  searchTerm = '';
  selectedFilter: 'all' | 'upcoming' | 'past' = 'upcoming';
  statusFilter: 'all' | 'upcoming' | 'past' = 'all';
  typeFilter: 'all' | 'online' | 'in-person' = 'all';
  isCreateModalOpen = false;
  isCreateEventModalOpen = false;

  // Stats
  upcomingEventsCount = 0;
  totalAttendeesCount = 0;
  uniqueLocationsCount = 0;

  // Categories
  popularCategories = [
    { name: 'Technology', icon: 'fa fa-laptop-code' },
    { name: 'Business', icon: 'fa fa-briefcase' },
    { name: 'Design', icon: 'fa fa-palette' },
    { name: 'Networking', icon: 'fa fa-handshake' }
  ];

  newEventForm = {
    title: '',
    description: '',
    location: '',
    startDate: '',
    endDate: '',
    groupId: 0,
    status: 'PENDING'
  };

  constructor(
    private router: Router,
    private eventService: EventService,
    private groupService: GroupService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.loadEvents();
    this.loadGroups();
  }

  loadEvents(): void {
    this.loading = true;
    this.eventService.getAllEvents().subscribe({
      next: (events) => {
        // Only show approved events to regular users
        this.events = events.filter(e => e.status === 'APPROVED' || !e.status);
        this.featuredEvents = this.events.slice(0, 1); // First event as featured
        this.updateStats();
        this.filterEvents();
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading events:', err);
        this.loading = false;
      }
    });
  }

  updateStats(): void {
    this.upcomingEventsCount = this.events.filter(e => this.isUpcoming(e)).length;
    this.totalAttendeesCount = this.events.reduce((sum, e) => sum + (e.attendeesCount || 0), 0);
    this.uniqueLocationsCount = new Set(this.events.map(e => e.location)).size;
  }

  filterEvents(): void {
    const now = new Date();
    let filtered = [...this.events]; // Create a copy

    // Filter by status (upcoming/past)
    if (this.statusFilter === 'upcoming') {
      filtered = filtered.filter(e => new Date(e.startDate) >= now);
    } else if (this.statusFilter === 'past') {
      filtered = filtered.filter(e => new Date(e.endDate) < now);
    }

    // Also apply selectedFilter for backward compatibility
    if (this.selectedFilter === 'upcoming') {
      filtered = filtered.filter(e => new Date(e.startDate) >= now);
    } else if (this.selectedFilter === 'past') {
      filtered = filtered.filter(e => new Date(e.endDate) < now);
    }

    // Filter by type (online/in-person)
    if (this.typeFilter === 'online') {
      filtered = filtered.filter(e => e.isOnline);
    } else if (this.typeFilter === 'in-person') {
      filtered = filtered.filter(e => !e.isOnline);
    }

    // Filter by search term
    if (this.searchTerm.trim()) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(e =>
        e.title.toLowerCase().includes(term) ||
        (e.description && e.description.toLowerCase().includes(term)) ||
        (e.location && e.location.toLowerCase().includes(term))
      );
    }

    // Sort by start date (upcoming first)
    filtered.sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime());

    this.filteredEvents = filtered;
  }

  loadGroups(): void {
    this.groupService.getAllGroups().subscribe({
      next: (groups) => {
        this.availableGroups = groups;
      },
      error: (err) => {
        console.error('Error loading groups:', err);
      }
    });
  }

  applyFilters(): void {
    const now = new Date();
    let filtered = this.events;

    // Filter by time
    if (this.selectedFilter === 'upcoming') {
      filtered = filtered.filter(e => new Date(e.startDate) >= now);
    } else if (this.selectedFilter === 'past') {
      filtered = filtered.filter(e => new Date(e.endDate) < now);
    }

    // Filter by search term
    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(e =>
        e.title.toLowerCase().includes(term) ||
        e.description.toLowerCase().includes(term) ||
        e.location.toLowerCase().includes(term)
      );
    }

    // Sort by start date
    filtered.sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime());

    this.filteredEvents = filtered;
  }

  onSearchChange(): void {
    this.filterEvents();
  }

  onFilterChange(filter: 'all' | 'upcoming' | 'past'): void {
    this.selectedFilter = filter;
    this.statusFilter = filter;
    this.filterEvents();
  }

  onStatusFilterChange(status: 'all' | 'upcoming' | 'past'): void {
    this.statusFilter = status;
    this.selectedFilter = status;
    this.filterEvents();
  }

  onTypeFilterChange(type: 'all' | 'online' | 'in-person'): void {
    this.typeFilter = type;
    this.filterEvents();
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      weekday: 'short', 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    });
  }

  formatTime(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  }

  getMonthDay(dateString: string): { day: string, month: string } {
    const date = new Date(dateString);
    return {
      day: date.getDate().toString(),
      month: date.toLocaleDateString('en-US', { month: 'short' }).toUpperCase()
    };
  }

  isUpcoming(event: any): boolean {
    return new Date(event.startDate) >= new Date();
  }

  getUpcomingCount(): number {
    return this.events.filter(e => this.isUpcoming(e)).length;
  }

  getPastCount(): number {
    return this.events.filter(e => !this.isUpcoming(e)).length;
  }

  navigateToGroups(): void {
    this.router.navigate(['/groups']);
  }

  navigateToClubDashboard(): void {
    this.router.navigate(['/ClubDashboard']);
  }

  openCreateEventModal(): void {
    this.newEventForm = {
      title: '',
      description: '',
      location: '',
      startDate: '',
      endDate: '',
      groupId: this.availableGroups.length > 0 ? this.availableGroups[0].id : 0,
      status: 'PENDING'
    };
    this.isCreateModalOpen = true;
    this.isCreateEventModalOpen = true;
  }

  closeCreateEventModal(): void {
    this.isCreateModalOpen = false;
    this.isCreateEventModalOpen = false;
  }

  createEvent(): void {
    this.submitEvent();
  }

  attendEvent(eventId: number): void {
    const event = this.events.find(e => e.id === eventId);
    if (event) {
      this.notificationService.addNotification({
        type: 'event',
        title: 'Joined Event!',
        message: `You have joined "${event.title}"`,
        importance: 'normal'
      });
      alert(`You have successfully joined "${event.title}"!`);
    }
  }

  viewEventDetails(eventId: number): void {
    // Navigate to event details page
    this.router.navigate(['/events', eventId]);
  }

  filterByCategory(category: any): void {
    this.searchTerm = category.name;
    this.filterEvents();
  }

  getStatusClass(status: string): string {
    switch (status) {
      case 'APPROVED': return 'status-approved';
      case 'PENDING': return 'status-pending';
      case 'REJECTED': return 'status-rejected';
      default: return '';
    }
  }

  submitEvent(): void {
    if (!this.newEventForm.title || !this.newEventForm.description || 
        !this.newEventForm.location || !this.newEventForm.startDate || 
        !this.newEventForm.endDate || !this.newEventForm.groupId) {
      alert('Please fill in all required fields');
      return;
    }

    const eventData = {
      title: this.newEventForm.title.trim(),
      description: this.newEventForm.description.trim(),
      location: this.newEventForm.location.trim(),
      startDate: this.newEventForm.startDate,
      endDate: this.newEventForm.endDate,
      group: { id: this.newEventForm.groupId },
      status: 'PENDING'
    };

    this.eventService.createEvent(eventData).subscribe({
      next: (created) => {
        // Send notification about new event
        this.notificationService.addNotification({
          type: 'event',
          title: 'Event Submitted',
          message: `"${created.title}" has been submitted and is pending approval`,
          importance: 'normal',
          relatedRoute: `/events`
        });
        
        alert('Event submitted successfully! It will be visible after admin approval.');
        this.closeCreateEventModal();
        // Don't reload events since pending events won't show
      },
      error: (err) => {
        console.error('Error creating event:', err);
        alert('Error submitting event. Please try again.');
      }
    });
  }
}
