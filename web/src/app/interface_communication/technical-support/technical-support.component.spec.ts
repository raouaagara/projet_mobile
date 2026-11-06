import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { of, throwError } from 'rxjs';
import { TechnicalSupportComponent } from './technical-support.component';
import { TicketService, Ticket } from '../../Services/ticket.service';

describe('TechnicalSupportComponent', () => {
  let component: TechnicalSupportComponent;
  let fixture: ComponentFixture<TechnicalSupportComponent>;
  let ticketServiceSpy: jasmine.SpyObj<TicketService>;

  const mockTicket: Ticket = {
    id: 1, userId: 10, title: 'Test', description: 'Desc',
    status: 'OPEN', priority: 'MEDIUM', category: 'TECHNICAL_ISSUE',
    createdAtStr: '2026-01-01T10:00:00'
  };

  beforeEach(async () => {
    ticketServiceSpy = jasmine.createSpyObj('TicketService', [
      'getMyTickets', 'createTicket', 'getResponses', 'addResponse',
      'escalateTicket', 'enhanceText', 'connectWebSocket', 'disconnectWebSocket',
      'notificationSubject'
    ]);
    ticketServiceSpy.getMyTickets.and.returnValue(of([mockTicket]));
    ticketServiceSpy.notificationSubject = { subscribe: () => ({ unsubscribe: () => {} }) } as any;

    await TestBed.configureTestingModule({
      declarations: [TechnicalSupportComponent],
      imports: [FormsModule, CommonModule],
      providers: [{ provide: TicketService, useValue: ticketServiceSpy }]
    }).compileComponents();

    fixture = TestBed.createComponent(TechnicalSupportComponent);
    component = fixture.componentInstance;
    component.currentUserId = 10;
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should load tickets on init', () => {
    component.loadTickets();
    expect(ticketServiceSpy.getMyTickets).toHaveBeenCalledWith(10);
    expect(component.tickets.length).toBe(1);
  });

  it('should filter tickets by status', () => {
    component.tickets = [
      { ...mockTicket, status: 'OPEN' },
      { ...mockTicket, id: 2, status: 'RESOLVED' }
    ];
    component.filterStatus = 'OPEN';
    component.applyFilters();
    expect(component.filteredTickets.length).toBe(1);
    expect(component.filteredTickets[0].status).toBe('OPEN');
  });

  it('should filter tickets by search query', () => {
    component.tickets = [
      { ...mockTicket, title: 'Payment issue' },
      { ...mockTicket, id: 2, title: 'Login problem' }
    ];
    component.searchQuery = 'payment';
    component.applyFilters();
    expect(component.filteredTickets.length).toBe(1);
  });

  it('submitTicket() should call createTicket and show success', () => {
    ticketServiceSpy.createTicket.and.returnValue(of(mockTicket));
    component.newTicket = { title: 'Test', description: 'Desc', priority: 'MEDIUM', category: '' };
    component.submitTicket();
    expect(ticketServiceSpy.createTicket).toHaveBeenCalled();
    expect(component.successMsg).toBeTruthy();
  });

  it('submitTicket() should show error if title is empty', () => {
    component.newTicket = { title: '', description: 'Desc', priority: 'MEDIUM', category: '' };
    component.submitTicket();
    expect(component.errorMsg).toBeTruthy();
    expect(ticketServiceSpy.createTicket).not.toHaveBeenCalled();
  });

  it('enhanceDescription() should call enhanceText and update description', () => {
    ticketServiceSpy.enhanceText.and.returnValue(of({ enhanced: 'Improved description.' }));
    component.newTicket = { title: 'Title', description: 'raw text', priority: 'MEDIUM', category: '' };
    component.enhanceDescription();
    expect(ticketServiceSpy.enhanceText).toHaveBeenCalledWith('Title', 'raw text');
    expect(component.newTicket.description).toBe('Improved description.');
    expect(component.enhanced).toBeTrue();
  });

  it('enhanceDescription() should show error on failure', () => {
    ticketServiceSpy.enhanceText.and.returnValue(throwError(() => new Error('Network error')));
    component.newTicket = { title: 'T', description: 'some text', priority: 'MEDIUM', category: '' };
    component.enhanceDescription();
    expect(component.errorMsg).toBeTruthy();
    expect(component.enhancing).toBeFalse();
  });

  it('enhanceDescription() should not call if description is empty', () => {
    component.newTicket = { title: 'T', description: '', priority: 'MEDIUM', category: '' };
    component.enhanceDescription();
    expect(ticketServiceSpy.enhanceText).not.toHaveBeenCalled();
  });

  it('openDetail() should load responses', () => {
    ticketServiceSpy.getResponses.and.returnValue(of([]));
    component.openDetail(mockTicket);
    expect(component.selectedTicket).toEqual(mockTicket);
    expect(component.view).toBe('detail');
    expect(ticketServiceSpy.getResponses).toHaveBeenCalledWith(1);
  });

  it('goBack() should reset view to list', () => {
    component.view = 'detail';
    component.goBack();
    expect(component.view).toBe('list');
    expect(component.selectedTicket).toBeNull();
  });

  it('formatLabel() should replace underscores with spaces', () => {
    expect(component.formatLabel('TECHNICAL_ISSUE')).toBe('TECHNICAL ISSUE');
  });

  it('getStatusClass() should return correct CSS class', () => {
    expect(component.getStatusClass('OPEN')).toBe('badge-open');
    expect(component.getStatusClass('RESOLVED')).toBe('badge-resolved');
    expect(component.getStatusClass('ESCALATED')).toBe('badge-escalated');
  });
});
