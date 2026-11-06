import { Component } from '@angular/core';
import { NotificationService, Notification } from '../../services-ayoub/notification.service';

@Component({
  selector: 'app-notification-center',
  templateUrl: './notification-center.component.html',
  styleUrl: './notification-center.component.css'
})
export class NotificationCenterComponent {
  open = false;

  constructor(public notif: NotificationService) {}

  toggle(): void {
    this.open = !this.open;
  }

  markRead(n: Notification): void {
    this.notif.markAsRead(n.id);
  }

  markAllRead(): void {
    this.notif.markAllAsRead();
  }
}
