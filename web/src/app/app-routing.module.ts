import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { HomeAppComponent } from './home-app/home-app.component';
import { AuthComponent } from './Interfaces_Authentification/auth/auth.component';
import { LoginClientComponent } from './Interfaces_Authentification/login-client/login-client.component';
import { LoginFreelancerComponent } from './Interfaces_Authentification/login-freelancer/login-freelancer.component';
import { RegisterClientComponent } from './Interfaces_Authentification/register-client/register-client.component';
import { RegisterFreelancerComponent } from './Interfaces_Authentification/register-freelancer/register-freelancer.component';
import { TechnicalSupportComponent } from './interface_communication/technical-support/technical-support.component';
import { MessengerComponent } from './interface_communication/messenger/messenger.component';
import { UserAdminComponent } from './Interfaces_Admin/user-admin/user-admin.component';
import { authGuard } from './Interfaces_Authentification/Guards/auth.guard';
import { WorkspaceComponent } from './workspace/workspace.component';
import { MessagesComponent } from './interface_communication/messages/messages.component';
import { MyAvailabilityComponent } from './Interfaces_Availability/my-availability/my-availability.component';
import { WorldClockViewComponent } from './Interfaces_Availability/world-clock-view/world-clock-view.component';

import { AdminSupportComponent } from './Interfaces_Admin/admin-support/admin-support.component';

const routes: Routes = [
  {path:'',component: HomeAppComponent, },
  {path:'Workspace',component: WorkspaceComponent, },

  // Authentification routes
  {path:'Auth',component: AuthComponent, },
  {path:'LoginClient',component: LoginClientComponent, },
  {path:'LoginFreelancer',component: LoginFreelancerComponent, },
  {path:'RegisterClient',component: RegisterClientComponent, },
  {path:'RegisterFreelancer',component: RegisterFreelancerComponent, },

  // Communication & support routes
  {path:'TechnicalSupport',component:TechnicalSupportComponent, },
  {path:'Messenger',component:MessengerComponent, },
  {path:'Messages',component:MessagesComponent, },

  // Admin routes (users and support)
  {path:'AdminUsers',component:UserAdminComponent, },
  {path:'AdminSupport',component:AdminSupportComponent, },

  // Availability & time zones
  {path:'MyAvailability',component:MyAvailabilityComponent, canActivate: [authGuard], data: { role: 'FREELANCER' } },
  {path:'WorldClock',component:WorldClockViewComponent, canActivate: [authGuard], data: { role: 'CLIENT' }},
  {path:'worldclock',redirectTo:'WorldClock', pathMatch:'full' },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
