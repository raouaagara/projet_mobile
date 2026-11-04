import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { SubscriptionService } from '../../services-ayoub/subscription.service';

@Component({
  selector: 'app-subscription-detail',
  templateUrl: './subscription-detail.component.html',
  styleUrl: './subscription-detail.component.css'
})
export class SubscriptionDetailComponent implements OnInit {
  plan: { id: number; name: string; type: string; price: number; duration: string; description: string; benefits: string[]; popular?: boolean } | null = null;
  loading = true;

  constructor(
    private route: ActivatedRoute,
    private subscriptionService: SubscriptionService
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.subscriptionService.getPlanById(+id).subscribe((p) => {
        if (p) {
          this.plan = {
            id: p.id ?? 0,
            name: p.name || 'Plan',
            type: (p.type || '').toLowerCase(),
            price: p.price ?? 0,
            duration: p.duration || 'monthly',
            description: p.description || '',
            benefits: p.benefits ? p.benefits.split(',').map(b => b.trim()).filter(Boolean) : [],
            popular: (p.type || '').toUpperCase() === 'PREMIUM'
          };
        } else {
          this.plan = null;
        }
        this.loading = false;
      });
    } else {
      this.loading = false;
    }
  }
}
