package tn.esprit.communitymicroservice.services;

import tn.esprit.communitymicroservice.ai.ContentModerator;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import tn.esprit.communitymicroservice.entities.Reaction;
import tn.esprit.communitymicroservice.entities.ReactionType;
import tn.esprit.communitymicroservice.repositories.CommentRepository;
import tn.esprit.communitymicroservice.repositories.GroupMemberRepository;
import tn.esprit.communitymicroservice.repositories.ReactionRepository;
import org.springframework.stereotype.Service;
import tn.esprit.communitymicroservice.entities.Post;
import tn.esprit.communitymicroservice.repositories.PostRepository;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class PostService {
    /** Checks the text by meaning before it is published (AI, fails open). */
    @Autowired
    private ContentModerator moderator;

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private GroupMemberRepository groupMemberRepository;

    @Autowired
    private ReactionRepository reactionRepository;

    @Autowired
    private CommentRepository commentRepository;

    /**
     * Posts of a group or a club (or all), newest first, each with its comment count, reaction
     * counts and [userId]'s own reaction — what a feed shows, in one call.
     */
    public List<Map<String, Object>> feed(Long groupId, Long clubId, Long userId) {
        List<Post> posts = groupId != null ? postRepository.findByGroupId(groupId)
                : clubId != null ? postRepository.findByClubId(clubId)
                : postRepository.findAll();
        return posts.stream()
                .sorted(Comparator.comparing(Post::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .map(post -> {
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", post.getId());
                    item.put("content", post.getContent());
                    item.put("authorId", post.getAuthorId());
                    item.put("isAnnouncement", Boolean.TRUE.equals(post.getIsAnnouncement()));
                    item.put("createdAt", post.getCreatedAt());
                    item.put("groupId", post.getGroup() != null ? post.getGroup().getId() : null);
                    item.put("groupName", post.getGroup() != null ? post.getGroup().getName() : null);
                    item.put("clubId", post.getClub() != null ? post.getClub().getId() : null);
                    item.put("clubName", post.getClub() != null ? post.getClub().getName() : null);
                    List<Reaction> reactions = reactionRepository.findByPostId(post.getId());
                    Map<ReactionType, Long> counts = new LinkedHashMap<>();
                    for (Reaction r : reactions) counts.merge(r.getType(), 1L, Long::sum);
                    item.put("reactionCounts", counts);
                    item.put("totalReactions", reactions.size());
                    item.put("commentsCount", commentRepository.countByPostId(post.getId()));
                    item.put("userReaction", userId == null ? null : reactions.stream()
                            .filter(r -> userId.equals(r.getAuthorId())).map(Reaction::getType).findFirst().orElse(null));
                    return item;
                })
                .toList();
    }

    public Post createPost(Post post) {
        moderator.requireAllowed(post.getContent());
        // Only members post in a group (clubs: the club's own page).
        if (post.getGroup() != null && post.getGroup().getId() != null && post.getAuthorId() != null
                && !groupMemberRepository.existsByGroupIdAndUserId(post.getGroup().getId(), post.getAuthorId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Join the group to post in it.");
        }
        try {
            post.setCreatedAt(LocalDateTime.now());
            System.out.println("Creating post: " + post.getContent() + " for group: " + 
                              (post.getGroup() != null ? post.getGroup().getId() : "null"));
            Post savedPost = postRepository.save(post);
            System.out.println("Post saved with ID: " + savedPost.getId());
            return savedPost;
        } catch (Exception e) {
            System.err.println("Error creating post: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Failed to create post: " + e.getMessage());
        }
    }

    public List<Post> getAllPosts() {
        try {
            List<Post> posts = postRepository.findAllOrderByCreatedAtDesc();
            System.out.println("Found " + posts.size() + " total posts");
            return posts;
        } catch (Exception e) {
            System.err.println("Error getting all posts: " + e.getMessage());
            return postRepository.findAll(); // Fallback
        }
    }

    public Post getPostById(Long id) {
        return postRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Post not found"));
    }

    public List<Post> getPostsByGroupId(Long groupId) {
        try {
            System.out.println("Looking for posts in group: " + groupId);
            List<Post> posts = postRepository.findByGroupId(groupId);
            System.out.println("Found " + posts.size() + " posts for group " + groupId);
            return posts;
        } catch (Exception e) {
            System.err.println("Error getting posts by group: " + e.getMessage());
            // Fallback: filter all posts by group ID
            try {
                List<Post> allPosts = postRepository.findAll();
                List<Post> filteredPosts = allPosts.stream()
                    .filter(p -> p.getGroup() != null && p.getGroup().getId().equals(groupId))
                    .collect(Collectors.toList());
                System.out.println("Fallback: Found " + filteredPosts.size() + " posts for group " + groupId);
                return filteredPosts;
            } catch (Exception fallbackError) {
                System.err.println("Fallback also failed: " + fallbackError.getMessage());
                return List.of(); // Return empty list
            }
        }
    }

    public List<Post> getPostsByClubId(Long clubId) {
        try {
            System.out.println("Looking for posts in club: " + clubId);
            List<Post> posts = postRepository.findByClubId(clubId);
            System.out.println("Found " + posts.size() + " posts for club " + clubId);
            return posts;
        } catch (Exception e) {
            System.err.println("Error getting posts by club: " + e.getMessage());
            // Fallback: filter all posts by club ID
            try {
                List<Post> allPosts = postRepository.findAll();
                List<Post> filteredPosts = allPosts.stream()
                    .filter(p -> p.getClub() != null && p.getClub().getId().equals(clubId))
                    .collect(Collectors.toList());
                System.out.println("Fallback: Found " + filteredPosts.size() + " posts for club " + clubId);
                return filteredPosts;
            } catch (Exception fallbackError) {
                System.err.println("Fallback also failed: " + fallbackError.getMessage());
                return List.of(); // Return empty list
            }
        }
    }

    public Post updatePost(Long id, Post updated) {
        moderator.requireAllowed(updated.getContent());
        try {
            Post post = getPostById(id);
            post.setContent(updated.getContent());
            if (updated.getIsAnnouncement() != null) {
                post.setIsAnnouncement(updated.getIsAnnouncement());
            }
            return postRepository.save(post);
        } catch (Exception e) {
            System.err.println("Error updating post: " + e.getMessage());
            throw new RuntimeException("Failed to update post: " + e.getMessage());
        }
    }

    public void deletePost(Long id) {
        try {
            postRepository.deleteById(id);
            System.out.println("Post deleted with ID: " + id);
        } catch (Exception e) {
            System.err.println("Error deleting post: " + e.getMessage());
            throw new RuntimeException("Failed to delete post: " + e.getMessage());
        }
    }
}
