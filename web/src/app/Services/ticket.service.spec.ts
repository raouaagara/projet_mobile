import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TicketService, Ticket, PagedTickets, TicketStats } from './ticket.service';

describe('TicketService', () => {
  let service: TicketService;
  let httpMock: HttpTestingController;
  const API = 'http://localhost:8085/api/tickets';

  const mockTicket: Ticket = {
    id: 1, userId: 10, title: 'Test', description: 'Desc',
    status: 'OPEN', priority: 'MEDIUM', category: 'TECHNICAL_ISSUE'
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [TicketService]
    });
    service = TestBed.inject(TicketService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify());

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('createTicket() should POST to /create', () => {
    service.createTicket({ userId: 10, title: 'Test', description: 'Desc' }).subscribe(t => {
      expect(t.id).toBe(1);
      expect(t.status).toBe('OPEN');
    });
    const req = httpMock.expectOne(`${API}/create`);
    expect(req.request.method).toBe('POST');
    req.flush(mockTicket);
  });

  it('getMyTickets() should GET /user/{userId}', () => {
    service.getMyTickets(10).subscribe(tickets => {
      expect(tickets.length).toBe(1);
      expect(tickets[0].userId).toBe(10);
    });
    const req = httpMock.expectOne(`${API}/user/10`);
    expect(req.request.method).toBe('GET');
    req.flush([mockTicket]);
  });

  it('getPagedTickets() should GET with pagination params', () => {
    const paged: PagedTickets = { tickets: [mockTicket], totalItems: 1, totalPages: 1, currentPage: 0, pageSize: 10 };
    service.getPagedTickets(0, 10).subscribe(res => {
      expect(res.tickets.length).toBe(1);
      expect(res.totalItems).toBe(1);
    });
    const req = httpMock.expectOne(r => r.url === API && r.params.get('page') === '0');
    expect(req.request.method).toBe('GET');
    req.flush(paged);
  });

  it('updateTicket() should PUT to /update/{id}', () => {
    const updated = { ...mockTicket, status: 'IN_PROGRESS' };
    service.updateTicket(1, { status: 'IN_PROGRESS' }).subscribe(t => {
      expect(t.status).toBe('IN_PROGRESS');
    });
    const req = httpMock.expectOne(`${API}/update/1`);
    expect(req.request.method).toBe('PUT');
    req.flush(updated);
  });

  it('deleteTicket() should DELETE /{id}', () => {
    service.deleteTicket(1).subscribe(() => {});
    const req = httpMock.expectOne(`${API}/1`);
    expect(req.request.method).toBe('DELETE');
    req.flush(null);
  });

  it('escalateTicket() should POST to /escalate/{id}', () => {
    const escalated = { ...mockTicket, escalated: true, status: 'ESCALATED' };
    service.escalateTicket(1).subscribe(t => {
      expect(t.escalated).toBeTrue();
    });
    const req = httpMock.expectOne(`${API}/escalate/1`);
    expect(req.request.method).toBe('POST');
    req.flush(escalated);
  });

  it('getStatistics() should GET /statistics', () => {
    const stats: TicketStats = { total: 5, open: 2, inProgress: 1, resolved: 2, closed: 0, escalated: 0, slaBreached: 0, critical: 0, high: 1, todayNew: 1, weekNew: 3 };
    service.getStatistics().subscribe(s => {
      expect(s.total).toBe(5);
      expect(s.open).toBe(2);
    });
    const req = httpMock.expectOne(`${API}/statistics`);
    expect(req.request.method).toBe('GET');
    req.flush(stats);
  });

  it('regenerateSummary() should POST to /{id}/summarize', () => {
    service.regenerateSummary(1).subscribe(res => {
      expect(res.aiSummary).toBe('Short summary.');
    });
    const req = httpMock.expectOne(`${API}/1/summarize`);
    expect(req.request.method).toBe('POST');
    req.flush({ aiSummary: 'Short summary.' });
  });

  it('regenerateEnhancement() should POST to /{id}/enhance', () => {
    service.regenerateEnhancement(1).subscribe(res => {
      expect(res.enhancedDescription).toBe('Enhanced text.');
    });
    const req = httpMock.expectOne(`${API}/1/enhance`);
    expect(req.request.method).toBe('POST');
    req.flush({ enhancedDescription: 'Enhanced text.' });
  });

  it('enhanceText() should POST to /enhance-text', () => {
    service.enhanceText('Title', 'raw description').subscribe(res => {
      expect(res.enhanced).toBe('Improved description.');
    });
    const req = httpMock.expectOne(`${API}/enhance-text`);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({ title: 'Title', description: 'raw description' });
    req.flush({ enhanced: 'Improved description.' });
  });

  it('addResponse() should POST to /{id}/responses', () => {
    const response = { responderId: 1, responderName: 'User', isStaff: false, message: 'Hello' };
    service.addResponse(1, response).subscribe(r => {
      expect(r.message).toBe('Hello');
    });
    const req = httpMock.expectOne(`${API}/1/responses`);
    expect(req.request.method).toBe('POST');
    req.flush({ ...response, id: 1 });
  });
});

