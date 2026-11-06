import { Component, OnInit } from '@angular/core';
import { SubscriptionService } from '../../services-ayoub/subscription.service';

export interface SubscriptionPlanDisplay {
  id: number;
  name: string;
  type: string;
  price: number;
  duration: string;
  benefits: string[];
  popular?: boolean;
}

@Component({
  selector: 'app-subscription-plans',
  templateUrl: './subscription-plans.component.html',
  styleUrl: './subscription-plans.component.css'
})
export class SubscriptionPlansComponent implements OnInit {
  priceFilter: string = 'all';
  durationFilter: string = 'all';
  plans: SubscriptionPlanDisplay[] = [];
  loading = true;

  constructor(private subscriptionService: SubscriptionService) {}

  ngOnInit(): void {
    this.subscriptionService.getAllPlans().subscribe((apiPlans) => {
      this.plans = (apiPlans || []).map((p) => ({
        id: p.id ?? 0,
        name: p.name || 'Plan',
        type: (p.type || '').toLowerCase(),
        price: p.price ?? 0,
        duration: p.duration || 'monthly',
        benefits: p.benefits ? p.benefits.split(',').map((b) => b.trim()).filter(Boolean) : [],
        popular: (p.type || '').toUpperCase() === 'PREMIUM'
      }));
      this.loading = false;
    });
  }

  get filteredPlans(): SubscriptionPlanDisplay[] {
    return this.plans.filter(p => {
      const priceMatch = this.priceFilter === 'all' ||
        (this.priceFilter === 'low' && p.price <= 15) ||
        (this.priceFilter === 'mid' && p.price > 15 && p.price <= 30) ||
        (this.priceFilter === 'high' && p.price > 30);
      const durationMatch = this.durationFilter === 'all' || p.duration === this.durationFilter;
      return priceMatch && durationMatch;
    });
  }
}
