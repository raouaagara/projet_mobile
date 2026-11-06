import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { NotificationService, NotificationItem } from '../notification.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-notification-bell',
  templateUrl: './notification-bell.component.html',
  styleUrls: ['./notification-bell.component.css']
})
export class NotificationBellComponent implements OnInit, OnDestroy {
  notifications: NotificationItem[] = [];
  unreadCount = 0;
  showDropdown = false;
  activeTab: 'all' | 'upcoming' | 'past' = 'all';
  private subscription?: Subscription;

  constructor(
    private notificationService: NotificationService,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Subscribe to notifications
    this.subscription = this.notificationService.items$.subscribe(items => {
      this.notifications = items;
      this.unreadCount = this.notificationService.unreadCount;
    });

    // Initial load
    this.notifications = this.notificationService.all;
    this.unreadCount = this.notificationService.unreadCount;
  }

  ngOnDestroy(): void {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  toggleDropdown(): void {
    this.showDropdown = !this.showDropdown;
  }

  closeDropdown(): void {
    this.showDropdown = false;
  }

  setTab(tab: 'all' | 'upcoming' | 'past'): void {
    this.activeTab = tab;
  }

  getFilteredNotifications(): NotificationItem[] {
    if (this.activeTab === 'all') {
      return this.notifications.slice(0, 10);
    }

    const now = new Date();
    
    if (this.activeTab === 'upcoming') {
      return this.notifications.filter(n => {
        if (n.type !== 'event') return false;
        // Check if it's an upcoming event notification
        return n.message.includes('starts in') || n.message.includes('scheduled') || n.message.includes('upcoming');
      }).slice(0, 10);
    }

    if (this.activeTab === 'past') {
      return this.notifications.filter(n => {
        if (n.type !== 'event') return false;
        // Check if it's a past event notification
        const createdDate = new Date(n.createdAt);
        const daysDiff = Math.floor((now.getTime() - createdDate.getTime()) / (1000 * 60 * 60 * 24));
        return daysDiff > 0 && !n.message.includes('starts in');
      }).slice(0, 10);
    }

    return [];
  }

  getUpcomingCount(): number {
    return this.notifications.filter(n => 
      n.type === 'event' && (n.message.includes('starts in') || n.message.includes('scheduled'))
    ).length;
  }

  getPastCount(): number {
    const now = new Date();
    return this.notifications.filter(n => {
      if (n.type !== 'event') return false;
      const createdDate = new Date(n.createdAt);
      const daysDiff = Math.floor((now.getTime() - createdDate.getTime()) / (1000 * 60 * 60 * 24));
      return daysDiff > 0 && !n.message.includes('starts in');
    }).length;
  }

  markAsRead(notification: NotificationItem, event: Event): void {
    event.stopPropagation();
    this.notificationService.markAsRead(notification.id);
  }

  markAllAsRead(): void {
    this.notificationService.markAllAsRead();
  }

  clearAll(): void {
    if (confirm('Are you sure you want to clear all notifications? This cannot be undone.')) {
      this.notificationService.clearAllNotifications();
      this.closeDropdown();
    }
  }

  navigateToNotification(notification: NotificationItem): void {
    this.notificationService.markAsRead(notification.id);
    if (notification.relatedRoute) {
      this.router.navigate([notification.relatedRoute]);
    }
    this.closeDropdown();
  }

  getNotificationIcon(type: string): string {
    const icons: any = {
      'event': '📅',
      'club': '🎯',
      'group': '👥',
      'system': '🔔'
    };
    return icons[type] || '🔔';
  }

  getNotificationClass(importance: string): string {
    const classes: any = {
      'high': 'notification-high',
      'normal': 'notification-normal',
      'low': 'notification-low'
    };
    return classes[importance] || 'notification-normal';
  }

  getTimeAgo(date: Date): string {
    const now = new Date();
    const diff = now.getTime() - new Date(date).getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    return `${days}d ago`;
  }
}
