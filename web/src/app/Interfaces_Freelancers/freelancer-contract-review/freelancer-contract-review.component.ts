import { AfterViewInit, Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import SignaturePad from 'signature_pad';
import { Contract } from '../../models/contract';
import { ActivatedRoute, Router } from '@angular/router';
import { ContractService } from '../../Services/contract.service';
import { UserService } from '../../Services/user.service'; // 🟢 INJECTION DU SERVICE USER

@Component({
  selector: 'app-freelancer-contract-review',
  templateUrl: './freelancer-contract-review.component.html',
  styleUrls: ['./freelancer-contract-review.component.css']
})
export class FreelancerContractReviewComponent implements OnInit, AfterViewInit {

  contract: Contract | null = null;
  isLoading: boolean = true;
  isProcessing: boolean = false;
  currentDate: Date = new Date();

  // 🟢 UTILISATEUR CONNECTÉ
  currentUser: any = null;
  currentFreelancerId: number | null = null;

  // Signature Pad Logic
  @ViewChild('signatureCanvas', { static: false }) signatureCanvas!: ElementRef<HTMLCanvasElement>;
  private signaturePad!: SignaturePad;
  signatureImg: string | null = null;

  constructor(
    private route: ActivatedRoute, 
    private router: Router,
    private contractService: ContractService,
    private userService: UserService 
  ) {}

  ngOnInit(): void {
   
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
              
                const contractIdParam = this.route.snapshot.paramMap.get('id');
                if (contractIdParam) {
                  this.loadContract(Number(contractIdParam));
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

  loadContract(id: number) {
    if (!this.currentFreelancerId) return;

    this.contractService.getFreelancerContracts(this.currentFreelancerId).subscribe({
      next: (contracts) => {
        this.contract = contracts.find(c => c.id === id) || null;
        this.isLoading = false;
      },
      error: (err) => {
        console.error("Error loading contract", err);
        this.isLoading = false;
      }
    });
  }

 
  ngAfterViewInit() {

  }

  initSignaturePad() {
    if (this.signatureCanvas && !this.signaturePad) {
      this.signaturePad = new SignaturePad(this.signatureCanvas.nativeElement, {
        backgroundColor: 'rgb(255, 255, 255)',
        penColor: 'rgb(0, 0, 0)'
      });

      this.resizeCanvas();
      window.addEventListener('resize', () => this.resizeCanvas());

      this.signaturePad.addEventListener("endStroke", () => {
         if(!this.signaturePad.isEmpty()) {
           this.signatureImg = this.signaturePad.toDataURL('image/png');
         }
      });
    }
  }

  resizeCanvas() {
    if (this.signatureCanvas) {
      const canvas = this.signatureCanvas.nativeElement;
      const ratio = Math.max(window.devicePixelRatio || 1, 1);
      canvas.width = canvas.offsetWidth * ratio;
      canvas.height = canvas.offsetHeight * ratio;
      canvas.getContext('2d')?.scale(ratio, ratio);
      this.signaturePad.clear(); 
      this.signatureImg = null;
    }
  }

  clearSignature() {
    if (this.signaturePad) {
      this.signaturePad.clear();
      this.signatureImg = null;
    }
  }

acceptContract() {
  if (!this.contract || !this.contract.id) return;
  if (!this.signatureImg) return alert("Please sign the contract first.");
  
  // Ensure we have user data to get the name
  if (!this.currentUser) {
    alert("User profile not loaded yet. Please wait.");
    return;
  }

  this.isProcessing = true;

  // Determine the name to save (handle various user object structures)
  const fName = this.currentUser.firstName || this.currentUser.name || '';
  const lName = this.currentUser.lastName || '';
  const fullName = (fName + ' ' + lName).trim();

  // Prepare the payload for the backend
  const payload = {
    signature: this.signatureImg,
    freelancerName: fullName // This is the field that was missing!
  };

  // Call the service with the payload instead of just a string
  this.contractService.signContract(this.contract.id, payload).subscribe({
    next: () => {
      this.isProcessing = false;
      alert("Contract Signed Successfully! You can now start working.");
      this.router.navigate(['/FreelancerContracts']);
    },
    error: (err) => {
      this.isProcessing = false;
      console.error("Signature Error:", err);
      alert("Error signing contract. Please try again.");
    }
  });
}

  rejectContract() {
    if (!this.contract) return;
    if(!confirm("Are you sure you want to reject this offer? This action cannot be undone.")) return;
    
    this.isProcessing = true;
    this.contractService.rejectContract(this.contract.id!).subscribe({
      next: () => {
        this.isProcessing = false;
        alert("Offer rejected.");
        this.router.navigate(['/FreelancerContracts']);
      },
      error: () => {
        this.isProcessing = false;
        alert("Error rejecting contract.");
      }
    });
  }
}