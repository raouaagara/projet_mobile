import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { EventService } from '../event.service';
import { NotificationService } from '../notification.service';

@Component({
  selector: 'app-event-details',
  templateUrl: './event-details.component.html',
  styleUrls: ['./event-details.component.css']
})
export class EventDetailsComponent implements OnInit {
  eventId!: number;
  event: any = null;
  loading = true;
  hasJoined = false;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private eventService: EventService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.eventId = Number(this.route.snapshot.paramMap.get('id'));
    this.loadEvent();
  }

  loadEvent(): void {
    this.loading = true;
    this.eventService.getEventById(this.eventId).subscribe({
      next: (data) => {
        this.event = data;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading event:', err);
        this.loading = false;
        this.router.navigate(['/events']);
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/events']);
  }

  joinEvent(): void {
    if (this.hasJoined) {
      this.notificationService.addNotification({
        type: 'event',
        title: 'Already Joined',
        message: `You have already joined "${this.event.title}"`,
        importance: 'normal'
      });
      return;
    }

    this.hasJoined = true;
    this.notificationService.addNotification({
      type: 'event',
      title: 'Joined Event!',
      message: `You have successfully joined "${this.event.title}"`,
      importance: 'high'
    });
  }

  shareEvent(): void {
    const eventUrl = `${window.location.origin}/events/${this.eventId}`;
    
    if (navigator.share) {
      navigator.share({
        title: this.event.title,
        text: `Check out this event: ${this.event.title}`,
        url: eventUrl
      }).then(() => {
        this.notificationService.addNotification({
          type: 'event',
          title: 'Event Shared!',
          message: `You shared "${this.event.title}"`,
          importance: 'normal'
        });
      }).catch((error) => {
        console.log('Error sharing:', error);
        this.copyToClipboard(eventUrl);
      });
    } else {
      this.copyToClipboard(eventUrl);
    }
  }

  private copyToClipboard(text: string): void {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(() => {
        this.notificationService.addNotification({
          type: 'event',
          title: 'Link Copied!',
          message: 'Event link copied to clipboard',
          importance: 'normal'
        });
      });
    }
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      weekday: 'long',
      year: 'numeric', 
      month: 'long', 
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

  isUpcoming(): boolean {
    return new Date(this.event.startDate) >= new Date();
  }

  getStatusClass(): string {
    switch (this.event.status) {
      case 'APPROVED': return 'status-approved';
      case 'PENDING': return 'status-pending';
      case 'REJECTED': return 'status-rejected';
      default: return '';
    }
  }
}
