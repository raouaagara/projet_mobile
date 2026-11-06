import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, interval } from 'rxjs';
import { EventService } from './event.service';
import { ClubService } from './club.service';
import { GroupService } from './group.service';

export type NotificationType = 'event' | 'club' | 'group' | 'system';

export type NotificationImportance = 'low' | 'normal' | 'high';

export interface NotificationItem {
  id: number;
  type: NotificationType;
  title: string;
  message: string;
  createdAt: Date;
  read: boolean;
  importance: NotificationImportance;
  relatedRoute?: string;
}

export interface NotificationGroup {
  type: NotificationType;
  label: string;
  items: NotificationItem[];
}

@Injectable({
  providedIn: 'root'
})
export class NotificationService {
  private items: NotificationItem[] = [];
  private itemsSubject = new BehaviorSubject<NotificationItem[]>([]);
  public items$ = this.itemsSubject.asObservable();
  
  private lastEventCheck: Date = new Date();
  private lastClubCheck: Date = new Date();
  private lastGroupCheck: Date = new Date();
  
  private readonly STORAGE_KEY = 'catchopp_notifications';
  private readonly MAX_NOTIFICATIONS = 100; // Keep last 100 notifications

  constructor(
    private eventService: EventService,
    private clubService: ClubService,
    private groupService: GroupService
  ) {
    // Load notifications from localStorage
    this.loadFromStorage();
    
    // Initialize with welcome notification if no notifications exist
    if (this.items.length === 0) {
      this.addNotification({
        type: 'system',
        title: 'Welcome to Communities',
        message: 'Join groups, clubs, and events to grow your network.',
        importance: 'low'
      });
    }

    // Check for new content every 30 seconds
    interval(30000).subscribe(() => {
      this.checkForNewContent();
    });

    // Initial check
    this.checkForNewContent();
  }

