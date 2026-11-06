import { Component, OnInit, OnDestroy } from '@angular/core';
import { trigger, state, style, transition, animate } from '@angular/animations';
import { NotificationService, NotificationItem } from '../notification.service';
import { Subscription } from 'rxjs';

interface ToastNotification extends NotificationItem {
  show: boolean;
  countdown?: number;
}

@Component({
  selector: 'app-notification-toast',
  templateUrl: './notification-toast.component.html',
  styleUrls: ['./notification-toast.component.css'],
  animations: [
    trigger('slideIn', [
      state('void', style({
        transform: 'translateX(400px)',
        opacity: 0
      })),
      state('*', style({
        transform: 'translateX(0)',
        opacity: 1
      })),
      transition('void => *', animate('300ms ease-out')),
      transition('* => void', animate('300ms ease-in'))
    ])
  ]
})
export class NotificationToastComponent implements OnInit, OnDestroy {
  toasts: ToastNotification[] = [];
  private subscription?: Subscription;
  private countdownIntervals: Map<number, any> = new Map();

  constructor(private notificationService: NotificationService) {}

  ngOnInit(): void {
    // Subscribe to new notifications
    this.subscription = this.notificationService.items$.subscribe(items => {
      // Get the latest unread notification
      const latestUnread = items.find(item => !item.read && !this.toasts.find(t => t.id === item.id));
      
      if (latestUnread) {
        this.showToast(latestUnread);
      }
    });
  }

  ngOnDestroy(): void {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
    // Clear all countdown intervals
    this.countdownIntervals.forEach(interval => clearInterval(interval));
  }

  showToast(notification: NotificationItem): void {
    const toast: ToastNotification = {
      ...notification,
      show: true
    };

    // Add countdown for event reminders
    if (notification.type === 'event' && notification.message.includes('starts in')) {
      const minutesMatch = notification.message.match(/(\d+) minutes/);
      if (minutesMatch) {
        toast.countdown = parseInt(minutesMatch[1]);
        this.startCountdown(toast);
      }
    }

    this.toasts.push(toast);

    // Auto-remove after 5 seconds
    setTimeout(() => {
      this.removeToast(toast.id);
    }, 5000);
  }

  startCountdown(toast: ToastNotification): void {
    const interval = setInterval(() => {
      if (toast.countdown && toast.countdown > 0) {
        toast.countdown--;
      } else {
        clearInterval(interval);
        this.countdownIntervals.delete(toast.id);
      }
    }, 60000); // Update every minute

    this.countdownIntervals.set(toast.id, interval);
  }

  removeToast(id: number): void {
    const index = this.toasts.findIndex(t => t.id === id);
    if (index !== -1) {
      this.toasts.splice(index, 1);
      
      // Clear countdown interval if exists
      const interval = this.countdownIntervals.get(id);
      if (interval) {
        clearInterval(interval);
        this.countdownIntervals.delete(id);
      }
    }
  }

  closeToast(toast: ToastNotification): void {
    this.removeToast(toast.id);
  }

  getToastIcon(type: string): string {
    const icons: any = {
      'event': '📅',
      'club': '🎯',
      'group': '👥',
      'system': '🔔'
    };
    return icons[type] || '🔔';
  }

  getToastClass(importance: string): string {
    const classes: any = {
      'high': 'toast-high',
      'normal': 'toast-normal',
      'low': 'toast-low'
    };
    return classes[importance] || 'toast-normal';
  }

  getTimeAgo(date: Date): string {
    const now = new Date();
    const diff = now.getTime() - new Date(date).getTime();
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (seconds < 60) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    return `${days}d ago`;
  }
}
