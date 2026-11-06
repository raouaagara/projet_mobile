package tn.esprit.communitymicroservice.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.communitymicroservice.entities.Post;
import tn.esprit.communitymicroservice.services.PostService;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/posts")
@CrossOrigin(origins = "*")
public class PostController {
    @Autowired
    private PostService postService;

    /** Feed with real counts (the /group/{id}/user/{id} endpoint returns zeros). */
    @GetMapping("/feed")
    public ResponseEntity<List<Map<String, Object>>> feed(@RequestParam(required = false) Long groupId,
                                                          @RequestParam(required = false) Long clubId,
                                                          @RequestParam(required = false) Long userId) {
        return ResponseEntity.ok(postService.feed(groupId, clubId, userId));
    }

    @PostMapping
    public ResponseEntity<Post> createPost(@RequestBody Post post) {
        try {
            Post createdPost = postService.createPost(post);
            return ResponseEntity.ok(createdPost);
        } catch (org.springframework.web.server.ResponseStatusException e) {
            throw e; // a refusal with a reason (e.g. not a member): keep its status and message
        } catch (Exception e) {
            System.err.println("Error in createPost: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Post>> getAllPosts() {
        try {
            List<Post> posts = postService.getAllPosts();
            return ResponseEntity.ok(posts);
        } catch (Exception e) {
            System.err.println("Error in getAllPosts: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<Post> getPostById(@PathVariable Long id) {
        try {
            Post post = postService.getPostById(id);
            return ResponseEntity.ok(post);
        } catch (Exception e) {
            System.err.println("Error in getPostById: " + e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/group/{groupId}")
    public ResponseEntity<List<Post>> getPostsByGroupId(@PathVariable Long groupId) {
        try {
            System.out.println("API called: getPostsByGroupId for group " + groupId);
            List<Post> posts = postService.getPostsByGroupId(groupId);
            System.out.println("Returning " + posts.size() + " posts");
            return ResponseEntity.ok(posts);
        } catch (Exception e) {
            System.err.println("Error in getPostsByGroupId: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/club/{clubId}")
    public ResponseEntity<List<Post>> getPostsByClubId(@PathVariable Long clubId) {
        try {
            System.out.println("API called: getPostsByClubId for club " + clubId);
            List<Post> posts = postService.getPostsByClubId(clubId);
            System.out.println("Returning " + posts.size() + " posts");
            return ResponseEntity.ok(posts);
        } catch (Exception e) {
            System.err.println("Error in getPostsByClubId: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/group/{groupId}/simple")
    public ResponseEntity<List<Post>> getPostsByGroupIdSimple(@PathVariable Long groupId) {
        try {
            System.out.println("Simple API called for group " + groupId);
            List<Post> posts = postService.getPostsByGroupId(groupId);
            System.out.println("Returning " + posts.size() + " simple posts");
            return ResponseEntity.ok(posts);
        } catch (Exception e) {
            System.err.println("Error in getPostsByGroupIdSimple: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/group/{groupId}/user/{userId}")
    public ResponseEntity<List<Map<String, Object>>> getPostsByGroupIdWithUserReactions(
            @PathVariable Long groupId, 
            @PathVariable Long userId) {
        try {
            List<Post> posts = postService.getPostsByGroupId(groupId);
            List<Map<String, Object>> enrichedPosts = posts.stream().map(post -> {
                Map<String, Object> postData = new HashMap<>();
                postData.put("post", post);
                postData.put("commentsCount", 0); // Simplified
                postData.put("reactionCounts", new HashMap<>()); // Simplified
                postData.put("userReaction", null); // Simplified
                postData.put("totalReactions", 0); // Simplified
                return postData;
            }).toList();
            return ResponseEntity.ok(enrichedPosts);
        } catch (Exception e) {
            System.err.println("Error in getPostsByGroupIdWithUserReactions: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<Post> updatePost(@PathVariable Long id, @RequestBody Post post) {
        try {
            Post updatedPost = postService.updatePost(id, post);
            return ResponseEntity.ok(updatedPost);
        } catch (org.springframework.web.server.ResponseStatusException e) {
            throw e; // refused by the moderation: keep its status and reason
        } catch (Exception e) {
            System.err.println("Error in updatePost: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePost(@PathVariable Long id) {
        try {
            postService.deletePost(id);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            System.err.println("Error in deletePost: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/debug/all")
    public ResponseEntity<List<Post>> getAllPostsDebug() {
        try {
            List<Post> posts = postService.getAllPosts();
            System.out.println("Debug: Found " + posts.size() + " posts");
            return ResponseEntity.ok(posts);
        } catch (Exception e) {
            System.err.println("Error in debug endpoint: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/debug/group/{groupId}")
    public ResponseEntity<List<Post>> getPostsByGroupIdDebug(@PathVariable Long groupId) {
        try {
            List<Post> posts = postService.getPostsByGroupId(groupId);
            System.out.println("Debug: Found " + posts.size() + " posts for group " + groupId);
            return ResponseEntity.ok(posts);
        } catch (Exception e) {
            System.err.println("Error in debug group endpoint: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/with-engagement")
    public ResponseEntity<List<Map<String, Object>>> getPostsWithEngagement() {
        try {
            List<Post> posts = postService.getAllPosts();
            List<Map<String, Object>> enrichedPosts = posts.stream().map(post -> {
                Map<String, Object> postData = new HashMap<>();
                postData.put("id", post.getId());
                postData.put("content", post.getContent());
                postData.put("authorId", post.getAuthorId());
                postData.put("isAnnouncement", post.getIsAnnouncement());
                postData.put("createdAt", post.getCreatedAt());
                postData.put("groupId", post.getGroup() != null ? post.getGroup().getId() : null);
                
                // Add engagement metrics
                postData.put("totalReactions", getTotalReactionsForPost(post.getId()));
                postData.put("totalComments", getTotalCommentsForPost(post.getId()));
                postData.put("engagementScore", getTotalReactionsForPost(post.getId()) + getTotalCommentsForPost(post.getId()));
                
                return postData;
            }).toList();
            return ResponseEntity.ok(enrichedPosts);
        } catch (Exception e) {
            System.err.println("Error in getPostsWithEngagement: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @Autowired
    private tn.esprit.communitymicroservice.services.ReactionService reactionService;

    @Autowired
    private tn.esprit.communitymicroservice.services.CommentService commentService;

    private long getTotalReactionsForPost(Long postId) {
        try {
            Map<tn.esprit.communitymicroservice.entities.ReactionType, Long> counts = reactionService.getReactionCounts(postId);
            return counts.values().stream().mapToLong(Long::longValue).sum();
        } catch (Exception e) {
            return 0;
        }
    }

    private long getTotalCommentsForPost(Long postId) {
        try {
            return commentService.getCommentsCount(postId);
        } catch (Exception e) {
            return 0;
        }
    }
}