  private loadFromStorage(): void {
    try {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        // Convert date strings back to Date objects
        this.items = parsed.map((item: any) => ({
          ...item,
          createdAt: new Date(item.createdAt)
        }));
        this.itemsSubject.next(this.items);
      }
    } catch (error) {
      console.error('Error loading notifications from storage:', error);
      this.items = [];
    }
  }

  private saveToStorage(): void {
    try {
      // Keep only the last MAX_NOTIFICATIONS
      const toSave = this.items.slice(0, this.MAX_NOTIFICATIONS);
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(toSave));
    } catch (error) {
      console.error('Error saving notifications to storage:', error);
    }
  }

  get all(): NotificationItem[] {
    return this.items;
  }

  get unreadCount(): number {
    return this.items.filter(i => !i.read).length;
  }

  getGroups(): NotificationGroup[] {
    const map: { [k in NotificationType]: NotificationGroup } = {
      event: { type: 'event', label: 'Events', items: [] },
      club: { type: 'club', label: 'Clubs', items: [] },
      group: { type: 'group', label: 'Groups', items: [] },
      system: { type: 'system', label: 'System', items: [] }
    };

    for (const item of this.items) {
      map[item.type].items.push(item);
    }

    return Object.values(map).filter(g => g.items.length > 0);
  }

  addNotification(partial: {
    type: NotificationType;
    title: string;
    message: string;
    importance?: NotificationImportance;
    relatedRoute?: string;
  }): void {
    const notification: NotificationItem = {
      id: Date.now() + Math.random(), // Ensure unique ID
      type: partial.type,
      title: partial.title,
      message: partial.message,
      createdAt: new Date(),
      read: false,
      importance: partial.importance ?? 'normal',
      relatedRoute: partial.relatedRoute
    };
    this.items = [notification, ...this.items];
    this.itemsSubject.next(this.items);
    this.saveToStorage(); // Save to localStorage
  }

  markAsRead(id: number): void {
    this.items = this.items.map(i =>
      i.id === id ? { ...i, read: true } : i
    );
    this.itemsSubject.next(this.items);
    this.saveToStorage(); // Save to localStorage
  }

  markAllAsRead(): void {
    this.items = this.items.map(i => ({ ...i, read: true }));
    this.itemsSubject.next(this.items);
    this.saveToStorage(); // Save to localStorage
  }

  clearAllNotifications(): void {
    this.items = [];
    this.itemsSubject.next(this.items);
    this.saveToStorage(); // Save to localStorage
  }

  private checkForNewContent(): void {
    this.checkForNewEvents();
    this.checkForNewClubs();
    this.checkForNewGroups();
    this.checkForUpcomingEvents();
  }

  private checkForNewEvents(): void {
    this.eventService.getAllEvents().subscribe({
      next: (events) => {
        const newEvents = events.filter(e => {
          const createdAt = new Date(e.createdAt || '');
          return createdAt > this.lastEventCheck;
        });

        newEvents.forEach(event => {
          this.addNotification({
            type: 'event',
            title: 'New Event Created',
            message: `"${event.title}" has been scheduled at ${event.location}`,
            importance: 'high',
            relatedRoute: `/events`
          });
        });

        if (newEvents.length > 0) {
          this.lastEventCheck = new Date();
        }
      },
      error: (err) => console.error('Error checking events:', err)
    });
  }

  private checkForNewClubs(): void {
    this.clubService.getAllClubs().subscribe({
      next: (clubs) => {
        const newClubs = clubs.filter(c => {
          const createdAt = new Date(c.createdAt || '');
          return createdAt > this.lastClubCheck;
        });

        newClubs.forEach(club => {
          this.addNotification({
            type: 'club',
            title: 'New Club Available',
            message: `"${club.name}" club has been created. Join now!`,
            importance: 'normal',
            relatedRoute: `/clubs/${club.id}`
          });
        });

        if (newClubs.length > 0) {
          this.lastClubCheck = new Date();
        }
      },
      error: (err) => console.error('Error checking clubs:', err)
    });
  }

  private checkForNewGroups(): void {
    this.groupService.getAllGroups().subscribe({
      next: (groups) => {
        const newGroups = groups.filter(g => {
          const createdAt = new Date(g.createdAt || '');
          return createdAt > this.lastGroupCheck;
        });

        newGroups.forEach(group => {
          this.addNotification({
            type: 'group',
            title: 'New Group Created',
            message: `"${group.name}" group is now available to join`,
            importance: 'normal',
            relatedRoute: `/groups/${group.id}`
          });
        });

        if (newGroups.length > 0) {
          this.lastGroupCheck = new Date();
        }
      },
      error: (err) => console.error('Error checking groups:', err)
    });
  }

  private checkForUpcomingEvents(): void {
    this.eventService.getAllEvents().subscribe({
      next: (events) => {
        const now = new Date();
        const twoHoursFromNow = new Date(now.getTime() + 2 * 60 * 60 * 1000);

        events.forEach(event => {
          const startDate = new Date(event.startDate);
          
          // Check if event starts within 2 hours
          if (startDate > now && startDate <= twoHoursFromNow) {
            // Check if we haven't already notified about this event
            const alreadyNotified = this.items.some(n => 
              n.type === 'event' && 
              n.title.includes(event.title) && 
              n.message.includes('starts soon')
            );

            if (!alreadyNotified) {
              const minutesUntil = Math.floor((startDate.getTime() - now.getTime()) / (1000 * 60));
              this.addNotification({
                type: 'event',
                title: `${event.title} starts soon!`,
                message: `Event starts in ${minutesUntil} minutes at ${event.location}`,
                importance: 'high',
                relatedRoute: `/events`
              });
            }
          }
        });
      },
      error: (err) => console.error('Error checking upcoming events:', err)
    });
  }

  // Method to notify when a new post is created in a group
  notifyNewPost(groupId: number, groupName: string, postContent: string): void {
    this.addNotification({
      type: 'group',
      title: `New post in ${groupName}`,
      message: postContent.substring(0, 50) + (postContent.length > 50 ? '...' : ''),
      importance: 'normal',
      relatedRoute: `/groups/${groupId}`
    });
  }

  // Method to notify when a new post is created in a club
  notifyNewClubPost(clubId: number, clubName: string, postContent: string): void {
    this.addNotification({
      type: 'club',
      title: `New post in ${clubName}`,
      message: postContent.substring(0, 50) + (postContent.length > 50 ? '...' : ''),
      importance: 'normal',
      relatedRoute: `/clubs/${clubId}`
    });
  }
}

