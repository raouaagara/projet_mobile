import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BaseChartDirective } from 'ng2-charts'; 
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { HomeAppComponent } from './home-app/home-app.component';
import { CreatePubComponent } from './Interfaces_Client/create-pub/create-pub.component';
import { AuthComponent } from './Interfaces_Authentification/auth/auth.component';
import { LoginFreelancerComponent } from './Interfaces_Authentification/login-freelancer/login-freelancer.component';
import { LoginClientComponent } from './Interfaces_Authentification/login-client/login-client.component';
import { RegisterFreelancerComponent } from './Interfaces_Authentification/register-freelancer/register-freelancer.component';
import { RegisterClientComponent } from './Interfaces_Authentification/register-client/register-client.component';
import { ClientFeedComponent } from './Interfaces_Client/client-feed/client-feed.component';
import { ProjectDetailsComponent } from './Interfaces_Freelancers/project-details/project-details.component';
import { ClientDashboardComponent } from './Interfaces_Client/client-dashboard/client-dashboard.component';
import { ProjectProposalsComponent } from './Interfaces_Client/project-proposals/project-proposals.component';
import { AllProjectsComponent } from './Interfaces_Client/all-projects/all-projects.component';
import { ClientProfileComponent } from './Interfaces_Client/client-profile/client-profile.component';
import { CommonModule } from '@angular/common';
import { VirtualContractComponent } from './Interfaces_Client/virtual-contract/virtual-contract.component';
import { FreelancerFeedComponent } from './Interfaces_Freelancers/freelancer-feed/freelancer-feed.component';
import { FreelancerJobsComponent } from './Interfaces_Freelancers/freelancer-jobs/freelancer-jobs.component';
import { FreelancerProfilComponent } from './Interfaces_Freelancers/freelancer-profil/freelancer-profil.component';
import { DetailclientprojectComponent } from './Interfaces_Client/detailclientproject/detailclientproject.component';
import { ProfileManagerComponent } from './Interfaces_Freelancers/profile-manager/profile-manager.component';
import { LeaderboardFreelancerComponent } from './Interfaces_Freelancers/leaderboard-freelancer/leaderboard-freelancer.component';
import { ClientWalletComponent } from './Interfaces_Client/client-wallet/client-wallet.component';
import { ClientProfilManagerComponent } from './Interfaces_Client/client-profil-manager/client-profil-manager.component';
import { DashboardFreelancerComponent } from './Interfaces_Freelancers/dashboard-freelancer/dashboard-freelancer.component';
import { FreelancerWalletComponent } from './Interfaces_Freelancers/freelancer-wallet/freelancer-wallet.component';
import { MessengerComponent } from './interface_communication/messenger/messenger.component';
import { TechnicalSupportComponent } from './interface_communication/technical-support/technical-support.component';
import { DashboardAdminComponent } from './Interfaces_Admin/dashboard-admin/dashboard-admin.component';
import { UserAdminComponent } from './Interfaces_Admin/user-admin/user-admin.component';
import { JobsAdminComponent } from './Interfaces_Admin/jobs-admin/jobs-admin.component';
import { DetailJobsAdminComponent } from './Interfaces_Admin/detail-jobs-admin/detail-jobs-admin.component';
import { DisputesAdminComponent } from './Interfaces_Admin/disputes-admin/disputes-admin.component';
import { FinanceAdminComponent } from './Interfaces_Admin/finance-admin/finance-admin.component';
import { HttpClientModule } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { CompetenceAdminComponent } from './Interfaces_Admin/competence-admin/competence-admin.component';
import { ContractCreationComponent } from './Interfaces_Client/contract-creation/contract-creation.component';
import { ClientContractComponent } from './Interfaces_Client/client-contract/client-contract.component';
import { ClientContractDetailsComponent } from './Interfaces_Client/client-contract-details/client-contract-details.component';
import { FreelancerContractsComponent } from './Interfaces_Freelancers/freelancer-contracts/freelancer-contracts.component';
import { FreelancerContractReviewComponent } from './Interfaces_Freelancers/freelancer-contract-review/freelancer-contract-review.component';
import { FreelancerContractDetailsComponent } from './Interfaces_Freelancers/freelancer-contract-details/freelancer-contract-details.component';
import { WorkspaceComponent } from './workspace/workspace.component';
import { OnboardingComponent } from './Interfaces_Freelancers/onboarding/onboarding.component';
import { MessagesComponent } from './interface_communication/messages/messages.component';
import { SubscriptionPlansComponent } from './Interfaces_Subscription/subscription-plans/subscription-plans.component';
import { SubscriptionDetailComponent } from './Interfaces_Subscription/subscription-detail/subscription-detail.component';
import { SubscriptionCheckoutComponent } from './Interfaces_Subscription/subscription-checkout/subscription-checkout.component';
import { SubscriptionDashboardComponent } from './Interfaces_Subscription/subscription-dashboard/subscription-dashboard.component';
import { AdminSubscriptionsComponent } from './Interfaces_Admin/admin-subscriptions/admin-subscriptions.component';
import { AdminCertificationsComponent } from './Interfaces_Admin/admin-certifications/admin-certifications.component';
import { AdminStatisticsComponent } from './Interfaces_Admin/admin-statistics/admin-statistics.component';
import { AdminPromoCodesComponent } from './Interfaces_Admin/admin-promo-codes/admin-promo-codes.component';
import { PlanComparatorComponent } from './Interfaces_Subscription/plan-comparator/plan-comparator.component';
import { SkillTestsListComponent } from './Interfaces_SkillTests/skill-tests-list/skill-tests-list.component';
import { SkillTestTakeComponent } from './Interfaces_SkillTests/skill-test-take/skill-test-take.component';
import { SkillTestResultComponent } from './Interfaces_SkillTests/skill-test-result/skill-test-result.component';
import { MyCertificationsComponent } from './Interfaces_SkillTests/my-certifications/my-certifications.component';
import { ReferralDashboardComponent } from './Interfaces_Referral/referral-dashboard/referral-dashboard.component';
import { MyAvailabilityComponent } from './Interfaces_Availability/my-availability/my-availability.component';
import { WorldClockViewComponent } from './Interfaces_Availability/world-clock-view/world-clock-view.component';
import { AdminPlansComponent } from './Interfaces_Admin/admin-plans/admin-plans.component';
import { AdminSkillTestsComponent } from './Interfaces_Admin/admin-skill-tests/admin-skill-tests.component';
import { AiCvGeneratorComponent } from './Interfaces_AI/ai-cv-generator/ai-cv-generator.component';
import { RewardsDashboardComponent } from './Interfaces_Rewards/rewards-dashboard/rewards-dashboard.component';
import { SpinWheelComponent } from './Interfaces_Rewards/spin-wheel/spin-wheel.component';
import { NotificationCenterComponent } from './shared/notification-center/notification-center.component';
import { DarkModeToggleComponent } from './shared/dark-mode-toggle/dark-mode-toggle.component';
import { GroupListComponent } from './interfaces_events/group-list/group-list.component';
import { GroupPageComponent } from './interfaces_events/group-page/group-page.component';
import { EventsListComponent } from './interfaces_events/events-list/events-list.component';
import { ClubComponent } from './interfaces_events/club/club.component';
import { ClubDashboardComponent } from './interfaces_events/club-dashboard/club-dashboard.component';
import { ClubsListComponent } from './interfaces_events/clubs-list/clubs-list.component';
import { PostReactionsComponent } from './interfaces_events/post-reactions/post-reactions.component';
import { PostCommentsComponent } from './interfaces_events/post-comments/post-comments.component';
import { CommentReactionsComponent } from './interfaces_events/comment-reactions/comment-reactions.component';
import { NotificationBellComponent } from './interfaces_events/notification-bell/notification-bell.component';
import { NotificationToastComponent } from './interfaces_events/notification-toast/notification-toast.component';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { EventDetailsComponent } from './interfaces_events/event-details/event-details.component';
import { ClubPageComponent } from './interfaces_events/club-page/club-page.component';
import { AdminDashboardComponent } from './interfaces_events/admin-dashboard/admin-dashboard.component';
import { ClubService } from './interfaces_events';
import { AdminFinanceComponent } from './Interfaces_Admin/admin-finance/admin-finance.component';
import { AdminSupportComponent } from './Interfaces_Admin/admin-support/admin-support.component';

