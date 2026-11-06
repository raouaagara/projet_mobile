import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

@Component({
  selector: 'app-workspace',
  templateUrl: './workspace.component.html',
  styleUrl: './workspace.component.css'
})
export class WorkspaceComponent implements OnInit {

  contractId!: number;
  currentTab: string = 'activity'; // 'activity', 'submissions', 'details'
  
  // Simulation de l'utilisateur connecté (Tu remplaceras par la logique du Token)
  currentUserRole: string = 'FREELANCER'; // Change à 'CLIENT' pour voir l'autre vue
  
  // Données mockées pour l'UI
  workspaceData = {
    projectTitle: 'E-commerce App Development (Angular & Spring Boot)',
    budget: 1200.00,
    deadline: '2026-03-15',
    status: 'ACTIVE',
    clientName: 'Ghassen Hchaichi',
    freelancerName: 'Kenneth Silva',
    escrowStatus: 'FUNDED'
  };

  deliveryMessage: string = '';

  constructor(private route: ActivatedRoute) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.contractId = Number(id);
      // Ici tu chargeras le vrai contrat et les "Submissions" depuis ton backend
    }
  }

  submitWork() {
    if (!this.deliveryMessage) return;
    alert("Work submitted for review! The client will be notified.");
    this.deliveryMessage = '';
    // Logique d'envoi au backend (Sprint 2)
  }
}