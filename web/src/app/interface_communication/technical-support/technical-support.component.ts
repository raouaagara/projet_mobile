import { Component, OnInit, OnDestroy, forwardRef, Inject } from '@angular/core';
import { TicketService, Ticket, TicketResponse } from '../../Services/ticket.service';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-technical-support',
  templateUrl: './technical-support.component.html',
  styleUrls: ['./technical-support.component.css']
})
export class TechnicalSupportComponent implements OnInit, OnDestroy {

  // ── State ──────────────────────────────────────────────────────────────────
  view: 'list' | 'create' | 'detail' = 'list';
  tickets: Ticket[] = [];
  filteredTickets: Ticket[] = [];
  selectedTicket: Ticket | null = null;
  responses: TicketResponse[] = [];
  loading = false;
  submitting = false;
  enhancing = false;
  enhanced = false;
  successMsg = '';
  errorMsg = '';
  newReply = '';
  notifications: any[] = [];
  private sub?: Subscription;

  // ── Current user ───────────────────────────────────────────────────────────
  currentUserId = 0;
  currentUserName = '';

  // ── Filters ────────────────────────────────────────────────────────────────
  filterStatus = '';
  filterPriority = '';
  filterCategory = '';
  searchQuery = '';

  // ── New ticket form ────────────────────────────────────────────────────────
  newTicket: Partial<Ticket> = {
    title: '', description: '', priority: 'MEDIUM', category: ''
  };

  readonly statuses   = ['OPEN','IN_PROGRESS','PENDING_USER','RESOLVED','CLOSED','ESCALATED'];
  readonly priorities = ['LOW','MEDIUM','HIGH','CRITICAL'];
  readonly categories = ['TECHNICAL_ISSUE','PAYMENT_ISSUE','ACCOUNT_ISSUE','CONTRACT_DISPUTE','FRAUD_REPORT','BUG_REPORT','FEATURE_REQUEST','OTHER'];

 constructor(
    @Inject(forwardRef(() => TicketService)) private ticketService: TicketService
  ) {}

  ngOnInit() {
    this.loadUser();
    this.loadTickets();
    this.ticketService.connectWebSocket(String(this.currentUserId));
    this.sub = this.ticketService.notificationSubject.subscribe(n => {
      this.notifications.unshift({ ...n, time: new Date().toLocaleTimeString() });
      this.loadTickets(); // refresh list on any update
    });
  }

  ngOnDestroy() {
    this.sub?.unsubscribe();
    this.ticketService.disconnectWebSocket();
  }

  loadUser() {
    const stored = localStorage.getItem('currentUser');
    if (stored) {
      try {
        const token = stored.includes('token') ? JSON.parse(stored).token : stored;
        const payload = JSON.parse(atob(token.split('.')[1]));
        this.currentUserId = Number(payload.id);
        this.currentUserName = `${payload.firstName || ''} ${payload.lastName || ''}`.trim() || payload.email;
      } catch { this.currentUserId = 0; }
    }
  }

  loadTickets() {
    this.loading = true;
    this.ticketService.getMyTickets(this.currentUserId).subscribe({
      next: (data) => { this.tickets = data; this.applyFilters(); this.loading = false; },
      error: () => { this.loading = false; }
    });
  }

  applyFilters() {
    let result = [...this.tickets];
    if (this.filterStatus)   result = result.filter(t => t.status === this.filterStatus);
    if (this.filterPriority) result = result.filter(t => t.priority === this.filterPriority);
    if (this.filterCategory) result = result.filter(t => t.category === this.filterCategory);
    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase();
      result = result.filter(t => t.title.toLowerCase().includes(q) || t.description.toLowerCase().includes(q));
    }
    this.filteredTickets = result;
  }

  openCreate() {
    this.view = 'create';
    this.newTicket = { title: '', description: '', priority: 'MEDIUM', category: '' };
    this.enhanced = false;
  }

  enhanceDescription() {
    if (!this.newTicket.description?.trim()) return;
    this.enhancing = true;
    this.errorMsg = '';
    // Call backend enhance endpoint with a temporary ticket ID of 0 won't work,
    // so we use a direct POST to the enhance-text endpoint
    this.ticketService.enhanceText(this.newTicket.title || '', this.newTicket.description).subscribe({
      next: (res) => {
        this.newTicket.description = res.enhanced;
        this.enhanced = true;
        this.enhancing = false;
      },
      error: () => {
        this.enhancing = false;
        this.errorMsg = 'Enhancement failed. Make sure the backend is running.';
      }
    });
  }

  submitTicket() {
    if (!this.newTicket.title?.trim() || !this.newTicket.description?.trim()) {
      this.errorMsg = 'Title and description are required.'; return;
    }
    this.errorMsg = '';
    this.submitting = true;

    // Build clean payload - remove empty category so backend auto-detects
    const payload: any = {
      userId: this.currentUserId,
      userName: this.currentUserName,
      title: this.newTicket.title,
      description: this.newTicket.description,
      priority: this.newTicket.priority || 'MEDIUM'
    };
    if (this.newTicket.category && this.newTicket.category !== '') {
      payload.category = this.newTicket.category;
    }

    this.ticketService.createTicket(payload).subscribe({
      next: () => {
        this.submitting = false;
        this.successMsg = 'Ticket submitted successfully!';
        setTimeout(() => { this.successMsg = ''; this.view = 'list'; this.loadTickets(); }, 1500);
      },
      error: (err) => {
        this.submitting = false;
        console.error('Ticket submission error:', err);
        this.errorMsg = `Failed to submit ticket. ${err?.error?.message || err?.message || ''}`;
      }
    });
  }

  openDetail(ticket: Ticket) {
    this.selectedTicket = ticket;
    this.view = 'detail';
    this.ticketService.getResponses(ticket.id!).subscribe(r => this.responses = r);
  }

  sendReply() {
    if (!this.newReply.trim() || !this.selectedTicket) return;
    const response: Partial<TicketResponse> = {
      responderId: this.currentUserId,
      responderName: this.currentUserName,
      isStaff: false,
      message: this.newReply
    };
    this.ticketService.addResponse(this.selectedTicket.id!, response).subscribe({
      next: (r) => { this.responses.push(r); this.newReply = ''; }
    });
  }

  goBack() { this.view = 'list'; this.selectedTicket = null; this.responses = []; }

  getStatusClass(status?: string): string {
    const map: any = { OPEN: 'badge-open', IN_PROGRESS: 'badge-progress', PENDING_USER: 'badge-pending',
      RESOLVED: 'badge-resolved', CLOSED: 'badge-closed', ESCALATED: 'badge-escalated' };
    return map[status || ''] || '';
  }

  getPriorityClass(priority?: string): string {
    const map: any = { LOW: 'priority-low', MEDIUM: 'priority-medium', HIGH: 'priority-high', CRITICAL: 'priority-critical' };
    return map[priority || ''] || '';
  }

  formatLabel(val?: string): string {
    return (val || '').replace(/_/g, ' ');
  }

  dismissNotification(i: number) { this.notifications.splice(i, 1); }
}
