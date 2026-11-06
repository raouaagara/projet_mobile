
export interface Contract {
  id?: number;
  projectId: number;
  freelancerId: number;
  clientId: number;
  
  projectTitle: string;
  freelancerName: string;
  clientName: string;
  
  rate: number;
  startDate: string; 
  deadline: string;
  
  status: string; 
  terms: string;
  createdAt?: string;
  clientSignature?: string;
  freelancerSignature?: string;
}