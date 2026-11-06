export interface User {
  id?: number;
  firstName?: string;
  lastName?: string;
  email: string;
  password?: string;
  role?: 'FREELANCER' | 'CLIENT' | 'ADMIN';
  location?: string;
  bio?: string;
  profilePictureUrl?: string;
  coverPictureUrl?: string; 
  website?: string;
  linkedinUrl?: string;
  
}