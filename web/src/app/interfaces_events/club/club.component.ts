import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ClubService } from '../club.service';
import { PostService } from '../post.service';
import { NotificationService } from '../notification.service';

@Component({
  selector: 'app-club',
  templateUrl: './club.component.html',
  styleUrls: ['./club.component.css']
})
export class ClubComponent implements OnInit {
  clubId!: number;
  club: any = null;
  loading = true;
  activeTab: 'about' | 'posts' = 'about';
  
  // Posts management
  posts: any[] = [];
  announcements: any[] = [];
  regularPosts: any[] = [];
  newPost = { content: '', title: '' };
  isAnnouncement = false;
  editingPost: any = null;
  editPostContent = '';
  error: string | null = null;
  
  // Mock data
  mockClub = {
    id: 0,
    name: 'Tech Innovators Club',
    description: 'A vibrant community of developers, designers, and tech enthusiasts passionate about innovation and collaboration.',
    interests: 'Technology, Programming, Web Development, AI',
    createdAt: new Date().toISOString(),
    bannerUrl: ''
  };

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private clubService: ClubService,
    private postService: PostService,
    private notificationService: NotificationService
  ) {}

  ngOnInit(): void {
    this.clubId = Number(this.route.snapshot.paramMap.get('id'));
    this.loadClub();
    this.loadClubPosts();
  }

  loadClub(): void {
    this.loading = true;
    this.clubService.getClubById(this.clubId).subscribe({
      next: (data) => {
        this.club = data;
        this.loading = false;
      },
      error: () => {
        // Use mock data on error
        this.club = { ...this.mockClub, id: this.clubId };
        this.loading = false;
      }
    });
  }

  setTab(tab: 'about' | 'posts'): void {
    this.activeTab = tab;
  }

  goBack(): void {
    this.router.navigate(['/clubs']);
  }

  shareClub(): void {
    const clubUrl = `${window.location.origin}/clubs/${this.clubId}`;
    
    // Try to use Web Share API if available
    if (navigator.share) {
      navigator.share({
        title: this.club.name,
        text: `Check out ${this.club.name} on CatchOPP!`,
        url: clubUrl
      }).then(() => {
        this.notificationService.addNotification({
          type: 'club',
          title: 'Club Shared!',
          message: `You shared "${this.club.name}" successfully`,
          importance: 'normal'
        });
      }).catch((error) => {
        console.log('Error sharing:', error);
        this.copyToClipboard(clubUrl);
      });
    } else {
      // Fallback: Copy to clipboard
      this.copyToClipboard(clubUrl);
    }
  }

  private copyToClipboard(text: string): void {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(() => {
        this.notificationService.addNotification({
          type: 'club',
          title: 'Link Copied!',
          message: 'Club link copied to clipboard. Share it with your friends!',
          importance: 'normal'
        });
      }).catch(() => {
        this.showShareDialog(text);
      });
    } else {
      this.showShareDialog(text);
    }
  }

  private showShareDialog(url: string): void {
    const message = `Share this club:\n${url}`;
    alert(message);
  }

  inviteFriends(): void {
    const clubUrl = `${window.location.origin}/clubs/${this.clubId}`;
    const inviteMessage = `Join me in ${this.club.name} on CatchOPP!\n\n${this.club.description}\n\nClick here to join: ${clubUrl}`;
    
    // Try to use Web Share API
    if (navigator.share) {
      navigator.share({
        title: `Join ${this.club.name}`,
        text: inviteMessage,
        url: clubUrl
      }).then(() => {
        this.notificationService.addNotification({
          type: 'club',
          title: 'Invitation Sent!',
          message: `You invited friends to join "${this.club.name}"`,
          importance: 'normal'
        });
      }).catch((error) => {
        console.log('Error inviting:', error);
        this.copyToClipboard(clubUrl);
      });
    } else {
      // Fallback: Copy invitation link
      this.copyToClipboard(clubUrl);
    }
  }

  leaveClub(): void {
    if (confirm(`Are you sure you want to leave "${this.club.name}"?\n\nYou will no longer receive updates from this club.`)) {
      // TODO: Implement actual leave club API call
      // For now, show notification and navigate back
      this.notificationService.addNotification({
        type: 'club',
        title: 'Left Club',
        message: `You have left "${this.club.name}"`,
        importance: 'normal'
      });
      
      // Navigate back to clubs list after a short delay
      setTimeout(() => {
        this.router.navigate(['/clubs']);
      }, 1500);
    }
  }

  getMemberInitials(name: string): string {
    return name.split(' ').map(n => n[0]).join('').toUpperCase();
  }

  getInterests(): string[] {
    if (!this.club?.interests) return [];
    return this.club.interests.split(',').map((i: string) => i.trim());
  }

  // Posts Management Methods
  loadClubPosts(): void {
    this.loading = true;
    this.error = null;
    
    // Load posts for this specific club only
    this.postService.getPostsByClubId(this.clubId).subscribe({
      next: (clubPosts) => {
        this.posts = clubPosts.map(post => ({
          ...post,
          author: `User ${post.authorId || 'Unknown'}`,
          avatar: `https://i.pravatar.cc/150?u=${post.authorId}`,
          role: 'Member',
          createdAt: this.formatDate(post.createdAt)
        }));
        
        // Separate announcements from regular posts
        this.announcements = this.posts.filter(p => p.isAnnouncement);
        this.regularPosts = this.posts.filter(p => !p.isAnnouncement);
        
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading club posts:', err);
        this.error = 'Failed to load posts. Please try again.';
        this.posts = [];
        this.announcements = [];
        this.regularPosts = [];
        this.loading = false;
      }
    });
  }

  createPost(): void {
    if (!this.club) return;
    
    const content = (this.newPost.content || '').trim();
    if (!content) {
      alert('Please enter some content for your post');
      return;
    }

    const newPost: any = {
      content: content,
      authorId: 1, // TODO: Replace with actual user ID
      isAnnouncement: this.isAnnouncement,
      club: { id: this.clubId }
    };

    if (this.newPost.title?.trim()) {
      newPost.title = this.newPost.title.trim();
    }

    this.loading = true;
    this.error = null;

    this.postService.createPost(newPost).subscribe({
      next: (created) => {
        console.log('Post created successfully:', created);
        this.notificationService.addNotification({
          type: 'club',
          title: this.isAnnouncement ? 'Announcement Posted!' : 'Post Created!',
          message: `Your ${this.isAnnouncement ? 'announcement' : 'post'} has been shared with ${this.club.name}`,
          importance: this.isAnnouncement ? 'high' : 'normal'
        });
        
        // Reset form
        this.newPost = { content: '', title: '' };
        this.isAnnouncement = false;
        
        // Reload posts
        this.loadClubPosts();
      },
      error: (err) => {
        console.error('Error creating post:', err);
        this.error = 'Failed to create post. Please try again.';
        this.loading = false;
      }
    });
  }

  startEditPost(post: any): void {
    this.editingPost = post;
    this.editPostContent = post.content;
  }

  cancelEditPost(): void {
    this.editingPost = null;
    this.editPostContent = '';
  }

  saveEditPost(): void {
    if (!this.editingPost) return;
    
    const content = this.editPostContent.trim();
    if (!content) {
      alert('Post content cannot be empty');
      return;
    }

    const updatedPost = {
      ...this.editingPost,
      content: content
    };

    this.postService.updatePost(this.editingPost.id, updatedPost).subscribe({
      next: () => {
        this.notificationService.addNotification({
          type: 'club',
          title: 'Post Updated!',
          message: 'Your post has been updated successfully',
          importance: 'normal'
        });
        this.cancelEditPost();
        this.loadClubPosts();
      },
      error: (err) => {
        console.error('Error updating post:', err);
        alert('Failed to update post. Please try again.');
      }
    });
  }

  deletePost(id: number): void {
    if (!confirm('Are you sure you want to delete this post?')) return;
    
    this.postService.deletePost(id).subscribe({
      next: () => {
        console.log('Post deleted successfully');
        this.notificationService.addNotification({
          type: 'club',
          title: 'Post Deleted',
          message: 'The post has been removed',
          importance: 'normal'
        });
        this.loadClubPosts();
      },
      error: (err) => {
        console.error('Error deleting post:', err);
        alert('Failed to delete post. Please try again.');
      }
    });
  }

  onPostInteraction(): void {
    // Reload posts when there's an interaction (comment/reaction)
    if (this.club) {
      this.loadClubPosts();
    }
  }

  formatDate(dateString: string | undefined): string {
    if (!dateString) return 'Recently';
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);
    
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} minute${diffMins > 1 ? 's' : ''} ago`;
    if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
    return date.toLocaleDateString();
  }
}
