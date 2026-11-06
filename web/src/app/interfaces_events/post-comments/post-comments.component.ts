import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { Comment, CommentForm } from '../models';
import { CommentService } from '../comment.service';

@Component({
  selector: 'app-post-comments',
  templateUrl: './post-comments.component.html',
  styleUrls: ['./post-comments.component.css']
})
export class PostCommentsComponent implements OnInit {
  @Input() postId!: number;
  @Input() currentUserId: number = 1; // À remplacer par l'ID utilisateur réel
  @Input() showComments: boolean = false;
  @Output() commentsToggled = new EventEmitter<boolean>();
  @Output() commentAdded = new EventEmitter<void>();

  comments: Comment[] = [];
  commentsCount: number = 0;
  newCommentContent: string = '';
  isSubmitting: boolean = false;
  editingCommentId: number | null = null;
  editingContent: string = '';

  constructor(private commentService: CommentService) {}

  ngOnInit() {
    this.loadCommentsCount();
    if (this.showComments) {
      this.loadComments();
    }
  }

  loadCommentsCount() {
    this.commentService.getCommentsCount(this.postId).subscribe(count => {
      this.commentsCount = count;
    });
  }

  loadComments() {
    this.commentService.getCommentsByPost(this.postId).subscribe(comments => {
      this.comments = comments;
    });
  }

  toggleComments() {
    this.showComments = !this.showComments;
    if (this.showComments && this.comments.length === 0) {
      this.loadComments();
    }
    this.commentsToggled.emit(this.showComments);
  }

  addComment() {
    if (!this.newCommentContent.trim() || this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    const commentForm: CommentForm = {
      postId: this.postId,
      authorId: this.currentUserId,
      content: this.newCommentContent.trim()
    };

    this.commentService.addComment(commentForm).subscribe({
      next: (comment) => {
        this.comments.push(comment);
        this.commentsCount++;
        this.newCommentContent = '';
        this.isSubmitting = false;
        this.commentAdded.emit();
      },
      error: (error) => {
        console.error('Error adding comment:', error);
        this.isSubmitting = false;
      }
    });
  }

  startEditing(comment: Comment) {
    this.editingCommentId = comment.id!;
    this.editingContent = comment.content;
  }

  cancelEditing() {
    this.editingCommentId = null;
    this.editingContent = '';
  }

  saveEdit(commentId: number) {
    if (!this.editingContent.trim()) {
      return;
    }

    this.commentService.updateComment(commentId, this.editingContent.trim()).subscribe({
      next: (updatedComment) => {
        const index = this.comments.findIndex(c => c.id === commentId);
        if (index !== -1) {
          this.comments[index] = updatedComment;
        }
        this.cancelEditing();
      },
      error: (error) => {
        console.error('Error updating comment:', error);
      }
    });
  }

  deleteComment(commentId: number) {
    if (confirm('Are you sure you want to delete this comment?')) {
      this.commentService.deleteComment(commentId).subscribe({
        next: () => {
          this.comments = this.comments.filter(c => c.id !== commentId);
          this.commentsCount--;
        },
        error: (error) => {
          console.error('Error deleting comment:', error);
        }
      });
    }
  }

  getAuthorName(authorId: number): string {
    // À remplacer par un service utilisateur réel
    return `User ${authorId}`;
  }

  getTimeAgo(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 60) {
      return 'Just now';
    } else if (diffInSeconds < 3600) {
      const minutes = Math.floor(diffInSeconds / 60);
      return `${minutes}m ago`;
    } else if (diffInSeconds < 86400) {
      const hours = Math.floor(diffInSeconds / 3600);
      return `${hours}h ago`;
    } else {
      const days = Math.floor(diffInSeconds / 86400);
      return `${days}d ago`;
    }
  }

  onKeyPress(event: KeyboardEvent) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.addComment();
    }
  }
}