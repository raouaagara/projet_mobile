import { Component, OnInit } from '@angular/core';
import { SubscriptionService, SubscriptionPlan } from '../../services-ayoub/subscription.service';

@Component({
  selector: 'app-admin-plans',
  templateUrl: './admin-plans.component.html',
  styleUrl: './admin-plans.component.css'
})
export class AdminPlansComponent implements OnInit {
  plans: SubscriptionPlan[] = [];
  loading = true;
  showForm = false;
  editingPlan: SubscriptionPlan | null = null;
  form: Partial<SubscriptionPlan> = {};
  message = '';

  planTypes = ['BASE', 'PREMIUM', 'ENTERPRISE'];
  durations = ['monthly', 'yearly'];

  constructor(private subscriptionService: SubscriptionService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.subscriptionService.getAllPlans().subscribe((p) => {
      this.plans = p || [];
      this.loading = false;
    });
  }

  openCreate(): void {
    this.editingPlan = null;
    this.form = { name: '', type: 'BASE', price: 0, duration: 'monthly', description: '', benefits: '', hasAiCvAccess: false, aiCvLimit: null as any };
    this.showForm = true;
    this.message = '';
  }

  openEdit(plan: SubscriptionPlan): void {
    this.editingPlan = plan;
    this.form = { ...plan };
    this.showForm = true;
    this.message = '';
  }

  closeForm(): void {
    this.showForm = false;
    this.editingPlan = null;
    this.form = {};
  }

  save(): void {
    if (!this.form.name || this.form.price == null || !this.form.type || !this.form.duration) {
      this.message = 'Name, type, price and duration are required.';
      return;
    }
    if (this.editingPlan?.id) {
      this.subscriptionService.updatePlan(this.editingPlan.id, this.form).subscribe({
        next: (updated) => {
          if (updated) {
            this.message = 'Plan updated.';
            this.load();
            this.closeForm();
          } else {
            this.message = 'Update failed.';
          }
        },
        error: () => (this.message = 'Update failed.')
      });
    } else {
      this.subscriptionService.createPlan(this.form as SubscriptionPlan).subscribe({
        next: (created) => {
          if (created) {
            this.message = 'Plan created.';
            this.load();
            this.closeForm();
          } else {
            this.message = 'Create failed. Check that SubscriptionMicroService is running on port 8083.';
          }
        },
        error: () => (this.message = 'Create failed. Check that SubscriptionMicroService is running on port 8083.')
      });
    }
  }

  deletePlan(plan: SubscriptionPlan): void {
    if (!plan.id || !confirm('Delete plan "' + plan.name + '"?')) return;
    this.subscriptionService.deletePlan(plan.id).subscribe({
      next: (ok) => { if (ok) { this.message = 'Plan deleted.'; this.load(); } else this.message = 'Delete failed.'; },
      error: () => (this.message = 'Delete failed.')
    });
  }
}
