/**
 * API Configuration for Events & Communities Module
 */

export const API_CONFIG = {
  BASE_URL: 'http://localhost:8090',
  ENDPOINTS: {
    GROUPS: '/api/groups',
    EVENTS: '/api/events',
    CLUBS: '/api/clubs',
    POSTS: '/api/posts',
    GROUP_MEMBERS: '/api/group-members',
    COMMENTS: '/api/comments',
    REACTIONS: '/api/reactions'
  }
};

// Helper function to build full URL
export function getApiUrl(endpoint: string): string {
  return `${API_CONFIG.BASE_URL}${endpoint}`;
}

