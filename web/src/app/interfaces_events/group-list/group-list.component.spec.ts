import { Component } from '@angular/core';

@Component({
  selector: 'app-group-list',
  templateUrl: './group-list.component.html',
  styleUrls: ['./group-list.component.css']
})
export class GroupListComponent {
filterGroups() {
throw new Error('Method not implemented.');
}
navigateToEvents() {
throw new Error('Method not implemented.');
}
handleNotificationClick(_t35: any) {
throw new Error('Method not implemented.');
}
onGroupTypeChange($event: Event) {
throw new Error('Method not implemented.');
}
toggleShowAllGroups() {
throw new Error('Method not implemented.');
}
viewGroup(arg0: any) {
throw new Error('Method not implemented.');
}
joinGroup(_t76: any,$event: PointerEvent) {
throw new Error('Method not implemented.');
}
previousMonth() {
throw new Error('Method not implemented.');
}
nextMonth() {
throw new Error('Method not implemented.');
}
  groups = [
    { id: 1, name: 'Développeurs Web', description: 'Un groupe pour les passionnés du web.' },
    { id: 2, name: 'Designers', description: 'Un groupe pour les créatifs.' }
  ];
searchTerm: any;
notificationService: any;
selectedGroupType: any;
showAllGroups: any;
currentMonth: any;

  // ✅ Correction : ajouter la méthode
  createGroup() {
    console.log('Créer un groupe');
  }

  openGroup(id: number) {
    console.log('Ouvrir le groupe avec ID:', id);
  }
}
