package tn.esprit.communitymicroservice.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.communitymicroservice.entities.CommentReaction;
import tn.esprit.communitymicroservice.entities.ReactionType;
import tn.esprit.communitymicroservice.services.CommentReactionService;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/comment-reactions")
@CrossOrigin(origins = "*")
public class CommentReactionController {

    @Autowired
    private CommentReactionService commentReactionService;

    @PostMapping
    public ResponseEntity<CommentReaction> addOrUpdateReaction(@RequestBody Map<String, Object> request) {
        Long commentId = Long.valueOf(request.get("commentId").toString());
        Long authorId = Long.valueOf(request.get("authorId").toString());
        ReactionType type = ReactionType.valueOf(request.get("type").toString());

        CommentReaction reaction = commentReactionService.addOrUpdateReaction(commentId, authorId, type);
        return ResponseEntity.ok(reaction);
    }

    @GetMapping("/comment/{commentId}/counts")
    public ResponseEntity<Map<ReactionType, Long>> getReactionCounts(@PathVariable Long commentId) {
        Map<ReactionType, Long> counts = commentReactionService.getReactionCounts(commentId);
        return ResponseEntity.ok(counts);
    }

    @GetMapping("/comment/{commentId}/user/{authorId}")
    public ResponseEntity<Map<String, Object>> getUserReaction(
            @PathVariable Long commentId, 
            @PathVariable Long authorId) {
        Optional<ReactionType> userReaction = commentReactionService.getUserReaction(commentId, authorId);
        Map<String, Object> response = new HashMap<>();
        response.put("hasReaction", userReaction.isPresent());
        response.put("reactionType", userReaction.orElse(null));
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/comment/{commentId}/user/{authorId}")
    public ResponseEntity<Void> removeReaction(
            @PathVariable Long commentId, 
            @PathVariable Long authorId) {
        commentReactionService.removeReaction(commentId, authorId);
        return ResponseEntity.ok().build();
    }
}
