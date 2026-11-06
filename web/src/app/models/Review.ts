export interface Review {
    id?: number;
    description: string;
    rating: number;
    createdAt?: string;
    
   
    clientId?: string;
    freelancerId?: string;
    reviewerRole?: 'CLIENT' | 'FREELANCER'; 
    

    reviewerName?: string; 
}