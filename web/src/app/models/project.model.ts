// project.model.ts
export interface Project {
  id?: number;
  title: string;
  description: string;
  image?: string;
  ExperienceLevel?: string; 
  budget: number;
  postedAt: string;
  status: string;
  clientId: number;
  likes?: number;
  loves?: number;
  hahas?: number;
  supports?: number;
  myReaction?: string;
  justReacted?: boolean;
  category?: string; 
  jobType?: string;
  proposals?: any[];
  requiredCompetenceIds?: number[]; 
}