package tn.esprit.communitymicroservice.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.communitymicroservice.entities.Post;

import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {
    // Méthode simple qui devrait fonctionner
    @Query("SELECT p FROM Post p WHERE p.group IS NOT NULL AND p.group.id = :groupId ORDER BY p.createdAt DESC")
    List<Post> findByGroupId(@Param("groupId") Long groupId);
    
    // Find posts by club ID
    @Query("SELECT p FROM Post p WHERE p.club IS NOT NULL AND p.club.id = :clubId ORDER BY p.createdAt DESC")
    List<Post> findByClubId(@Param("clubId") Long clubId);
    
    // Méthode alternative plus simple
    @Query("SELECT p FROM Post p ORDER BY p.createdAt DESC")
    List<Post> findAllOrderByCreatedAtDesc();
    
    // Méthode pour récupérer tous les posts sans condition
    @Query("SELECT p FROM Post p")
    List<Post> findAllPosts();
    
    // Delete posts by group ID
    @Modifying
    @Transactional
    @Query("DELETE FROM Post p WHERE p.group.id = :groupId")
    void deleteByGroupId(@Param("groupId") Long groupId);
}
