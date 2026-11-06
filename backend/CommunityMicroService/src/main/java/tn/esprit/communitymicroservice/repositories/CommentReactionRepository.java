package tn.esprit.communitymicroservice.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import tn.esprit.communitymicroservice.entities.CommentReaction;
import tn.esprit.communitymicroservice.entities.ReactionType;

import java.util.List;
import java.util.Optional;

@Repository
public interface CommentReactionRepository extends JpaRepository<CommentReaction, Long> {
    
    Optional<CommentReaction> findByCommentIdAndAuthorId(Long commentId, Long authorId);
    
    @Query("SELECT r.type, COUNT(r) FROM CommentReaction r WHERE r.comment.id = :commentId GROUP BY r.type")
    List<Object[]> countReactionsByCommentId(@Param("commentId") Long commentId);
    
    void deleteByCommentId(Long commentId);
}
