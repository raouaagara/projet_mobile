import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

export const authGuard: CanActivateFn = (route, state) => {

  const router = inject(Router); 
  const storedData = localStorage.getItem('currentUser');

 
  if (!storedData) {
    router.navigate(['/Auth']); 
    return false;
  }

  try {
    let token = storedData.includes('token') ? JSON.parse(storedData).token : storedData;
    const payload = token.split('.')[1];
    const decodedPayload = JSON.parse(decodeURIComponent(escape(window.atob(payload))));

    const expectedRole = route.data['role']; 
    
    if (expectedRole && decodedPayload.role && decodedPayload.role !== expectedRole) {
      if (decodedPayload.role === 'FREELANCER') {
        router.navigate(['/FreelancerFeed']);
      } else {
        router.navigate(['/ClientFeed']);
      }
      return false;
    }

    return true; 
    
  } catch (e) {
    localStorage.removeItem('currentUser');
    router.navigate(['/Auth']);
    return false;
  }
};