import { Component, ElementRef, OnInit, ViewChild, AfterViewInit } from '@angular/core';
import { ContractService } from '../../Services/contract.service';
import { ActivatedRoute, Router } from '@angular/router';
import { Contract } from '../../models/contract';
import { UserService } from '../../Services/user.service'; 
import SignaturePad from 'signature_pad';

@Component({
  selector: 'app-contract-creation',
  templateUrl: './contract-creation.component.html',
  styleUrls: ['./contract-creation.component.css']
})
export class ContractCreationComponent implements OnInit, AfterViewInit {
  @ViewChild('signatureCanvas', { static: false }) signatureCanvas!: ElementRef<HTMLCanvasElement>;
  private signaturePad!: SignaturePad;
  signatureImg: string | null = null;

  currentDate: Date = new Date();
  showSuccessModal: boolean = false;
  isLoading: boolean = false;
  proposalId!: number;
  platformFeePercent: number = 0.03;

 
  currentUser: any = null;

  contractData: Contract = {
    projectId: 0,
    freelancerId: 0,
    clientId: 0, 
    projectTitle: 'Loading...',
    freelancerName: 'Loading...',
    clientName: 'Loading...', 
    rate: 0,
    startDate: new Date().toISOString().split('T')[0],
    deadline: '',
    status: 'SENT',
    terms: `1. Scope of Work:\nThe Contractor agrees to perform the services described in the proposal.\n\n2. Confidentiality:\nThe Contractor agrees to keep all information confidential.`
  };

  constructor(
    private contractService: ContractService,
    private route: ActivatedRoute,
    private router: Router,
    private userService: UserService 
  ) {

    const navigation = this.router.getCurrentNavigation();
    if (navigation?.extras.state) {
      this.contractData.freelancerName = navigation.extras.state['freelancerName'];
      this.contractData.projectTitle = navigation.extras.state['projectTitle'];
      this.contractData.rate = navigation.extras.state['bidAmount'];
      this.contractData.freelancerId = navigation.extras.state['freelancerId'];
    }
  }

  ngOnInit(): void {
    this.loadUserData(); 

    const pId = this.route.snapshot.paramMap.get('proposalId');
    if (pId) {
      this.proposalId = Number(pId);
      this.loadProposalDetails(this.proposalId);
    }
  }

  loadUserData() {
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
                this.contractData.clientId = user.id;
                this.contractData.clientName = user.firstName ;
              },
              error: (err) => console.error("Erreur Backend Profil :", err)
            });
          }
        }
      } catch (e) {
        console.error("Erreur token :", e);
      }
    }
  }

  loadProposalDetails(id: number) {
    this.isLoading = true;
    this.contractService.getProposalById(id).subscribe({
      next: (proposal) => {
        
        if (!this.contractData.rate) this.contractData.rate = proposal.bidAmount;
        if (!this.contractData.freelancerId) this.contractData.freelancerId = proposal.freelancerId;
        this.contractData.deadline = proposal.estimationEndDate;
        
        if (proposal.project) {
          if (this.contractData.projectTitle === 'Loading...') this.contractData.projectTitle = proposal.project.title;
          this.contractData.projectId = proposal.project.id;
        } else {
          if (this.contractData.projectTitle === 'Loading...') this.contractData.projectTitle = "Project #" + (proposal.projectId || "?");
        }
        
        if (this.contractData.freelancerName === 'Loading...') {
          this.contractData.freelancerName = proposal.freelancerName || ("Freelancer #" + proposal.freelancerId);
        }
        this.isLoading = false;
      },
      error: (err) => {
        console.error("Error loading details:", err);
        this.isLoading = false;
      }
    });
  }

 
  ngAfterViewInit() {
    if (this.signatureCanvas) {
      this.signaturePad = new SignaturePad(this.signatureCanvas.nativeElement, {
        backgroundColor: 'rgb(255, 255, 255)',
        penColor: 'rgb(0, 0, 0)'
      });

      this.resizeCanvas();
      window.addEventListener('resize', () => this.resizeCanvas());

      this.signaturePad.addEventListener("endStroke", () => {
        if (!this.signaturePad.isEmpty()) {
           this.signatureImg = this.signaturePad.toDataURL('image/png');
        }
      });
    }
  }

  resizeCanvas() {
    if (!this.signatureCanvas) return;
    const canvas = this.signatureCanvas.nativeElement;
    const ratio = Math.max(window.devicePixelRatio || 1, 1);
    canvas.width = canvas.offsetWidth * ratio;
    canvas.height = canvas.offsetHeight * ratio;
    canvas.getContext('2d')?.scale(ratio, ratio);
    this.signaturePad.clear(); 
    this.signatureImg = null; 
  }

  clearSignature() {
    this.signaturePad.clear();
    this.signatureImg = null;
  }


  calculatePlatformFee(): number { return (this.contractData.rate || 0) * this.platformFeePercent; }
  calculateTotalCost(): number { return (this.contractData.rate || 0) + this.calculatePlatformFee(); }

  sendOffer() {
    if (!this.contractData.startDate) {
      alert("Please select a Start Date.");
      return;
    }
    if (!this.signatureImg) {
      alert("Please sign the contract (draw in the box).");
      return;
    }

    this.isLoading = true;

    const requestData = {
      terms: this.contractData.terms,
      clientName: this.contractData.clientName,
      clientId: this.contractData.clientId,
      startDate: this.contractData.startDate,
      clientSignature: this.signatureImg 
    };

    this.contractService.generateContractFromProposal(this.proposalId, requestData).subscribe({
      next: (savedContract) => {
        this.contractData.id = savedContract.id;
        this.contractData.status = 'SENT';
        this.isLoading = false;
        this.showSuccessModal = true;
      },
      error: (err) => {
        console.error('API Error:', err);
        this.isLoading = false;
        alert('Failed to create contract.');
      }
    });
  }
}