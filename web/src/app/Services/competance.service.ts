import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Competance } from '../models/Competance';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class CompetanceService {

    constructor(private http:HttpClient) { }  
    private url ='http://localhost:8085/Competance'

parseCv(file: File): Observable<Competance[]> {
  const formData: FormData = new FormData();
  formData.append('file', file);
  
  // On envoie le fichier au nouveau endpoint qu'on a créé
  return this.http.post<Competance[]>(`${this.url}/ParseCV`, formData);
}

    getAllCompetances(): Observable<Competance[]> {
    return this.http.get<Competance[]>(`${this.url}/GetAllCompetance`);
  }

  addCompetance(competance: Competance): Observable<Competance> {
    return this.http.post<Competance>(`${this.url}/AjouterCompetance`, competance);
  }

  updateCompetance(competance: Competance): Observable<Competance> {
    return this.http.put<Competance>(`${this.url}/ModifierCompetance`, competance);
  }

  deleteCompetance(id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/SupprimerCompetance/${id}`);
  }
}


