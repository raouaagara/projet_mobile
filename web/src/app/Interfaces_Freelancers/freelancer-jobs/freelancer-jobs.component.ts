import { Component } from '@angular/core';

@Component({
  selector: 'app-freelancer-jobs',
  templateUrl: './freelancer-jobs.component.html',
  styleUrl: './freelancer-jobs.component.css'
})
export class FreelancerJobsComponent {
activeTab: 'active' | 'proposals' | 'completed' = 'active';

  setActiveTab(tab: 'active' | 'proposals' | 'completed') {
    this.activeTab = tab;
  }
}
