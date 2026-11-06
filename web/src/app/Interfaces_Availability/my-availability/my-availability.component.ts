import { Component, OnInit } from '@angular/core';
import { AvailabilityService, AvailabilityProfile, AvailableSlot, AvailabilityStatus } from '../../services-ayoub/availability.service';
import { UserService } from '../../services-ayoub/user.service';

const DAYS = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'] as const;
const COMMON_TIMEZONES = [
  { id: 'Europe/Paris', label: 'Paris (UTC+1/+2)' },
  { id: 'Europe/London', label: 'London (UTC+0/+1)' },
  { id: 'America/New_York', label: 'New York (UTC-5/-4)' },
  { id: 'America/Los_Angeles', label: 'Los Angeles (UTC-8/-7)' },
  { id: 'Asia/Tokyo', label: 'Tokyo (UTC+9)' },
  { id: 'Asia/Dubai', label: 'Dubai (UTC+4)' },
  { id: 'Australia/Sydney', label: 'Sydney (UTC+10/+11)' },
  { id: 'Africa/Cairo', label: 'Cairo (UTC+2)' },
  { id: 'UTC', label: 'UTC' },
];

@Component({
  selector: 'app-my-availability',
  templateUrl: './my-availability.component.html',
  styleUrl: './my-availability.component.css'
})
export class MyAvailabilityComponent implements OnInit {
  userId: number | null = null;
  profile: AvailabilityProfile | null = null;
  slots: AvailableSlot[] = [];
  loading = true;
  saving = false;
  message = '';

  timezone = '';
  status: AvailabilityStatus = 'OFFLINE';
  customMessage = '';

  statusOptions: { value: AvailabilityStatus; label: string; icon: string; color: string }[] = [
    { value: 'ONLINE', label: 'En ligne', icon: 'fa-circle', color: 'online' },
    { value: 'AVAILABLE', label: 'Disponible', icon: 'fa-check-circle', color: 'available' },
    { value: 'AVAILABLE_TOMORROW', label: 'Disponible demain', icon: 'fa-sun', color: 'tomorrow' },
    { value: 'OFFLINE', label: 'Hors ligne', icon: 'fa-moon', color: 'offline' },
    { value: 'DO_NOT_DISTURB', label: 'Ne pas déranger', icon: 'fa-bell-slash', color: 'dnd' },
    { value: 'CUSTOM', label: 'Personnalisé', icon: 'fa-pen', color: 'custom' },
  ];

  timezoneOptions = COMMON_TIMEZONES;
  days = DAYS;

  newSlot: Partial<AvailableSlot> = { dayOfWeek: 'MONDAY', startTime: '09:00', endTime: '17:00' };

  constructor(
    private availabilityService: AvailabilityService,
    private userService: UserService
  ) {}

  ngOnInit(): void {
    this.timezone = this.availabilityService.getBrowserTimezone();
    
    // Get current logged-in user
    const currentUser = this.userService.getCurrentUser();
    console.log('🔍 DEBUG Availability: Current user from service:', currentUser);
    console.log('🔍 DEBUG Availability: JWT token exists:', !!this.userService.getToken());
    
    if (currentUser?.id) {
      this.userId = currentUser.id;
      console.log('✅ DEBUG Availability: Using userId:', this.userId);
      this.load();
    } else {
      // Try to get user from token if exists
      const token = this.userService.getToken();
      if (token) {
        try {
          const payload = JSON.parse(atob(token.split('.')[1]));
          this.userId = payload.id;
          console.log('✅ DEBUG Availability: Extracted userId from token:', this.userId);
          this.load();
        } catch (error) {
          console.error('❌ DEBUG Availability: Failed to parse token:', error);
          this.loading = false;
          alert('Please login to manage your availability');
        }
      } else {
        console.log('❌ DEBUG Availability: No token found, user not logged in');
        this.loading = false;
        alert('Please login to manage your availability');
      }
    }
  }

