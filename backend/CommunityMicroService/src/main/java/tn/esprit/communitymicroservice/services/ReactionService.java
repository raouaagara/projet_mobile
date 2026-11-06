package tn.esprit.communitymicroservice.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import tn.esprit.communitymicroservice.entities.Post;
import tn.esprit.communitymicroservice.entities.Reaction;
import tn.esprit.communitymicroservice.entities.ReactionType;
import tn.esprit.communitymicroservice.repositories.PostRepository;
import tn.esprit.communitymicroservice.repositories.ReactionRepository;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class ReactionService {

    @Autowired
    private ReactionRepository reactionRepository;

    @Autowired
    private PostRepository postRepository;

    public Reaction addOrUpdateReaction(Long postId, Long authorId, ReactionType type) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        Optional<Reaction> existingReaction = reactionRepository.findByPostIdAndAuthorId(postId, authorId);

        if (existingReaction.isPresent()) {
            Reaction reaction = existingReaction.get();
            if (reaction.getType() == type) {
                // Si c'est la même réaction, on la supprime (toggle)
                reactionRepository.delete(reaction);
                return null;
            } else {
                // Sinon on met à jour le type
                reaction.setType(type);
                return reactionRepository.save(reaction);
            }
        } else {
            // Nouvelle réaction
            Reaction reaction = new Reaction();
            reaction.setPost(post);
            reaction.setAuthorId(authorId);
            reaction.setType(type);
            return reactionRepository.save(reaction);
        }
    }

    public Map<ReactionType, Long> getReactionCounts(Long postId) {
        List<Object[]> results = reactionRepository.countReactionsByPostId(postId);
        Map<ReactionType, Long> counts = new HashMap<>();
        
        // Initialiser tous les types à 0
        for (ReactionType type : ReactionType.values()) {
            counts.put(type, 0L);
        }
        
        // Remplir avec les vraies valeurs
        for (Object[] result : results) {
            ReactionType type = (ReactionType) result[0];
            Long count = (Long) result[1];
            counts.put(type, count);
        }
        
        return counts;
    }

    public Optional<ReactionType> getUserReaction(Long postId, Long authorId) {
        Optional<Reaction> reaction = reactionRepository.findByPostIdAndAuthorId(postId, authorId);
        return reaction.map(Reaction::getType);
    }

    public void removeReaction(Long postId, Long authorId) {
        Optional<Reaction> reaction = reactionRepository.findByPostIdAndAuthorId(postId, authorId);
        reaction.ifPresent(reactionRepository::delete);
    }
}