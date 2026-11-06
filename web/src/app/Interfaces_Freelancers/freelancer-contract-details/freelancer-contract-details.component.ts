import { Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import { Contract } from '../../models/contract';
import { ActivatedRoute } from '@angular/router';
import { ContractService } from '../../Services/contract.service';
import { UserService } from '../../Services/user.service'; // 🟢 INJECTION
import { DisputeService } from '../../Services/dispute.service';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';

@Component({
  selector: 'app-freelancer-contract-details',
  templateUrl: './freelancer-contract-details.component.html',
  styleUrls: ['./freelancer-contract-details.component.css']
})
export class FreelancerContractDetailsComponent implements OnInit {

  contract: Contract | null = null;
  isLoading: boolean = true;
  
  // 🟢 UTILISATEUR CONNECTÉ
  currentUser: any = null;
  currentFreelancerId: number | null = null;

  // Référence à la <div #contentToConvert> dans le HTML pour le PDF
  @ViewChild('contentToConvert') contentToConvert!: ElementRef;

  constructor(
    private route: ActivatedRoute,
    private contractService: ContractService,
    private userService: UserService, // 🟢 INJECTION
    private disputeService: DisputeService
  ) {}

  ngOnInit(): void {
    // 🟢 1. On charge l'utilisateur
    this.loadUserData();
  }

  loadUserData() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        if (token) {
          const payload = token.split('.')[1];
          const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
          this.currentFreelancerId = decodedPayload.id;

          if (this.currentFreelancerId) {
            this.userService.getUserById(this.currentFreelancerId).subscribe({
              next: (user) => {
                this.currentUser = user;
                // 🟢 2. Une fois l'utilisateur chargé, on charge le contrat
                const contractId = Number(this.route.snapshot.paramMap.get('id'));
                if (contractId) {
                  this.loadContract(contractId);
                } else {
                  this.isLoading = false;
                }
              },
              error: (err) => {
                console.error("Erreur Backend Profil :", err);
                this.isLoading = false;
              }
            });
          }
        }
      } catch (e) {
        console.error("Erreur token :", e);
        this.isLoading = false;
      }
    } else {
      this.isLoading = false;
    }
  }

  loadContract(contractId: number) {
    if (!this.currentFreelancerId) return;

    this.contractService.getFreelancerContracts(this.currentFreelancerId).subscribe({
      next: (contracts) => {
        this.contract = contracts.find(c => c.id === contractId) || null;
        this.isLoading = false;
      },
      error: (err) => {
        console.error("Error loading contract", err);
        this.isLoading = false;
      }
    });
  }

  public downloadPDF() {
    if (!this.contract) return;

    const data = this.contentToConvert.nativeElement;
    const btn = document.getElementById('downloadBtn');
    if(btn) btn.innerHTML = '<i class="fa fa-circle-notch fa-spin"></i> Generating PDF...';

    html2canvas(data, { scale: 2 }).then(canvas => {
      const imgWidth = 210; // Format A4
      const pageHeight = 297; 
      const imgHeight = canvas.height * imgWidth / canvas.width;
      
      const contentDataURL = canvas.toDataURL('image/png');
      const pdf = new jsPDF('p', 'mm', 'a4');
      
      pdf.addImage(contentDataURL, 'PNG', 0, 0, imgWidth, imgHeight);
      
      // Nom du fichier propre sans espaces
      const safeTitle = this.contract?.projectTitle.replace(/[^a-z0-9]/gi, '_').toLowerCase();
      pdf.save(`Contract_${safeTitle}_Signed.pdf`);
      
      if(btn) btn.innerHTML = '<i class="fa fa-file-download"></i> Download Signed PDF';
    }).catch(err => {
      console.error("Error generating PDF", err);
      if(btn) btn.innerHTML = '<i class="fa fa-file-download"></i> Download Signed PDF';
    });
  }

  // --- DISPUTE LOGIC ---
  showDisputeModal = false;
  disputeReason = '';
  isDisputing = false;

  openDisputeModal() {
    this.showDisputeModal = true;
  }

  closeDisputeModal() {
    this.showDisputeModal = false;
    this.disputeReason = '';
  }

  submitDispute() {
    if (!this.disputeReason.trim() || !this.contract || !this.currentFreelancerId) return;
    
    this.isDisputing = true;
    this.disputeService.raiseDispute(this.contract.id!, this.currentFreelancerId, this.disputeReason).subscribe({
      next: (res) => {
        this.isDisputing = false;
        this.closeDisputeModal();
        alert('Dispute raised successfully. Our Admin team will review it shortly.');
      },
      error: (err) => {
        console.error('Error raising dispute', err);
        this.isDisputing = false;
        alert('Failed to raise dispute. Make sure the escrow is locked and not already closed.');
      }
    });
  }
}