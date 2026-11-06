import { Component } from '@angular/core';

@Component({
  selector: 'app-virtual-contract',
  templateUrl: './virtual-contract.component.html',
  styleUrl: './virtual-contract.component.css'
})
export class VirtualContractComponent {
  currentDate = new Date();
  showSuccessModal = false;

  sendOffer() {
    // Simulate API call
    setTimeout(() => {
      this.showSuccessModal = true;
    }, 500);
  }

}
