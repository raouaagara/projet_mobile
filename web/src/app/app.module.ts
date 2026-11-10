import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BaseChartDirective } from 'ng2-charts'; 
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { HomeAppComponent } from './home-app/home-app.component';
import { AuthComponent } from './Interfaces_Authentification/auth/auth.component';
import { LoginFreelancerComponent } from './Interfaces_Authentification/login-freelancer/login-freelancer.component';
import { LoginClientComponent } from './Interfaces_Authentification/login-client/login-client.component';
import { RegisterFreelancerComponent } from './Interfaces_Authentification/register-freelancer/register-freelancer.component';
import { RegisterClientComponent } from './Interfaces_Authentification/register-client/register-client.component';
import { CommonModule } from '@angular/common';
import { MessengerComponent } from './interface_communication/messenger/messenger.component';
import { TechnicalSupportComponent } from './interface_communication/technical-support/technical-support.component';
import { UserAdminComponent } from './Interfaces_Admin/user-admin/user-admin.component';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { WorkspaceComponent } from './workspace/workspace.component';
import { MessagesComponent } from './interface_communication/messages/messages.component';
import { MyAvailabilityComponent } from './Interfaces_Availability/my-availability/my-availability.component';
import { WorldClockViewComponent } from './Interfaces_Availability/world-clock-view/world-clock-view.component';
import { NotificationCenterComponent } from './shared/notification-center/notification-center.component';
import { DarkModeToggleComponent } from './shared/dark-mode-toggle/dark-mode-toggle.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { AdminSupportComponent } from './Interfaces_Admin/admin-support/admin-support.component';

@NgModule({
  declarations: [
    AppComponent,
    HomeAppComponent,
    AuthComponent,
    LoginFreelancerComponent,
    LoginClientComponent,
    RegisterFreelancerComponent,
    RegisterClientComponent,
    MessengerComponent,
    MessagesComponent,
    TechnicalSupportComponent,
    WorkspaceComponent,
    UserAdminComponent,
    AdminSupportComponent,
    NotificationCenterComponent,
    DarkModeToggleComponent,
    MyAvailabilityComponent,
    WorldClockViewComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    CommonModule,
    HttpClientModule,
    FormsModule,
    BaseChartDirective
  
    
],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
