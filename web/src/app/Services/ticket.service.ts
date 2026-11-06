import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, Subject } from 'rxjs';
import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

export interface Ticket {
  id?: number;
  userId: number;
  userEmail?: string;
  userName?: string;
  title: string;
  description: string;
  enhancedDescription?: string;
  aiSummary?: string;
  status?: string;
  priority?: string;
  category?: string;
  department?: string;
  assignedToId?: number;
  assignedToName?: string;
  escalated?: boolean;
  slaBreached?: boolean;
  createdAtStr?: string;
  updatedAtStr?: string;
  resolvedAtStr?: string;
  slaDeadlineStr?: string;
}

export interface TicketResponse {
  id?: number;
  responderId: number;
  responderName: string;
  isStaff: boolean;
  message: string;
  createdAtStr?: string;
}

export interface PagedTickets {
  tickets: Ticket[];
  totalItems: number;
  totalPages: number;
  currentPage: number;
  pageSize: number;
}

export interface TicketStats {
  total: number;
  open: number;
  inProgress: number;
  resolved: number;
  closed: number;
  escalated: number;
  slaBreached: number;
  critical: number;
  high: number;
  todayNew: number;
  weekNew: number;
}

@Injectable({ providedIn: 'root' })
export class TicketService {
  private apiUrl = 'http://localhost:8085/api/tickets';
  private stompClient: Client | null = null;

  public notificationSubject = new Subject<any>();

  constructor(private http: HttpClient) {}

  // ── CRUD ──────────────────────────────────────────────────────────────────
  createTicket(ticket: any): Observable<Ticket> {
    return this.http.post<Ticket>(`${this.apiUrl}/create`, ticket);
  }

  // Paginated - used by admin
  getPagedTickets(page = 0, size = 10, status?: string, priority?: string, category?: string, sortBy = 'id', sortDir = 'desc'): Observable<PagedTickets> {
    let params = new HttpParams()
      .set('page', page)
      .set('size', size)
      .set('sortBy', sortBy)
      .set('sortDir', sortDir);
    if (status)   params = params.set('status', status);
    if (priority) params = params.set('priority', priority);
    if (category) params = params.set('category', category);
    return this.http.get<PagedTickets>(this.apiUrl, { params });
  }

  // Non-paginated - used by dashboard widget
  getAllTickets(): Observable<Ticket[]> {
    return this.http.get<Ticket[]>(`${this.apiUrl}/all`);
  }

  getTicketById(id: number): Observable<Ticket> {
    return this.http.get<Ticket>(`${this.apiUrl}/${id}`);
  }

  getMyTickets(userId: number): Observable<Ticket[]> {
    return this.http.get<Ticket[]>(`${this.apiUrl}/user/${userId}`);
  }

  updateTicket(id: number, updates: any): Observable<Ticket> {
    return this.http.put<Ticket>(`${this.apiUrl}/update/${id}`, updates);
  }

  deleteTicket(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  escalateTicket(id: number): Observable<Ticket> {
    return this.http.post<Ticket>(`${this.apiUrl}/escalate/${id}`, {});
  }

  // ── RESPONSES ─────────────────────────────────────────────────────────────
  addResponse(ticketId: number, response: Partial<TicketResponse>): Observable<TicketResponse> {
    return this.http.post<TicketResponse>(`${this.apiUrl}/${ticketId}/responses`, response);
  }

  getResponses(ticketId: number): Observable<TicketResponse[]> {
    return this.http.get<TicketResponse[]>(`${this.apiUrl}/${ticketId}/responses`);
  }

  // ── STATISTICS ────────────────────────────────────────────────────────────
  getStatistics(): Observable<TicketStats> {
    return this.http.get<TicketStats>(`${this.apiUrl}/statistics`);
  }

  // ── AI ────────────────────────────────────────────────────────────────────
  regenerateSummary(ticketId: number): Observable<{ aiSummary: string }> {
    return this.http.post<{ aiSummary: string }>(`${this.apiUrl}/${ticketId}/summarize`, {});
  }

  regenerateEnhancement(ticketId: number): Observable<{ enhancedDescription: string }> {
    return this.http.post<{ enhancedDescription: string }>(`${this.apiUrl}/${ticketId}/enhance`, {});
  }

  enhanceText(title: string, description: string): Observable<{ enhanced: string }> {
    return this.http.post<{ enhanced: string }>(`${this.apiUrl}/enhance-text`, { title, description });
  }

  // ── WEBSOCKET ─────────────────────────────────────────────────────────────
  connectWebSocket(userId: string) {
    if (this.stompClient?.active) return;
    this.stompClient = new Client({
      webSocketFactory: () => new SockJS('http://localhost:8085/ws-support'),
      reconnectDelay: 5000,
    });
    this.stompClient.onConnect = () => {
      this.stompClient?.subscribe(`/user/${userId}/queue/support`, (msg) => {
        this.notificationSubject.next(JSON.parse(msg.body));
      });
      this.stompClient?.subscribe('/topic/support/admin', (msg) => {
        this.notificationSubject.next(JSON.parse(msg.body));
      });
    };
    this.stompClient.activate();
  }

  disconnectWebSocket() { this.stompClient?.deactivate(); }
}

