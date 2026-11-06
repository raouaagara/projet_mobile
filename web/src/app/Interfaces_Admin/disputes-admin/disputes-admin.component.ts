import { Component, OnInit } from '@angular/core';
import { DisputeService, Dispute } from '../../Services/dispute.service';

export interface DisputeGroup {
  contractId: number;
  escrowId?: number;
  disputes: Dispute[];
  status: string;
}

@Component({
  selector: 'app-disputes-admin',
  templateUrl: './disputes-admin.component.html',
  styleUrls: ['./disputes-admin.component.css']
})
export class DisputesAdminComponent implements OnInit {

  disputes: Dispute[] = [];
  disputeGroups: DisputeGroup[] = [];
  selectedGroup: DisputeGroup | null = null;
  isLoading = true;
  isActionLoading = false;

  constructor(private disputeService: DisputeService) {}

  ngOnInit(): void {
    this.loadDisputes();
  }

  loadDisputes() {
    this.isLoading = true;
    this.disputeService.getAllDisputes().subscribe({
      next: (data) => {
        this.disputes = data;
        this.groupDisputesByContract();
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error fetching disputes', err);
        this.isLoading = false;
      }
    });
  }

  groupDisputesByContract() {
    const map = new Map<number, DisputeGroup>();
    for (const d of this.disputes) {
      const cid = d.contractId;
      if (!map.has(cid)) {
        map.set(cid, {
          contractId: cid,
          escrowId: d.escrow?.id,
          disputes: [],
          status: 'RESOLVED'
        });
      }
      const group = map.get(cid)!;
      group.disputes.push(d);
      if (d.status === 'OPEN' || d.status === 'IN_REVIEW') {
        group.status = 'OPEN';
      }
    }
    this.disputeGroups = Array.from(map.values());
  }

  viewGroup(group: DisputeGroup) {
    this.selectedGroup = group;
  }

  closeGroupView() {
    this.selectedGroup = null;
  }

  get activeDisputeForResolution(): Dispute | null {
    return this.selectedGroup?.disputes.find(d => d.status === 'OPEN' || d.status === 'IN_REVIEW') || null;
  }

  resolveDispute(resolution: 'CLIENT' | 'FREELANCER') {
    const activeDispute = this.activeDisputeForResolution;
    if (!activeDispute || !activeDispute.id) return;

    if (confirm(`Are you sure you want to resolve in favor of the ${resolution}? This is irreversible — escrow funds will be transferred and the contract will be closed.`)) {
      this.isActionLoading = true;
      this.disputeService.resolveDispute(activeDispute.id, resolution).subscribe({
        next: (updatedDispute) => {
          this.isActionLoading = false;
          const idx = this.disputes.findIndex(d => d.id === updatedDispute.id);
          if (idx !== -1) this.disputes[idx] = updatedDispute;
          this.groupDisputesByContract();
          if (this.selectedGroup) {
            const refreshed = this.disputeGroups.find(g => g.contractId === this.selectedGroup!.contractId);
            this.selectedGroup = refreshed || null;
          }
        },
        error: (err) => {
          console.error('Error resolving dispute', err);
          this.isActionLoading = false;
          alert('Failed to resolve dispute. Please check backend logs.');
        }
      });
    }
  }

  get openDisputesCount(): number {
    return this.disputeGroups.filter(g => g.status === 'OPEN').length;
  }
}
