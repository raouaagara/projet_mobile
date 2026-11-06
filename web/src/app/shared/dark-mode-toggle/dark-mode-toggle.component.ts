import { Component, OnInit } from '@angular/core';
import { ThemeService } from '../../services-ayoub/theme.service';

@Component({
  selector: 'app-dark-mode-toggle',
  template: `
    <button class="toggle-btn" (click)="theme.toggle()" [title]="theme.isDark() ? 'Light mode' : 'Dark mode'">
      <i class="fa" [ngClass]="theme.isDark() ? 'fa-sun' : 'fa-moon'"></i>
    </button>
  `,
  styles: [`
    .toggle-btn {
      background: none;
      border: none;
      width: 40px;
      height: 40px;
      border-radius: 8px;
      color: var(--text-muted);
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.1rem;
    }
    .toggle-btn:hover { color: var(--primary); background: rgba(16,185,129,0.1); }
  `]
})
export class DarkModeToggleComponent implements OnInit {
  constructor(public theme: ThemeService) {}

  ngOnInit(): void {
    this.theme.init();
  }
}
