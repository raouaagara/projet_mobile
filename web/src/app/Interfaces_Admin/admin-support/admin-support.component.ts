import { Component, OnInit, OnDestroy } from '@angular/core';
import { TicketService, Ticket, TicketStats, TicketResponse } from '../../Services/ticket.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-admin-support',
  templateUrl: './admin-support.component.html',
  styleUrls: ['./admin-support.component.css']
})
export class AdminSupportComponent implements OnInit, OnDestroy {
  stats: TicketStats | null = null;
  tickets: Ticket[] = [];
  
  selectedTicket: Ticket | null = null;
  ticketResponses: TicketResponse[] = [];
  
  currentPage = 0;
  totalPages = 0;
  totalItems = 0;
  pageSize = 10;
  
  statusFilter = '';
  priorityFilter = '';
  
  isLoading = true;
  isActionLoading = false;
  
  replyMessage = '';

  private notificationSub!: Subscription;

  constructor(private ticketService: TicketService) {}

  ngOnInit(): void {
    this.loadStats();
    this.loadTickets();
    
    // Connect to WebSocket for real-time updates
    this.ticketService.connectWebSocket('admin');
    this.notificationSub = this.ticketService.notificationSubject.subscribe(notification => {
      this.loadStats();
      this.loadTickets(this.currentPage);
      if (this.selectedTicket && notification.data?.ticketId === this.selectedTicket.id) {
          this.loadResponses(this.selectedTicket.id!);
      }
    });
  }

  ngOnDestroy(): void {
    if (this.notificationSub) this.notificationSub.unsubscribe();
    this.ticketService.disconnectWebSocket();
  }

  loadStats() {
    this.ticketService.getStatistics().subscribe({
      next: (data) => this.stats = data,
      error: (err) => console.error('Error fetching stats', err)
    });
  }

  loadTickets(page = 0) {
    this.isLoading = true;
    this.ticketService.getPagedTickets(page, this.pageSize, this.statusFilter || undefined, this.priorityFilter || undefined).subscribe({
      next: (data) => {
        this.tickets = data.tickets;
        this.currentPage = data.currentPage;
        this.totalPages = data.totalPages;
        this.totalItems = data.totalItems;
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching tickets', err);
        this.isLoading = false;
      }
    });
  }

  onFilterChange() {
    this.loadTickets(0);
  }
  
  nextPage() {
    if (this.currentPage < this.totalPages - 1) {
      this.loadTickets(this.currentPage + 1);
    }
  }

  prevPage() {
    if (this.currentPage > 0) {
      this.loadTickets(this.currentPage - 1);
    }
  }

  viewTicket(ticket: Ticket) {
    this.selectedTicket = ticket;
    this.loadResponses(ticket.id!);
  }

  closeTicketView() {
    this.selectedTicket = null;
    this.ticketResponses = [];
  }

  loadResponses(ticketId: number) {
      this.ticketService.getResponses(ticketId).subscribe(data => {
          this.ticketResponses = data;
      });
  }

  updateTicketStatus(ticket: Ticket, newStatus: string) {
    this.isActionLoading = true;
    this.ticketService.updateTicket(ticket.id!, { status: newStatus }).subscribe({
      next: (updated) => {
        ticket.status = updated.status;
        this.isActionLoading = false;
        this.loadStats();
      },
      error: (err) => {
        console.error('Error updating status', err);
        this.isActionLoading = false;
      }
    });
  }

  sendReply() {
    if (!this.selectedTicket || !this.replyMessage.trim()) return;
    
    this.isActionLoading = true;
    this.ticketService.addResponse(this.selectedTicket.id!, {
      responderId: 1, // System/Admin ID
      responderName: 'Support Team',
      isStaff: true,
      message: this.replyMessage
    }).subscribe({
      next: (res) => {
        this.ticketResponses.push(res);
        this.replyMessage = '';
        this.isActionLoading = false;
        if (this.selectedTicket!.status === 'OPEN') {
           this.updateTicketStatus(this.selectedTicket!, 'IN_PROGRESS'); 
        }
      },
      error: (err) => {
        console.error('Error sending reply', err);
        this.isActionLoading = false;
      }
    });
  }

  getStatusClass(status: string | undefined): string {
    if (!status) return 'badge-default';
    switch (status) {
      case 'OPEN': return 'badge-danger';
      case 'IN_PROGRESS': return 'badge-warning';
      case 'RESOLVED': return 'badge-success';
      case 'CLOSED': return 'badge-default';
      case 'ESCALATED': return 'badge-critical';
      default: return 'badge-default';
    }
  }

  getPriorityClass(priority: string | undefined): string {
    if (!priority) return 'priority-low';
    switch (priority) {
      case 'CRITICAL': return 'priority-critical';
      case 'HIGH': return 'priority-high';
      case 'MEDIUM': return 'priority-medium';
      case 'LOW': return 'priority-low';
      default: return 'priority-low';
    }
  }
}
