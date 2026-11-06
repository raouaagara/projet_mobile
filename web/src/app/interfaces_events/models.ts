/**
 * Models for Events & Communities Module
 * Aligned with CommunityMicroService backend entities
 */

// Enums
export enum GroupType {
  PUBLIC = 'PUBLIC',
  PRIVATE = 'PRIVATE',
  INVITE_ONLY = 'INVITE_ONLY'
}

export enum MemberRole {
  ADMIN = 'ADMIN',
  MODERATOR = 'MODERATOR',
  MEMBER = 'MEMBER'
}

export enum ReactionType {
  LIKE = 'LIKE',
  LOVE = 'LOVE',
  HAPPY = 'HAPPY',
  SAD = 'SAD',
  ANGRY = 'ANGRY',
  WOW = 'WOW'
}

// Group Model
export interface Group {
  id?: number;
  name: string;
  description: string;
  bannerUrl?: string;
  type: GroupType;
}

// Event Model
export interface Event {
  id?: number;
  title: string;
  description: string;
  location: string;
  startDate: string; // ISO 8601 format
  endDate: string;   // ISO 8601 format
  group?: { id: number };
  creatorId?: number;
  createdAt?: string;
  status?: string; // PENDING, APPROVED, REJECTED
}

// Club Model
export interface Club {
  id?: number;
  name: string;
  description: string;
  bannerUrl?: string;
  interests?: string;
  creatorId?: number;
  createdAt?: string;
  status?: string; // ACTIVE or PAUSED
}

// Post Model
export interface Post {
  id?: number;
  group?: { id: number };
  authorId?: number;
  content: string;
  isAnnouncement?: boolean;
  createdAt?: string;
  commentsCount?: number;
  reactionCounts?: { [key in ReactionType]: number };
  userReaction?: ReactionType;
  totalReactions?: number;
}

// Comment Model
export interface Comment {
  id?: number;
  content: string;
  createdAt?: string;
  post?: { id: number };
  authorId?: number;
}

// Reaction Model
export interface Reaction {
  id?: number;
  post?: { id: number };
  authorId?: number;
  type: ReactionType;
  createdAt?: string;
}

// GroupMember Model
export interface GroupMember {
  id?: number;
  group?: { id: number };
  userId: number;
  role: MemberRole;
  joinedAt?: string;
}

// API Response Models
export interface ApiResponse<T> {
  data: T;
  message?: string;
  status: number;
}

export interface PaginatedResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  currentPage: number;
  pageSize: number;
}

// Form Models (for creating/updating)
export interface GroupForm {
  name: string;
  description: string;
  bannerUrl?: string;
  type: GroupType;
}

export interface EventForm {
  title: string;
  description: string;
  location: string;
  startDate: string;
  endDate: string;
  groupId: number;
}

export interface ClubForm {
  name: string;
  description: string;
  bannerUrl?: string;
  interests?: string;
}

export interface PostForm {
  groupId: number;
  content: string;
  isAnnouncement?: boolean;
}

export interface CommentForm {
  postId: number;
  authorId: number;
  content: string;
}

export interface ReactionForm {
  postId: number;
  authorId: number;
  type: ReactionType;
}

export interface GroupMemberForm {
  groupId: number;
  userId: number;
  role: MemberRole;
}
