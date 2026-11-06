import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NotificationService } from '../notification.service';
import { GroupService } from '../group.service';
import { EventService } from '../event.service';
import { PostService } from '../post.service';
import { GroupMemberService } from '../group-member.service';
import { Post } from '../models';

interface GroupMember {
  name: string;
  role: string;
  avatar: string;
  status: 'online' | 'offline';
}

interface GroupDetails {
  id: number;
  name: string;
  description: string;
  membersCount: number;
  visibility: 'Public' | 'Private' | 'Invitation only';
  createdAt: string;
  members: GroupMember[];
  bannerUrl?: string;
}

interface GroupPost {
  id: number;
  author: string;
  role: string;
  avatar: string;
  createdAt: string;
  title: string;
  content: string;
  isAnnouncement: boolean;
  likes?: number;
  comments?: PostComment[];
}

interface PostComment {
  id: number;
  author: string;
  avatar: string;
  content: string;
  createdAt: string;
}

interface GroupEvent {
  id: number;
  title: string;
  date: string;
  time: string;
  location: string;
  type: 'Webinar' | 'Meetup' | 'Social' | 'Workshop';
  isOnline: boolean;
  remindMe: boolean;
}

@Component({
  selector: 'app-group-page',
  templateUrl: './group-page.component.html',
  styleUrls: ['./group-page.component.css']
})
export class GroupPageComponent implements OnInit {
  group: GroupDetails | undefined;
  currentUser: GroupMember | undefined;
  currentUserRole: 'Admin' | 'Moderator' | 'Member' = 'Member';
  roleStats = {
    Admin: 0,
    Moderator: 0,
    Member: 0
  };
  posts: GroupPost[] = [];
  newPost: Partial<GroupPost> = { title: '', content: '' };
  isAnnouncement = false;
  editingPost: GroupPost | null = null;
  editPostContent = '';
  showComments: { [postId: number]: boolean } = {};
  newComment: { [postId: number]: string } = {};
  events: GroupEvent[] = [];
  calendarMonthLabel = '';
  calendarDays: { day: number; hasEvent: boolean }[] = [];
  loading = false;
  error: string | null = null;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private notificationService: NotificationService,
    private groupService: GroupService,
    private eventService: EventService,
    private postService: PostService,
    private memberService: GroupMemberService
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (id) {
      this.loadGroupData(id);
    }
  }

  loadGroupData(id: number): void {
    this.loading = true;
    this.error = null;

    this.groupService.getGroupById(id).subscribe({
      next: (group) => {
        this.group = {
          id: group.id || 0,
          name: group.name,
          description: group.description,
          membersCount: 0,
          visibility: this.mapTypeToVisibility(group.type),
          createdAt: 'Recently',
          members: [],
          bannerUrl: group.bannerUrl
        };
        
        this.loadGroupMembers(id);
        this.loadGroupPosts(id);
        this.loadGroupEvents(id);
        this.buildCalendar();
        // Don't set loading to false here, let loadGroupPosts handle it
      },
      error: (err) => {
        this.error = 'Impossible de charger le groupe';
        this.loading = false;
        console.error(err);
      }
    });
  }

  private mapTypeToVisibility(type: string): 'Public' | 'Private' | 'Invitation only' {
    const map: Record<string, 'Public' | 'Private' | 'Invitation only'> = {
      'PUBLIC': 'Public',
      'PRIVATE': 'Private',
      'INVITE_ONLY': 'Invitation only'
    };
    return map[type] || 'Public';
  }

  loadGroupMembers(groupId: number): void {
    this.memberService.getMembersByGroupId(groupId).subscribe({
      next: (members) => {
        if (this.group) {
          this.group.members = members.map(m => ({
            name: `User ${m.userId}`,
            role: m.role,
            avatar: `https://i.pravatar.cc/150?u=${m.userId}`,
            status: 'online' as const
          }));
          this.group.membersCount = members.length;
          
          if (this.group.members.length > 0) {
            this.currentUser = this.group.members[0];
            // Set first user as Admin for testing
            this.currentUserRole = 'Admin';
          }
          
          this.computeRoleStats();
        }
      },
      error: (err) => {
        console.error('Error loading members:', err);
        if (this.group) {
          this.group.members = [];
          this.group.membersCount = 0;
          // Even if no members, set as Admin for testing
          this.currentUserRole = 'Admin';
        }
      }
    });
  }

  loadGroupPosts(groupId: number): void {
    console.log('Loading posts for group:', groupId);
    
    // Only set loading if not already loading from group data
    if (!this.loading) {
      this.loading = true;
    }
    this.error = null;
    
    // Utiliser l'API simple d'abord
    this.postService.getPostsByGroupIdSimple(groupId).subscribe({
      next: (posts) => {
        console.log('Received simple posts:', posts);
        if (posts && posts.length > 0) {
          this.posts = posts.map(p => ({
            id: p.id || 0,
            author: `User ${p.authorId || 'Unknown'}`,
            role: 'Member',
            avatar: `https://i.pravatar.cc/150?u=${p.authorId || 1}`,
            createdAt: this.formatDate(p.createdAt),
            title: '',
            content: p.content || 'No content',
            isAnnouncement: p.isAnnouncement || false,
            likes: Math.floor(Math.random() * 10), // Random likes for demo
            comments: this.generateStaticComments()
          }));
          console.log('Mapped simple posts:', this.posts);
          console.log('Total posts loaded:', this.posts.length);
        } else {
          console.log('No posts found for group', groupId);
          this.posts = [];
        }
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading simple posts:', err);
        console.log('Error details:', err.error, err.status, err.statusText);
        
        // Fallback vers l'API normale
        this.postService.getPostsByGroupId(groupId).subscribe({
          next: (posts) => {
            console.log('Received fallback posts:', posts);
            if (posts && posts.length > 0) {
              this.posts = posts.map(p => ({
                id: p.id || 0,
                author: `User ${p.authorId || 'Unknown'}`,
                role: 'Member',
                avatar: `https://i.pravatar.cc/150?u=${p.authorId || 1}`,
                createdAt: this.formatDate(p.createdAt),
                title: '',
                content: p.content || 'No content',
                isAnnouncement: p.isAnnouncement || false,
                likes: Math.floor(Math.random() * 10),
                comments: this.generateStaticComments()
              }));
              console.log('Mapped fallback posts:', this.posts);
            } else {
              this.posts = [];
            }
            this.loading = false;
          },
          error: (fallbackErr) => {
            console.error('All APIs failed:', fallbackErr);
            this.posts = [];
            this.error = 'Unable to load posts. Please check if the server is running.';
            this.loading = false;
          }
        });
      }
    });
  }

  private generateStaticComments(): PostComment[] {
    const commentCount = Math.floor(Math.random() * 4);
    const comments: PostComment[] = [];
    
    for (let i = 0; i < commentCount; i++) {
      comments.push({
        id: i + 1,
        author: `User ${Math.floor(Math.random() * 10) + 1}`,
        avatar: `https://i.pravatar.cc/150?u=${Math.floor(Math.random() * 100)}`,
        content: this.getRandomComment(),
        createdAt: `${Math.floor(Math.random() * 24)} hours ago`
      });
    }
    
    return comments;
  }

  private getRandomComment(): string {
    const comments = [
      'Great post! Thanks for sharing.',
      'This is really helpful, appreciate it!',
      'Interesting perspective on this topic.',
      'I agree with this approach.',
      'Looking forward to more updates!',
      'Thanks for the information!'
    ];
    return comments[Math.floor(Math.random() * comments.length)];
  }

  loadGroupEvents(groupId: number): void {
    this.eventService.getEventsByGroupId(groupId).subscribe({
      next: (events) => {
        this.events = events.map(e => ({
          id: e.id || 0,
          title: e.title,
          date: e.startDate.split('T')[0],
          time: e.startDate.split('T')[1]?.substring(0, 5) || '00:00',
          location: e.location,
          type: 'Meetup' as const,
          isOnline: e.location.toLowerCase().includes('online'),
          remindMe: false
        }));
        this.buildCalendar();
      },
      error: (err) => {
        console.error('Error loading events:', err);
        this.events = [];
      }
    });
  }

  private formatDate(dateStr?: string): string {
    if (!dateStr) return 'Recently';
    const date = new Date(dateStr);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    
    if (hours < 1) return 'Just now';
    if (hours < 24) return `${hours} hours ago`;
    const days = Math.floor(hours / 24);
    if (days < 7) return `${days} days ago`;
    return date.toLocaleDateString();
  }

  get isAdmin(): boolean {
    return this.currentUserRole === 'Admin';
  }

  get canModerate(): boolean {
    return this.currentUserRole === 'Admin' || this.currentUserRole === 'Moderator';
  }

  get announcements(): GroupPost[] {
    return this.posts.filter(p => p.isAnnouncement);
  }

  get regularPosts(): GroupPost[] {
    return this.posts.filter(p => !p.isAnnouncement);
  }

  changeRole(member: GroupMember, role: string): void {
    const r = role as 'Admin' | 'Moderator' | 'Member';
    member.role = r;
    if (this.currentUser && member.name === this.currentUser.name) {
      this.currentUserRole = r;
    }
    this.computeRoleStats();
  }

  private computeRoleStats(): void {
    if (!this.group) return;
    this.roleStats = { Admin: 0, Moderator: 0, Member: 0 };
    for (const m of this.group.members) {
      if (m.role === 'Admin') this.roleStats.Admin++;
      else if (m.role === 'Moderator') this.roleStats.Moderator++;
      else this.roleStats.Member++;
    }
  }

  createPost(): void {
    if (!this.group) return;
    const content = (this.newPost.content || '').trim();
    if (!content) {
      alert('Please enter some content for your post.');
      return;
    }

    const newPost: Post = {
      group: { id: this.group.id },
      authorId: 1, // TODO: Get from auth service
      content: content,
      isAnnouncement: this.isAnnouncement
    };

    console.log('Creating post:', newPost);

    // Show loading state
    this.loading = true;
    this.error = null;

    this.postService.createPost(newPost).subscribe({
      next: (created) => {
        console.log('Post created successfully:', created);
        
        // Send notification about new post
        this.notificationService.notifyNewPost(
          this.group!.id,
          this.group!.name,
          content
        );
        
        // Clear form
        this.newPost = { title: '', content: '' };
        this.isAnnouncement = false;
        // Reload posts to show the new one
        this.loadGroupPosts(this.group!.id);
      },
      error: (err) => {
        console.error('Error creating post:', err);
        this.loading = false;
        this.error = 'Error creating post. Please try again.';
      }
    });
  }

  onPostInteraction(): void {
    // Méthode appelée quand il y a une interaction (commentaire/réaction)
    if (this.group) {
      this.loadGroupPosts(this.group.id);
    }
  }

  startEditPost(post: GroupPost): void {
    this.editingPost = post;
    this.editPostContent = post.content;
  }

  cancelEditPost(): void {
    this.editingPost = null;
    this.editPostContent = '';
  }

  saveEditPost(): void {
    if (!this.editingPost || !this.group) return;
    const content = this.editPostContent.trim();
    if (!content) {
      alert('Please enter some content for your post.');
      return;
    }

    const updatedPost: Post = {
      group: { id: this.group.id },
      authorId: 1, // TODO: Get from auth service
      content: content,
      isAnnouncement: this.editingPost.isAnnouncement
    };

    this.postService.updatePost(this.editingPost.id, updatedPost).subscribe({
      next: () => {
        console.log('Post updated successfully');
        this.cancelEditPost();
        // Reload posts to show the updated content
        this.loadGroupPosts(this.group!.id);
      },
      error: (err) => {
        console.error('Error updating post:', err);
        alert('Error updating post. Please try again.');
      }
    });
  }

  deletePost(id: number): void {
    if (!confirm('Are you sure you want to delete this post?')) return;
    
    this.postService.deletePost(id).subscribe({
      next: () => {
        console.log('Post deleted successfully');
        // Reload posts after deletion
        if (this.group) {
          this.loadGroupPosts(this.group.id);
        }
      },
      error: (err) => {
        console.error('Error deleting post:', err);
        alert('Error deleting post. Please try again.');
      }
    });
  }

  // Méthodes simples pour les interactions temporaires
  likePost(post: GroupPost): void {
    post.likes = (post.likes || 0) + 1;
  }

  toggleComments(postId: number): void {
    this.showComments[postId] = !this.showComments[postId];
  }

  addComment(post: GroupPost): void {
    const content = (this.newComment[post.id] || '').trim();
    if (!content) return;

    const comment: PostComment = {
      id: (post.comments?.length || 0) + 1,
      author: this.currentUser?.name || 'User 1',
      avatar: this.currentUser?.avatar || 'https://i.pravatar.cc/150?u=1',
      content: content,
      createdAt: 'Just now'
    };

    if (!post.comments) {
      post.comments = [];
    }
    post.comments.push(comment);
    this.newComment[post.id] = '';
  }

  toggleReminder(event: GroupEvent): void {
    event.remindMe = !event.remindMe;
    if (event.remindMe && this.group) {
      this.notificationService.addNotification({
        type: 'event',
        title: 'Reminder enabled',
        message: `You will be reminded for "${event.title}" in group ${this.group.name}.`,
        importance: 'high',
        relatedRoute: `/groups/${this.group.id}`
      });
    }
  }

  private buildCalendar(): void {
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth();
    const daysInMonth = new Date(year, month + 1, 0).getDate();

    this.calendarMonthLabel = today.toLocaleString('default', {
      month: 'long',
      year: 'numeric'
    });

    const eventDays = new Set<number>();
    for (const e of this.events) {
      if (!e.date) continue;
      const d = new Date(e.date);
      if (!isNaN(d.getTime()) && d.getFullYear() === year && d.getMonth() === month) {
        eventDays.add(d.getDate());
      }
    }

    this.calendarDays = [];
    for (let day = 1; day <= daysInMonth; day++) {
      this.calendarDays.push({
        day,
        hasEvent: eventDays.has(day)
      });
    }
  }
}
