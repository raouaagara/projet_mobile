import { Component, OnInit } from '@angular/core';
import { Project } from '../../models/project.model';
import { ProjectServiceService } from '../../Services/project-service.service';
import { UserService } from '../../Services/user.service';
import { ContractService } from '../../Services/contract.service';
import { Router } from '@angular/router';
import { ChartConfiguration, ChartOptions, ChartType } from 'chart.js';
import { Chart, registerables } from 'chart.js';

// Register all chart components to fix "category is not a registered scale" error
Chart.register(...registerables);

@Component({
  selector: 'app-client-dashboard',
  templateUrl: './client-dashboard.component.html',
  styleUrls: ['./client-dashboard.component.css']
})
export class ClientDashboardComponent implements OnInit {

  currentUser: any = null;
  myProjects: Project[] = [];
  
  // Dashboard Metrics
  totalProjects: number = 0;
  activeContracts: number = 0;
  openRequisitions: number = 0;
  totalSpentClosed: number = 0;

  // Chart Properties
  public lineChartData: ChartConfiguration<'line'>['data'] = {
    labels: [],
    datasets: [
      {
        data: [],
        label: 'Projects Created',
        fill: true,
        tension: 0.4,
        borderColor: '#198754',
        backgroundColor: 'rgba(25, 135, 84, 0.1)',
        pointBackgroundColor: '#198754',
      }
    ]
  };
  public lineChartOptions: ChartOptions<'line'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false }
    },
    scales: {
      x: { grid: { display: false } },
      y: { grid: { color: '#f3f4f6' }, beginAtZero: true, ticks: { stepSize: 1 } }
    }
  };
  public lineChartLegend = false;

  constructor(
    private projectService: ProjectServiceService,
    private userService: UserService,
    private contractService: ContractService,
    private router: Router
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
          const currentUserId = decodedPayload.id;

          if (currentUserId) {
            this.userService.getUserById(currentUserId).subscribe({
              next: (user) => {
                this.currentUser = user;
                this.loadMyProjects(user.id);
              },
              error: (err) => console.error("Erreur Backend Profil :", err)
            });
          }
        }
      } catch (e) {
        console.error("Erreur de décodage du token :", e);
      }
    }
  }

  loadMyProjects(clientId: number) {
    this.projectService.getAllProjects().subscribe({
      next: (data) => {
        // Filter ONLY projects belonging to this client
        this.myProjects = data.filter(p => p.clientId === clientId).reverse();
        this.calculateMetrics();
        this.generateChartData();
      },
      error: (err) => console.error("Failed to load projects", err)
    });
  }

  // Pagination
  currentPage: number = 1;
  itemsPerPage: number = 5;

  get paginatedProjects(): Project[] {
    const startIndex = (this.currentPage - 1) * this.itemsPerPage;
    return this.myProjects.slice(startIndex, startIndex + this.itemsPerPage);
  }

  get totalPages(): number {
    return Math.ceil(this.myProjects.length / this.itemsPerPage);
  }

  nextPage() {
    if (this.currentPage < this.totalPages) this.currentPage++;
  }

  prevPage() {
    if (this.currentPage > 1) this.currentPage--;
  }

  calculateMetrics() {
    this.totalProjects = this.myProjects.length;
    
    // Count open requisitions (OPEN)
    this.openRequisitions = this.myProjects.filter(p => p.status === 'OPEN').length;
    
    // Calculate Total Spent (ONLY CLOSED PROJECTS)
    this.totalSpentClosed = this.myProjects
      .filter(p => p.status === 'CLOSED')
      .reduce((sum, p) => sum + (p.budget || 0), 0);

    // Fetch contracts for this client to get "Active Contracts" count
    if (this.currentUser && this.currentUser.id) {
      this.contractService.getClientContracts(this.currentUser.id).subscribe({
        next: (contracts) => {
          // Strictly match only active states to avoid counting COMPLETED or TERMINATED contracts
          this.activeContracts = contracts.filter(c => 
            c.status === 'ACTIVE' || 
            c.status === 'IN_PROGRESS' || 
            c.status === 'SIGNED' ||
            c.status === 'PENDING'
          ).length;
        },
        error: (err) => console.error("Failed to load contracts", err)
      });
    }
  }

  generateChartData() {
    // Group projects by month (last 6 months)
    const monthCounts: { [key: string]: number } = {};
    const monthLabels: string[] = [];
    
    // Initialize last 6 months
    for (let i = 5; i >= 0; i--) {
      const d = new Date();
      d.setMonth(d.getMonth() - i);
      const monthName = d.toLocaleString('en-US', { month: 'short' });
      monthLabels.push(monthName);
      monthCounts[monthName] = 0;
    }

    this.myProjects.forEach(p => {
      if (p.postedAt) {
        // postedAt is usually ISO string or format '2023-10-05T...'
        const d = new Date(p.postedAt);
        const monthName = d.toLocaleString('en-US', { month: 'short' });
        if (monthCounts[monthName] !== undefined) {
          monthCounts[monthName]++;
        }
      }
    });

    const dataArray = monthLabels.map(month => monthCounts[month]);

    this.lineChartData = {
      labels: monthLabels,
      datasets: [
        {
          data: dataArray,
          label: 'Projects Created',
          fill: true,
          tension: 0.4,
          borderColor: '#198754',
          backgroundColor: 'rgba(25, 135, 84, 0.1)',
          pointBackgroundColor: '#198754',
        }
      ]
    };
  }

  formatEnumText(text: string | undefined): string {
    if (!text) return 'N/A';
    return text.replace(/_/g, ' ');
  }
}
