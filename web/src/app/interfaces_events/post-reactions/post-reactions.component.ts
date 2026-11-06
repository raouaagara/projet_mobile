import { Component, Input, Output, EventEmitter, OnInit } from '@angular/core';
import { ReactionType } from '../models';
import { ReactionService } from '../reaction.service';

@Component({
  selector: 'app-post-reactions',
  templateUrl: './post-reactions.component.html',
  styleUrls: ['./post-reactions.component.css']
})
export class PostReactionsComponent implements OnInit {
  @Input() postId!: number;
  @Input() currentUserId: number = 1; // À remplacer par l'ID utilisateur réel
  @Output() reactionChanged = new EventEmitter<void>();

  // Exposer l'enum pour le template
  ReactionType = ReactionType;

  reactionCounts: { [key in ReactionType]: number } = {
    [ReactionType.LIKE]: 0,
    [ReactionType.LOVE]: 0,
    [ReactionType.HAPPY]: 0,
    [ReactionType.SAD]: 0,
    [ReactionType.ANGRY]: 0,
    [ReactionType.WOW]: 0
  };

  userReaction: ReactionType | null = null;
  showReactionPicker = false;
  private hidePickerTimeout: any;

  reactionEmojis = {
    [ReactionType.LIKE]: '👍',
    [ReactionType.LOVE]: '❤️',
    [ReactionType.HAPPY]: '😊',
    [ReactionType.SAD]: '😢',
    [ReactionType.ANGRY]: '😠',
    [ReactionType.WOW]: '😮'
  };

  reactionLabels = {
    [ReactionType.LIKE]: 'Like',
    [ReactionType.LOVE]: 'Love',
    [ReactionType.HAPPY]: 'Happy',
    [ReactionType.SAD]: 'Sad',
    [ReactionType.ANGRY]: 'Angry',
    [ReactionType.WOW]: 'Wow'
  };

  constructor(private reactionService: ReactionService) {}

  ngOnInit() {
    this.loadReactions();
    this.loadUserReaction();
  }

  loadReactions() {
    this.reactionService.getReactionCounts(this.postId).subscribe(counts => {
      this.reactionCounts = counts;
    });
  }

  loadUserReaction() {
    this.reactionService.getUserReaction(this.postId, this.currentUserId).subscribe(response => {
      this.userReaction = response.reactionType;
    });
  }

  showPicker() {
    clearTimeout(this.hidePickerTimeout);
    this.showReactionPicker = true;
  }

  hidePicker() {
    this.hidePickerTimeout = setTimeout(() => {
      this.showReactionPicker = false;
    }, 300); // 300ms delay before hiding
  }

  toggleReactionPicker() {
    this.showReactionPicker = !this.showReactionPicker;
  }

  selectReaction(reactionType: ReactionType) {
    const reactionForm = {
      postId: this.postId,
      authorId: this.currentUserId,
      type: reactionType
    };

    this.reactionService.addOrUpdateReaction(reactionForm).subscribe(() => {
      this.loadReactions();
      this.loadUserReaction();
      this.showReactionPicker = false;
      this.reactionChanged.emit();
    });
  }

  getTotalReactions(): number {
    return Object.values(this.reactionCounts).reduce((sum, count) => sum + count, 0);
  }

  getTopReactions(): ReactionType[] {
    return Object.entries(this.reactionCounts)
      .filter(([_, count]) => count > 0)
      .sort(([_, a], [__, b]) => b - a)
      .slice(0, 3)
      .map(([type, _]) => type as ReactionType);
  }

  getReactionTypes(): ReactionType[] {
    return Object.values(ReactionType);
  }
}