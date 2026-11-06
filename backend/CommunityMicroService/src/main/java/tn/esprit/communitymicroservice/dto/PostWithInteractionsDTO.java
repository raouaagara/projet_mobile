package tn.esprit.communitymicroservice.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import tn.esprit.communitymicroservice.entities.Post;
import tn.esprit.communitymicroservice.entities.ReactionType;

import java.util.Map;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PostWithInteractionsDTO {
    private Post post;
    private long commentsCount;
    private Map<ReactionType, Long> reactionCounts;
    private ReactionType userReaction;
    private long totalReactions;

    public PostWithInteractionsDTO(Post post, long commentsCount, Map<ReactionType, Long> reactionCounts) {
        this.post = post;
        this.commentsCount = commentsCount;
        this.reactionCounts = reactionCounts;
        this.totalReactions = reactionCounts.values().stream().mapToLong(Long::longValue).sum();
    }
}