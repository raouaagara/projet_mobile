import { Component, OnInit } from '@angular/core';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { SubscriptionService } from '../../services-ayoub/subscription.service';

interface PlanStats {
  plan: string;
  count: number;
  revenue: number;
  color: string;
}

@Component({
  selector: 'app-admin-statistics',
  templateUrl: './admin-statistics.component.html',
  styleUrl: './admin-statistics.component.css'
})
export class AdminStatisticsComponent implements OnInit {
  loading = true;
  
  stats = {
    totalSubscribers: 0,
    activeSubscriptions: 0,
    monthlyRevenue: 0,
    conversionRate: 0,
    totalSubscribersTrend: 0,
    activeTrend: 0,
    revenueTrend: 0,
    conversionTrend: 0,
    byPlan: [] as PlanStats[],
    monthlyRevenueData: [] as number[]
  };

  // Line chart - Monthly Revenue
  lineChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Revenue ($)',
      fill: true,
      tension: 0.4,
      borderColor: '#10b981',
      backgroundColor: 'rgba(16, 185, 129, 0.1)',
      pointBackgroundColor: '#10b981',
      pointBorderColor: '#fff',
      pointHoverBackgroundColor: '#fff',
      pointHoverBorderColor: '#10b981'
    }]
  };

  lineChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: 'rgba(0,0,0,0.8)',
        padding: 12,
        titleFont: { size: 14 },
        bodyFont: { size: 13 }
      }
    },
    scales: {
      y: {
        beginAtZero: false,
        grid: { color: 'rgba(0,0,0,0.05)' },
        ticks: { callback: v => '$' + v }
      },
      x: {
        grid: { display: false }
      }
    }
  };

  lineChartType: ChartType = 'line';

  // Bar chart - Subscribers by Plan
  barChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Subscribers',
      backgroundColor: [],
      borderRadius: 8
    }]
  };

  barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: { backgroundColor: 'rgba(0,0,0,0.8)' }
    },
    scales: {
      y: {
        beginAtZero: true,
        grid: { color: 'rgba(0,0,0,0.05)' }
      },
      x: {
        grid: { display: false }
      }
    }
  };

  barChartType: ChartType = 'bar';

  // Doughnut chart - Revenue Distribution
  doughnutChartData: ChartData<'doughnut'> = {
    labels: [],
    datasets: [{
      data: [],
      backgroundColor: [],
      borderWidth: 2,
      borderColor: '#fff'
    }]
  };

  doughnutChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'bottom',
        labels: { padding: 20, usePointStyle: true }
      }
    },
    cutout: '65%'
  } as ChartConfiguration['options'];

  doughnutChartType: ChartType = 'doughnut';

  constructor(private subscriptionService: SubscriptionService) {}

  ngOnInit(): void {
    this.loadStatistics();
  }

  loadStatistics(): void {
    this.loading = true;
    
    this.subscriptionService.getAllSubscriptions().subscribe(subscriptions => {
      // Calculate total subscribers
      this.stats.totalSubscribers = subscriptions.length;
      
      // Calculate active subscriptions
      this.stats.activeSubscriptions = subscriptions.filter(s => s.status === 'ACTIVE').length;
      
      // Calculate conversion rate
      this.stats.conversionRate = this.stats.totalSubscribers > 0 
        ? Math.round((this.stats.activeSubscriptions / this.stats.totalSubscribers) * 100)
        : 0;
      
      // Group by plan type
      const planColors: { [key: string]: string } = {
        'BASE': '#6366f1',
        'PREMIUM': '#10b981',
        'ENTERPRISE': '#f59e0b'
      };
      
      const planGroups = new Map<string, { count: number, revenue: number }>();
      
      subscriptions.forEach(sub => {
        const planType = sub.plan?.type || 'UNKNOWN';
        if (!planGroups.has(planType)) {
          planGroups.set(planType, { count: 0, revenue: 0 });
        }
        const group = planGroups.get(planType)!;
        group.count++;
        
        // Calculate revenue from payments
        const payments = (sub as any).payments || [];
        const subRevenue = payments.reduce((sum: number, p: any) => sum + (p.amount || 0), 0);
        group.revenue += subRevenue;
      });
      
      // Convert to array
      this.stats.byPlan = Array.from(planGroups.entries()).map(([plan, data]) => ({
        plan,
        count: data.count,
        revenue: data.revenue,
        color: planColors[plan] || '#6b7280'
      }));
      
      // Calculate total monthly revenue (sum of all payments in current month)
      const now = new Date();
      const currentMonth = now.getMonth();
      const currentYear = now.getFullYear();
      
      let monthlyRevenue = 0;
      subscriptions.forEach(sub => {
        const payments = (sub as any).payments || [];
        payments.forEach((p: any) => {
          if (p.paidAt) {
            const paymentDate = new Date(p.paidAt);
            if (paymentDate.getMonth() === currentMonth && paymentDate.getFullYear() === currentYear) {
              monthlyRevenue += p.amount || 0;
            }
          }
        });
      });
      
      this.stats.monthlyRevenue = monthlyRevenue;
      
      // Calculate monthly revenue trend (last 6 months)
      const monthlyData: { [key: string]: number } = {};
      const monthLabels: string[] = [];
      
      for (let i = 5; i >= 0; i--) {
        const d = new Date(currentYear, currentMonth - i, 1);
        const monthKey = `${d.getFullYear()}-${d.getMonth()}`;
        const monthLabel = d.toLocaleDateString('en-US', { month: 'short' });
        monthlyData[monthKey] = 0;
        monthLabels.push(monthLabel);
      }
      
      subscriptions.forEach(sub => {
        const payments = (sub as any).payments || [];
        payments.forEach((p: any) => {
          if (p.paidAt) {
            const paymentDate = new Date(p.paidAt);
            const monthKey = `${paymentDate.getFullYear()}-${paymentDate.getMonth()}`;
            if (monthlyData.hasOwnProperty(monthKey)) {
              monthlyData[monthKey] += p.amount || 0;
            }
          }
        });
      });
      
      this.stats.monthlyRevenueData = Object.values(monthlyData);
      
      // Update charts
      this.updateCharts(monthLabels);
      
      // Calculate trends (mock for now - would need historical data)
      this.stats.totalSubscribersTrend = 12;
      this.stats.activeTrend = 8;
      this.stats.revenueTrend = 15;
      this.stats.conversionTrend = -2;
      
      this.loading = false;
    });
  }

  updateCharts(monthLabels: string[]): void {
    // Update line chart
    this.lineChartData = {
      labels: monthLabels,
      datasets: [{
        data: this.stats.monthlyRevenueData,
        label: 'Revenue ($)',
        fill: true,
        tension: 0.4,
        borderColor: '#10b981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        pointBackgroundColor: '#10b981',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: '#10b981'
      }]
    };
    
    // Update bar chart
    this.barChartData = {
      labels: this.stats.byPlan.map(p => p.plan),
      datasets: [{
        data: this.stats.byPlan.map(p => p.count),
        label: 'Subscribers',
        backgroundColor: this.stats.byPlan.map(p => p.color),
        borderRadius: 8
      }]
    };
    
    // Update doughnut chart
    this.doughnutChartData = {
      labels: this.stats.byPlan.map(p => p.plan),
      datasets: [{
        data: this.stats.byPlan.map(p => p.revenue),
        backgroundColor: this.stats.byPlan.map(p => p.color),
        borderWidth: 2,
        borderColor: '#fff'
      }]
    };
  }

  getTotalRevenue(): number {
    return this.stats.byPlan.reduce((s, p) => s + p.revenue, 0);
  }

  getPlanPercent(plan: { count: number }): number {
    const total = this.stats.byPlan.reduce((s, p) => s + p.count, 0);
    return total ? Math.round((plan.count / total) * 100) : 0;
  }
}
