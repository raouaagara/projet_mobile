import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { HomeAppComponent } from './home-app/home-app.component';
import { AuthComponent } from './Interfaces_Authentification/auth/auth.component';
import { LoginClientComponent } from './Interfaces_Authentification/login-client/login-client.component';
import { LoginFreelancerComponent } from './Interfaces_Authentification/login-freelancer/login-freelancer.component';
import { RegisterClientComponent } from './Interfaces_Authentification/register-client/register-client.component';
import { RegisterFreelancerComponent } from './Interfaces_Authentification/register-freelancer/register-freelancer.component';
import { ClientFeedComponent } from './Interfaces_Client/client-feed/client-feed.component';
import { ProjectDetailsComponent } from './Interfaces_Freelancers/project-details/project-details.component';
import { ClientDashboardComponent } from './Interfaces_Client/client-dashboard/client-dashboard.component';
import { ProjectProposalsComponent } from './Interfaces_Client/project-proposals/project-proposals.component';
import { AllProjectsComponent } from './Interfaces_Client/all-projects/all-projects.component';
import { ClientProfileComponent } from './Interfaces_Client/client-profile/client-profile.component';
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
import { TechnicalSupportComponent } from './interface_communication/technical-support/technical-support.component';
import { MessengerComponent } from './interface_communication/messenger/messenger.component';
import { DashboardAdminComponent } from './Interfaces_Admin/dashboard-admin/dashboard-admin.component';
import { UserAdminComponent } from './Interfaces_Admin/user-admin/user-admin.component';
import { JobsAdminComponent } from './Interfaces_Admin/jobs-admin/jobs-admin.component';
import { DetailJobsAdminComponent } from './Interfaces_Admin/detail-jobs-admin/detail-jobs-admin.component';
import { DisputesAdminComponent } from './Interfaces_Admin/disputes-admin/disputes-admin.component';
import { FinanceAdminComponent } from './Interfaces_Admin/finance-admin/finance-admin.component';
import { CompetenceAdminComponent } from './Interfaces_Admin/competence-admin/competence-admin.component';
import { ContractCreationComponent } from './Interfaces_Client/contract-creation/contract-creation.component';
import { ClientContractComponent } from './Interfaces_Client/client-contract/client-contract.component';
import { ClientContractDetailsComponent } from './Interfaces_Client/client-contract-details/client-contract-details.component';
import { FreelancerContractsComponent } from './Interfaces_Freelancers/freelancer-contracts/freelancer-contracts.component';
import { FreelancerContractReviewComponent } from './Interfaces_Freelancers/freelancer-contract-review/freelancer-contract-review.component';
import { FreelancerContractDetailsComponent } from './Interfaces_Freelancers/freelancer-contract-details/freelancer-contract-details.component';
import { authGuard } from './Interfaces_Authentification/Guards/auth.guard';
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

import { GroupListComponent } from './interfaces_events/group-list/group-list.component';
import { GroupPageComponent } from './interfaces_events/group-page/group-page.component';
import { AdminDashboardComponent } from './interfaces_events/admin-dashboard/admin-dashboard.component';
import { EventsListComponent } from './interfaces_events/events-list/events-list.component';
import { EventDetailsComponent } from './interfaces_events/event-details/event-details.component';
import { ClubComponent } from './interfaces_events/club/club.component';
import { ClubDashboardComponent } from './interfaces_events/club-dashboard/club-dashboard.component';
import { ClubsListComponent } from './interfaces_events/clubs-list/clubs-list.component';
import { AdminFinanceComponent } from './Interfaces_Admin/admin-finance/admin-finance.component';
import { AdminSupportComponent } from './Interfaces_Admin/admin-support/admin-support.component';