  load(): void {
    if (!this.userId) return;
    
    this.loading = true;
    this.availabilityService.getOrCreateProfile(this.userId, this.timezone).subscribe((p) => {
      this.profile = p;
      if (p) {
        this.timezone = p.timezone || this.timezone;
        this.status = p.status || 'OFFLINE';
        this.customMessage = p.customStatusMessage || '';
        this.loadSlots();
      }
      this.loading = false;
    });
  }

  loadSlots(): void {
    if (!this.profile?.id) return;
    this.availabilityService.getSlots(this.profile.id).subscribe((s) => (this.slots = s || []));
  }

  saveProfile(): void {
    console.log('🔍 DEBUG: saveProfile called');
    console.log('🔍 DEBUG: profile:', this.profile);
    console.log('🔍 DEBUG: userId:', this.userId);
    console.log('🔍 DEBUG: timezone:', this.timezone);
    console.log('🔍 DEBUG: status:', this.status);
    
    if (!this.profile || !this.userId) {
      console.error('❌ DEBUG: Cannot save - profile or userId is null');
      this.message = 'Erreur: Profil non chargé';
      return;
    }
    
    this.saving = true;
    this.message = '';
    
    const updateData = {
      timezone: this.timezone,
      status: this.status,
      customStatusMessage: this.status === 'CUSTOM' ? this.customMessage : undefined,
    };
    
    console.log('🔍 DEBUG: Updating profile with data:', updateData);
    
    this.availabilityService.updateProfile(this.profile.id!, updateData).subscribe({
      next: (p) => {
        console.log('✅ DEBUG: Profile updated successfully:', p);
        this.profile = p;
        this.saving = false;
        this.message = 'Profil mis à jour.';
        this.setHeartbeat();
      },
      error: (err) => {
        console.error('❌ DEBUG: Error updating profile:', err);
        this.saving = false;
        this.message = 'Erreur lors de la sauvegarde: ' + (err.error?.message || err.message);
      },
    });
  }

  setHeartbeat(): void {
    if (!this.userId) return;
    this.availabilityService.updateHeartbeat(this.userId).subscribe();
  }

  addSlot(): void {
    if (!this.profile?.id || !this.newSlot.dayOfWeek || !this.newSlot.startTime || !this.newSlot.endTime) return;
    this.availabilityService.addSlot(this.profile.id, this.newSlot as AvailableSlot).subscribe({
      next: () => {
        this.loadSlots();
        this.newSlot = { dayOfWeek: 'MONDAY', startTime: '09:00', endTime: '17:00' };
        this.message = 'Créneau ajouté.';
      },
      error: () => (this.message = 'Erreur.'),
    });
  }

  removeSlot(slot: AvailableSlot): void {
    if (!slot.id) return;
    this.availabilityService.deleteSlot(slot.id).subscribe(() => this.loadSlots());
  }

  formatSlot(slot: AvailableSlot): string {
    const day = slot.dayOfWeek?.slice(0, 2) || '';
    return `${day} ${slot.startTime} - ${slot.endTime}`;
  }

  getLocalTime(): string {
    try {
      return new Date().toLocaleTimeString('fr-FR', { timeZone: this.timezone || 'UTC', hour: '2-digit', minute: '2-digit' });
    } catch {
      return '--';
    }
  }

  getBarLeft(slot: AvailableSlot): number {
    const [h, m] = (slot.startTime || '00:00').split(':').map(Number);
    return (h * 60 + m) / 1440 * 100;
  }

  getBarWidth(slot: AvailableSlot): number {
    const [sh, sm] = (slot.startTime || '00:00').split(':').map(Number);
    const [eh, em] = (slot.endTime || '24:00').split(':').map(Number);
    const mins = (eh * 60 + em) - (sh * 60 + sm);
    return Math.max(5, (mins / 1440) * 100);
  }
}
