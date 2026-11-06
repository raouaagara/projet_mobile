import { Injectable } from '@angular/core';

export interface Notification {
  id: number;
  type: 'subscription' | 'payment' | 'reminder' | 'info';
  title: string;
  message: string;
  date: string;
  read: boolean;
}

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private notifications: Notification[] = [
    { id: 1, type: 'reminder', title: 'Subscription expires soon', message: 'Your Premium plan expires in 5 days.', date: '2025-02-09', read: false },
    { id: 2, type: 'payment', title: 'Payment received', message: 'Your payment of $24.99 was processed.', date: '2025-02-09', read: true },
    { id: 3, type: 'info', title: 'AI CV ready', message: 'Your AI-generated CV is available.', date: '2025-02-08', read: false }
  ];

  getAll(): Notification[] {
    return [...this.notifications];
  }

  getUnreadCount(): number {
    return this.notifications.filter(n => !n.read).length;
  }

  markAsRead(id: number): void {
    const n = this.notifications.find(x => x.id === id);
    if (n) n.read = true;
  }

  markAllAsRead(): void {
    this.notifications.forEach(n => n.read = true);
  }
}
