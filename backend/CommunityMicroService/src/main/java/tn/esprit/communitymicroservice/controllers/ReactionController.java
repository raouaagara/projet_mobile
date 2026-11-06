package tn.esprit.communitymicroservice.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.communitymicroservice.entities.Reaction;
import tn.esprit.communitymicroservice.entities.ReactionType;
import tn.esprit.communitymicroservice.services.ReactionService;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/reactions")
@CrossOrigin(origins = "*")
public class ReactionController {

    @Autowired
    private ReactionService reactionService;

    @PostMapping
    public ResponseEntity<Reaction> addOrUpdateReaction(@RequestBody Map<String, Object> request) {
        Long postId = Long.valueOf(request.get("postId").toString());
        Long authorId = Long.valueOf(request.get("authorId").toString());
        ReactionType type = ReactionType.valueOf(request.get("type").toString());

        Reaction reaction = reactionService.addOrUpdateReaction(postId, authorId, type);
        return ResponseEntity.ok(reaction);
    }

    @GetMapping("/post/{postId}/counts")
    public ResponseEntity<Map<ReactionType, Long>> getReactionCounts(@PathVariable Long postId) {
        Map<ReactionType, Long> counts = reactionService.getReactionCounts(postId);
        return ResponseEntity.ok(counts);
    }

    @GetMapping("/post/{postId}/user/{authorId}")
    public ResponseEntity<Map<String, Object>> getUserReaction(
            @PathVariable Long postId, 
            @PathVariable Long authorId) {
        Optional<ReactionType> userReaction = reactionService.getUserReaction(postId, authorId);
        Map<String, Object> response = new java.util.HashMap<>();
        response.put("hasReaction", userReaction.isPresent());
        response.put("reactionType", userReaction.orElse(null));
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/post/{postId}/user/{authorId}")
    public ResponseEntity<Void> removeReaction(
            @PathVariable Long postId, 
            @PathVariable Long authorId) {
        reactionService.removeReaction(postId, authorId);
        return ResponseEntity.ok().build();
    }
}