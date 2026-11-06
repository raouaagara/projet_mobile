import { Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import { Contract } from '../../models/contract';
import { ActivatedRoute } from '@angular/router';
import { ContractService } from '../../Services/contract.service';
import { UserService } from '../../Services/user.service';
import { DisputeService } from '../../Services/dispute.service';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

@Component({
  selector: 'app-client-contract-details',
  templateUrl: './client-contract-details.component.html',
  styleUrls: ['./client-contract-details.component.css']
})
export class ClientContractDetailsComponent implements OnInit {
  contract: Contract | null = null;
  isLoading: boolean = true;
  contractId!: number;

  currentUser: any = null;

  @ViewChild('contentToConvert') contentToConvert!: ElementRef;

  constructor(
    private route: ActivatedRoute,
    private contractService: ContractService,
    private userService: UserService,
    private disputeService: DisputeService
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.contractId = Number(id);
      this.loadUserDataAndContract(); 
    } else {
      this.isLoading = false;
    }
  }

  loadUserDataAndContract() {
    const storedData = localStorage.getItem('currentUser');
    if (storedData) {
      try {
        let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
        if (token) {
          const payload = token.split('.')[1];
          const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));
          const currentUserId = decodedPayload.id;

          if (currentUserId) {
            this.userService.getUserById(currentUserId).subscribe({
              next: (user) => {
                this.currentUser = user;
                this.loadContract(currentUserId);
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

  loadContract(clientId: number) {
    this.contractService.getClientContracts(clientId).subscribe({ 
      next: (contracts) => {
        this.contract = contracts.find(c => c.id === this.contractId) || null;
        
        // 🟢 MAGIE ICI : Si on a trouvé le contrat et qu'il a un freelancerId
        if (this.contract && this.contract.freelancerId) {
          
          // On va chercher les vraies informations du Freelancer dans la base de données
          this.userService.getUserById(this.contract.freelancerId).subscribe({
            next: (freelancerUser) => {
              // On assemble son prénom et son nom et on le met dans le contrat !
              this.contract!.freelancerName = `${freelancerUser.firstName} ${freelancerUser.lastName || ''}`.trim();
              this.isLoading = false;
            },
            error: (err) => {
              console.error("Erreur chargement du profil Freelancer", err);
              this.isLoading = false; // On arrête le chargement même s'il y a une erreur
            }
          });

        } else {
          this.isLoading = false;
        }
      },
      error: (err) => {
        console.error("Error loading contract:", err);
        this.isLoading = false;
      }
    });
  }

  public downloadPDF() {
    const data = this.contentToConvert.nativeElement;
    const btn = document.getElementById('downloadBtn');
    if(btn) btn.innerHTML = '<i class="fa fa-circle-notch fa-spin"></i> Generating...';

    html2canvas(data, { scale: 2 }).then(canvas => {
      const imgWidth = 208; 
      const pageHeight = 295; 
      const imgHeight = canvas.height * imgWidth / canvas.width;
      
      const contentDataURL = canvas.toDataURL('image/png');
      const pdf = new jsPDF('p', 'mm', 'a4');
      
      pdf.addImage(contentDataURL, 'PNG', 0, 0, imgWidth, imgHeight);
      pdf.save(`Contract_${this.contractId}_CatchIQ.pdf`);
      
      if(btn) btn.innerHTML = '<i class="fa fa-file-download"></i> Download PDF';
    }).catch(err => {
      console.error("PDF Error", err);
      if(btn) btn.innerHTML = '<i class="fa fa-file-download"></i> Download PDF';
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
    if (!this.disputeReason.trim() || !this.contract || !this.currentUser) return;
    
    this.isDisputing = true;
    this.disputeService.raiseDispute(this.contract.id!, this.currentUser.id, this.disputeReason).subscribe({
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