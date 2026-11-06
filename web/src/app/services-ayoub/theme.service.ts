import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  private readonly STORAGE_KEY = 'catchopp-theme';

  isDark(): boolean {
    const saved = localStorage.getItem(this.STORAGE_KEY);
    if (saved) return saved === 'dark';
    return window.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false;
  }

  setDark(dark: boolean): void {
    localStorage.setItem(this.STORAGE_KEY, dark ? 'dark' : 'light');
    this.apply();
  }

  toggle(): void {
    this.setDark(!this.isDark());
  }

  apply(): void {
    document.documentElement.classList.toggle('dark-theme', this.isDark());
  }

  init(): void {
    this.apply();
  }
}
