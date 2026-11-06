import { Component } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { NotificationService } from '../notification.service';

interface ClubMember {
  name: string;
  role: string;
  avatar: string;
  status: 'online' | 'offline';
}

interface ClubDetails {
  id: number;
  name: string;
  description: string;
  parentGroup: string;
  focus: string[];
  membersCount: number;
  members: ClubMember[];
}

interface ClubActivity {
  id: number;
  author: string;
  avatar: string;
  createdAt: string;
  type: 'discussion' | 'activity';
  content: string;
}


export class ClubPageComponent {
  club!: ClubDetails;
  currentUser: ClubMember | undefined;
  activities: ClubActivity[] = [];
  newMessage = '';

  private mockClubs: ClubDetails[] = [
    {
      id: 1,
      name: 'Frontend Club',
      description: 'Hands-on workshops around Angular, React and UI best practices.',
      parentGroup: 'Web Developers',
      focus: ['Angular', 'React', 'UI'],
      membersCount: 24,
      members: [
        { name: 'Amine Ben Salah', role: 'Club Admin', avatar: 'https://i.pravatar.cc/150?u=club1', status: 'online' },
        { name: 'Nour UI', role: 'Member', avatar: 'https://i.pravatar.cc/150?u=club2', status: 'online' },
        { name: 'Youssef Dev', role: 'Member', avatar: 'https://i.pravatar.cc/150?u=club3', status: 'offline' }
      ]
    },
    {
      id: 2,
      name: 'UX Critique Club',
      description: 'Weekly sessions to review mockups and prototypes.',
      parentGroup: 'Designers',
      focus: ['UX', 'Prototypage'],
      membersCount: 15,
      members: [
        { name: 'Sara Design', role: 'Club Admin', avatar: 'https://i.pravatar.cc/150?u=club4', status: 'online' },
        { name: 'Karim UX', role: 'Member', avatar: 'https://i.pravatar.cc/150?u=club5', status: 'offline' }
      ]
    }
  ];

  constructor(
    private route: ActivatedRoute,
    private notificationService: NotificationService
  ) {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    // Always load a club - use the ID if it matches, otherwise use first club
    this.club = this.mockClubs.find(c => c.id === id) || this.mockClubs[0];
    this.currentUser = this.club.members[0];
    this.seedActivities();
  }

  get onlineMembers(): ClubMember[] {
    return this.club.members.filter(m => m.status === 'online');
  }

  postMessage(): void {
    const content = this.newMessage.trim();
    if (!content) { return; }

    const author = this.currentUser?.name || 'Club member';
    const avatar = this.currentUser?.avatar || 'https://i.pravatar.cc/150?u=club-member';

    const activity: ClubActivity = {
      id: Date.now(),
      author,
      avatar,
      createdAt: 'Just now',
      type: 'discussion',
      content
    };

    this.activities = [activity, ...this.activities];
    this.newMessage = '';

    this.notificationService.addNotification({
      type: 'club',
      title: `New discussion in ${this.club.name}`,
      message: content.length > 80 ? content.slice(0, 77) + '…' : content,
      importance: 'normal',
      relatedRoute: `/Club/${this.club.id}`
    });
  }

  private seedActivities(): void {
    this.activities = [
      {
        id: 1,
        author: this.club.members[0]?.name || 'Admin',
        avatar: this.club.members[0]?.avatar || 'https://i.pravatar.cc/150?u=club1',
        createdAt: '1 h ago',
        type: 'activity',
        content: 'New “Hands-on Angular signals” session added for Friday.'
      },
      {
        id: 2,
        author: this.club.members[1]?.name || 'Member',
        avatar: this.club.members[1]?.avatar || 'https://i.pravatar.cc/150?u=club2',
        createdAt: '3 h ago',
        type: 'discussion',
        content: 'Has anyone tried the new React Server Components APIs yet?'
      }
    ];
  }
}

