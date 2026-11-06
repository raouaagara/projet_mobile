import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Project } from '../models/project.model';

@Injectable({
  providedIn: 'root'
})
export class ProjectServiceService {

    constructor(private http:HttpClient) { }  
  private url ='http://localhost:8085/Project'
 

  addProject(project: Project): Observable<Project> {
    return this.http.post<Project>(`${this.url}/newproject`, project);
  }
  getAllProjects(): Observable<Project[]> {
    return this.http.get<Project[]>(`${this.url}/allprojects`);
  }
  deleteProject(id: number): Observable<any> {
    return this.http.delete(`${this.url}/delete/${id}`);
  }

  updateProjectStatus(id: number, status: string): Observable<Project> {
    
    return this.http.put<Project>(`${this.url}/${id}/status?status=${status}`, {});
  }

  updateProject(id: number, project: Project): Observable<Project> {
    return this.http.put<Project>(`${this.url}/update/${id}`, project);
  }
  reactToProject(projectId: number, reactionType: string): Observable<Project> {
    return this.http.put<Project>(`${this.url}/${projectId}/react?type=${reactionType}`, {});
  }
  getProjectById(id: number): Observable<Project> {
    return this.http.get<Project>(`${this.url}/${id}`);
  }
  
  getProposalsForProject(projectId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.url}/${projectId}/proposals`);
  }

 
  submitProposal(projectId: number, proposal: any): Observable<any> {
    return this.http.post<any>(`${this.url}/${projectId}/proposals`, proposal);
  }
  updateProposalStatus(proposalId: number, status: string): Observable<any> {
  // Spring Boot attend le status en @RequestParam, donc on utilise HttpParams
  const params = new HttpParams().set('status', status);
  return this.http.put<any>(`${this.url}/proposals/${proposalId}/status`, {}, { params });
}
}