@NgModule({
  declarations: [
    AppComponent,
    HomeAppComponent,
    CreatePubComponent,
    AuthComponent,
    LoginFreelancerComponent,
    LoginClientComponent,
    RegisterFreelancerComponent,
    RegisterClientComponent,
    ClientFeedComponent,
    ProjectDetailsComponent,
    ClientDashboardComponent,
    ProjectProposalsComponent,
    AllProjectsComponent,
    
  
    ClientProfileComponent,
        VirtualContractComponent,
        FreelancerFeedComponent,
        FreelancerJobsComponent,
        FreelancerProfilComponent,
        DetailclientprojectComponent,
        ProfileManagerComponent,
        LeaderboardFreelancerComponent,
        ClientWalletComponent,
        ClientProfilManagerComponent,
        DashboardFreelancerComponent,
        FreelancerWalletComponent,
        MessengerComponent,
      
        DashboardAdminComponent,
        UserAdminComponent,
        JobsAdminComponent,
        DetailJobsAdminComponent,
        DisputesAdminComponent,
        FinanceAdminComponent,
        CompetenceAdminComponent,
        ContractCreationComponent,
        ClientContractComponent,
        ClientContractDetailsComponent,
        FreelancerContractsComponent,
        FreelancerContractReviewComponent,
        FreelancerContractDetailsComponent,
        WorkspaceComponent,
        OnboardingComponent,
        MessagesComponent,
        TechnicalSupportComponent,
        AdminSupportComponent,

         SubscriptionPlansComponent,
         SubscriptionDashboardComponent,
         SubscriptionPlansComponent,
        SubscriptionDetailComponent,
        SubscriptionCheckoutComponent,
        AdminSubscriptionsComponent,
        AdminCertificationsComponent,
        AdminStatisticsComponent,
        AdminPromoCodesComponent,
        PlanComparatorComponent,
        NotificationCenterComponent,
        DarkModeToggleComponent,
        SkillTestsListComponent,
        SkillTestTakeComponent,
        SkillTestResultComponent,
        MyCertificationsComponent,
        ReferralDashboardComponent,
        MyAvailabilityComponent,
        WorldClockViewComponent,
        AdminPlansComponent,
        AdminSkillTestsComponent,
        AiCvGeneratorComponent,
        RewardsDashboardComponent,
        SpinWheelComponent,

        GroupListComponent,
        GroupPageComponent,
        AdminDashboardComponent,
        EventsListComponent,
        ClubComponent,
        ClubDashboardComponent,
        ClubsListComponent,
        PostReactionsComponent,
        PostCommentsComponent,
        CommentReactionsComponent,
        NotificationBellComponent,
        NotificationToastComponent,
        EventDetailsComponent,
      
        NotificationCenterComponent,
        NotificationBellComponent,
        NotificationToastComponent,
        AdminDashboardComponent,
        AdminFinanceComponent
        
        
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
