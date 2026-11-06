import { Component, OnInit, OnDestroy } from '@angular/core';
import { Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { SubscriptionService, UserSubscription } from '../../services-ayoub/subscription.service';
import { UserService } from '../../services-ayoub/user.service';

interface AdminSubscriptionRow {
  id: number;
  userId: number;
  userName: string;
  userEmail: string;
  planName: string;
  planType: string;
  status: string;
  startDate: string;
  endDate: string;
  lastPaymentAmount: number;
  lastPaymentDate: string;
}

@Component({
  selector: 'app-admin-subscriptions',
  templateUrl: './admin-subscriptions.component.html',
  styleUrl: './admin-subscriptions.component.css'
})
export class AdminSubscriptionsComponent implements OnInit, OnDestroy {
  planFilter = 'ALL';
  statusFilter = 'ALL';
  searchQuery = '';
  searching = false;
  private search$ = new Subject<string>();

  rows: AdminSubscriptionRow[] = [];
  displayRows: AdminSubscriptionRow[] = [];
  currentPage = 1;
  pageSize = 10;
  pageSizeOptions = [5, 10, 25, 50];

  constructor(
    private subscriptionService: SubscriptionService,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    this.search$.pipe(
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(() => {
      this.searching = true;
      setTimeout(() => {
        this.applyFilters();
        this.searching = false;
      }, 150);
    });
    this.load();
  }

  load(): void {
    this.searching = true;
    this.subscriptionService.getAllSubscriptions().subscribe((subs) => {
      this.userService.getAllUsers().subscribe((users) => {
        const userMap = new Map(users.map(u => [u.id, u]));
        this.rows = (subs || []).map((s: UserSubscription) => {
          const u = userMap.get(s.userId);
          const payments = (s as any).payments || [];
          const lastPay = payments.length ? payments.reduce((a: any, b: any) =>
            (!a || (b.paidAt && a.paidAt && b.paidAt > a.paidAt)) ? b : a
          ) : null;
          return {
            id: s.id,
            userId: s.userId,
            userName: u ? `${u.firstName} ${u.lastName}` : 'User #' + s.userId,
            userEmail: u?.email ?? '-',
            planName: s.plan?.name ?? '-',
            planType: s.plan?.type ?? '-',
            status: s.status ?? 'PENDING',
            startDate: s.startDate ? String(s.startDate).slice(0, 10) : '-',
            endDate: s.endDate ? String(s.endDate).slice(0, 10) : '-',
            lastPaymentAmount: lastPay?.amount ?? 0,
            lastPaymentDate: lastPay?.paidAt ? String(lastPay.paidAt).slice(0, 10) : '-'
          };
        });
        this.applyFilters();
        this.searching = false;
      });
    });
  }

  ngOnDestroy(): void {
    this.search$.complete();
  }

  onSearchInput(): void {
    this.search$.next(this.searchQuery);
  }

  private applyFilters(): void {
    const q = this.searchQuery.toLowerCase().trim();
    this.displayRows = this.rows.filter((row: AdminSubscriptionRow) => {
      const planOk = this.planFilter === 'ALL' || row.planType === this.planFilter;
      const statusOk = this.statusFilter === 'ALL' || row.status === this.statusFilter;
      const searchOk = !q ||
        row.userName.toLowerCase().includes(q) ||
        row.userEmail.toLowerCase().includes(q) ||
        row.planName.toLowerCase().includes(q);
      return planOk && statusOk && searchOk;
    });
    this.currentPage = 1;
  }

  onPlanChange(): void {
    this.applyFilters();
  }

  onStatusChange(): void {
    this.applyFilters();
  }

  get paginatedRows(): AdminSubscriptionRow[] {
    const start = (this.currentPage - 1) * this.pageSize;
    return this.displayRows.slice(start, start + this.pageSize);
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.displayRows.length / this.pageSize));
  }

  goToPage(p: number): void {
    if (p >= 1 && p <= this.totalPages) this.currentPage = p;
  }

  get pageNumbers(): number[] {
    return Array.from({ length: this.totalPages }, (_, i) => i + 1);
  }

  onPageSizeChange(): void {
    this.currentPage = 1;
  }
}
