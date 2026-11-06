import { Component, OnInit, OnDestroy } from '@angular/core';
import { AvailabilityService, WorldViewItem } from '../../services-ayoub/availability.service';

@Component({
  selector: 'app-world-clock-view',
  templateUrl: './world-clock-view.component.html',
  styleUrl: './world-clock-view.component.css'
})
export class WorldClockViewComponent implements OnInit, OnDestroy {
  worldData: WorldViewItem[] = [];
  loading = true;
  currentTime = new Date();
  private timer: any;

  constructor(private availabilityService: AvailabilityService) {}

  ngOnInit(): void {
    console.log('🔍 WorldClock: Component initialized');
    this.load();
    this.timer = setInterval(() => {
      this.currentTime = new Date();
    }, 1000);
  }

  ngOnDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  load(): void {
    console.log('🔍 WorldClock: Loading world view data');
    this.loading = true;
    this.availabilityService.getWorldView().subscribe({
      next: (data) => {
        console.log('✅ WorldClock: Data received:', data);
        this.worldData = data || [];
        this.loading = false;
      },
      error: (err) => {
        console.error('❌ WorldClock: Error loading data:', err);
        this.worldData = [];
        this.loading = false;
      }
    });
  }

  getLocalTime(tz: string): string {
    try {
      return this.currentTime.toLocaleTimeString('fr-FR', {
        timeZone: tz || 'UTC',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
      });
    } catch {
      return '--:--:--';
    }
  }

  getStatusLabel(s: string): string {
    const map: Record<string, string> = {
      ONLINE: 'En ligne',
      AVAILABLE: 'Disponible',
      AVAILABLE_TOMORROW: 'Disponible demain',
      OFFLINE: 'Hors ligne',
      DO_NOT_DISTURB: 'Ne pas déranger',
      CUSTOM: 'Personnalisé',
    };
    return map[s] || s;
  }

  getStatusClass(s: string): string {
    return (s || '').toLowerCase().replace('_', '-');
  }

  getTzCity(tz: string): string {
    const parts = tz.split('/');
    return parts[parts.length - 1]?.replace(/_/g, ' ') || tz;
  }
}