const routes: Routes = [



  {path:'',component: HomeAppComponent, },
  {path:'Workspace',component: WorkspaceComponent, },


//Authentification routes
  {path:'Auth',component: AuthComponent, },
  {path:'LoginClient',component: LoginClientComponent, },
  {path:'LoginFreelancer',component: LoginFreelancerComponent, },
  {path:'RegisterClient',component: RegisterClientComponent, },
  {path:'RegisterFreelancer',component: RegisterFreelancerComponent, },

//client routes
 {path:'ClientFeed',component: ClientFeedComponent, canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ClientDashboard',component:ClientDashboardComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ProjectProposals/:id',component:ProjectProposalsComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'AllProjects',component:AllProjectsComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ClientProfil/:id',component:ClientProfileComponent,  },
 {path:'ClientProfil',component:ClientProfileComponent,  },
 {path:'VirtualContract',component:VirtualContractComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ClientDetailProject/:id',component:DetailclientprojectComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ClientProfileManager',component:ClientProfilManagerComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ClientWallet',component:ClientWalletComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ClientCreateContract/:proposalId',component:ContractCreationComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ClientContracts', component: ClientContractComponent , canActivate: [authGuard], data: { role: 'CLIENT' } },
 {path:'ClientContracts/:id', component: ClientContractDetailsComponent,  canActivate: [authGuard], data: { role: 'CLIENT' } },

 //Freelancer routes
{path:'FreelancerContractDetails/:id',component:FreelancerContractDetailsComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerContractReview/:id',component:FreelancerContractReviewComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerContracts',component:FreelancerContractsComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'ProjectDetails/:id',component:ProjectDetailsComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerDashboard',component:DashboardFreelancerComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerProfileManager',component:ProfileManagerComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerFeed',component:FreelancerFeedComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerJobs',component:FreelancerJobsComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerProfil/:id',component:FreelancerProfilComponent}, 
{path:'FreelancerProfil',component:FreelancerProfilComponent}, 

{path:'LeaderboardFreelancer',component:LeaderboardFreelancerComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerWallet',component:FreelancerWalletComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'FreelancerOnboarding',component:OnboardingComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},


 //Communication routes
{path:'TechnicalSupport',component:TechnicalSupportComponent, },
{path:'Messenger',component:MessengerComponent, },
{path:'Messages',component:MessagesComponent, },


//Admin routes
{path:'AdminDashboard',component:DashboardAdminComponent, },
{path:'AdminUsers',component:UserAdminComponent, },
{path:'AdminJobs',component:JobsAdminComponent, },
{path:'DetailJobs/:id',component:DetailJobsAdminComponent, },
{path:'AdminDisputes',component:DisputesAdminComponent, },
{path:'AdminFinancee',component:FinanceAdminComponent, },
{path:'AdminSkills',component:CompetenceAdminComponent, },
{path:'AdminFinance',component:AdminFinanceComponent, },
{path:'AdminSupport',component:AdminSupportComponent, },

//Subscription routes (Module 3 - Freelancer)
{path:'SubscriptionPlans',component:SubscriptionPlansComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'SubscriptionDetail/:id',component:SubscriptionDetailComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'SubscriptionCheckout/:id',component:SubscriptionCheckoutComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'SubscriptionDashboard',component:SubscriptionDashboardComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'PlanComparator',component:PlanComparatorComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},

// Admin back-office (Protected by AdminGuard)
{path:'AdminSubscriptions',component:AdminSubscriptionsComponent, },
{path:'AdminCertifications',component:AdminCertificationsComponent, },
{path:'AdminSkillTests',component:AdminSkillTestsComponent,  },
{path:'AdminStatistics',component:AdminStatisticsComponent,  },
{path:'AdminPromoCodes',component:AdminPromoCodesComponent,  },
{path:'AdminPlans',component:AdminPlansComponent,  },

// Skill Tests & Certifications
{path:'SkillTests',component:SkillTestsListComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'SkillTestTake/:id',component:SkillTestTakeComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'SkillTestResult/:id',component:SkillTestResultComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'MyCertifications',component:MyCertificationsComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},

// Referral & Affiliate Program
{path:'ReferralDashboard',component:ReferralDashboardComponent,canActivate: [authGuard], data: { role: 'FREELANCER' } },

// Time Zone & Availability (Freelancer + Client)
{path:'MyAvailability',component:MyAvailabilityComponent, canActivate: [authGuard], data: { role: 'FREELANCER' } },
{path:'WorldClock',component:WorldClockViewComponent, canActivate: [authGuard], data: { role: 'CLIENT' }},
{path:'worldclock',redirectTo:'WorldClock', pathMatch:'full' },

// AI CV Generator (Premium/Enterprise only)
{path:'AICVGenerator',component:AiCvGeneratorComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},

// Rewards & Promo Codes
{path:'rewards',component:RewardsDashboardComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},
{path:'rewards/spin-wheel',component:SpinWheelComponent, canActivate: [authGuard], data: { role: 'FREELANCER' }},


// Events & Communities routes

{ path: 'groups', component: GroupListComponent },
{ path: 'groups/:id', component: GroupPageComponent },
{ path: 'events', component: EventsListComponent },
{ path: 'events/:id', component: EventDetailsComponent },
{ path: 'clubs', component: ClubsListComponent },
{ path: 'clubs/:id', component: ClubComponent },
{ path: 'ClubDashboard', component: ClubDashboardComponent },
{ path: 'admin/dashboard', component: AdminDashboardComponent }




   
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
