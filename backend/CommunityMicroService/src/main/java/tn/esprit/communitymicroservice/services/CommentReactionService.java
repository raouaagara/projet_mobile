package tn.esprit.communitymicroservice.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.communitymicroservice.entities.Comment;
import tn.esprit.communitymicroservice.entities.CommentReaction;
import tn.esprit.communitymicroservice.entities.ReactionType;
import tn.esprit.communitymicroservice.repositories.CommentReactionRepository;
import tn.esprit.communitymicroservice.repositories.CommentRepository;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class CommentReactionService {

    @Autowired
    private CommentReactionRepository commentReactionRepository;

    @Autowired
    private CommentRepository commentRepository;

    @Transactional
    public CommentReaction addOrUpdateReaction(Long commentId, Long authorId, ReactionType type) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new RuntimeException("Comment not found"));

        Optional<CommentReaction> existingReaction = commentReactionRepository.findByCommentIdAndAuthorId(commentId, authorId);

        if (existingReaction.isPresent()) {
            CommentReaction reaction = existingReaction.get();
            if (reaction.getType() == type) {
                // Toggle off - remove reaction
                commentReactionRepository.delete(reaction);
                return null;
            } else {
                // Update reaction type
                reaction.setType(type);
                return commentReactionRepository.save(reaction);
            }
        } else {
            // New reaction
            CommentReaction reaction = new CommentReaction();
            reaction.setComment(comment);
            reaction.setAuthorId(authorId);
            reaction.setType(type);
            return commentReactionRepository.save(reaction);
        }
    }

    public Map<ReactionType, Long> getReactionCounts(Long commentId) {
        List<Object[]> results = commentReactionRepository.countReactionsByCommentId(commentId);
        Map<ReactionType, Long> counts = new HashMap<>();
        
        // Initialize all types to 0
        for (ReactionType type : ReactionType.values()) {
            counts.put(type, 0L);
        }
        
        // Fill with actual values
        for (Object[] result : results) {
            ReactionType type = (ReactionType) result[0];
            Long count = (Long) result[1];
            counts.put(type, count);
        }
        
        return counts;
    }

    public Optional<ReactionType> getUserReaction(Long commentId, Long authorId) {
        Optional<CommentReaction> reaction = commentReactionRepository.findByCommentIdAndAuthorId(commentId, authorId);
        return reaction.map(CommentReaction::getType);
    }

    @Transactional
    public void removeReaction(Long commentId, Long authorId) {
        Optional<CommentReaction> reaction = commentReactionRepository.findByCommentIdAndAuthorId(commentId, authorId);
        reaction.ifPresent(commentReactionRepository::delete);
    }
}
