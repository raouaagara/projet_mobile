package tn.esprit.communitymicroservice.services;

import tn.esprit.communitymicroservice.ai.ContentModerator;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import tn.esprit.communitymicroservice.entities.Comment;
import tn.esprit.communitymicroservice.entities.Post;
import tn.esprit.communitymicroservice.repositories.CommentRepository;
import tn.esprit.communitymicroservice.repositories.PostRepository;

import java.util.List;

@Service
public class CommentService {
    /** Checks the text by meaning before it is published (AI, fails open). */
    @Autowired
    private ContentModerator moderator;


    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private PostRepository postRepository;

    public Comment addComment(Long postId, Long authorId, String content) {
        moderator.requireAllowed(content);
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));

        Comment comment = new Comment();
        comment.setPost(post);
        comment.setAuthorId(authorId);
        comment.setContent(content);

        return commentRepository.save(comment);
    }

    public List<Comment> getCommentsByPost(Long postId) {
        return commentRepository.findByPostIdOrderByCreatedAtAsc(postId);
    }

    public long getCommentsCount(Long postId) {
        return commentRepository.countByPostId(postId);
    }

    public void deleteComment(Long commentId) {
        commentRepository.deleteById(commentId);
    }

    public Comment updateComment(Long commentId, String content) {
        moderator.requireAllowed(content);
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new RuntimeException("Comment not found"));
        
        comment.setContent(content);
        return commentRepository.save(comment);
    }
}