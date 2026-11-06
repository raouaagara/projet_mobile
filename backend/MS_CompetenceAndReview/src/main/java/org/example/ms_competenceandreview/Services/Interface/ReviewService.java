package org.example.ms_competenceandreview.Services.Interface;

import org.example.ms_competenceandreview.Entities.Competance;
import org.example.ms_competenceandreview.Entities.Review;

import java.util.List;

public interface ReviewService {
    Review AjouterReview(Review review);
    Review ModifierReview(Review review);
    void SupprimerReview(Long id);
    Review GetReview(Long id);
    List<Review> GetAllReview();
    List<Review> GetReviewsByFreelancer(String freelancerId);
    List<Review> GetReviewsByClient(String clientId);

    String generateEnhancedText(String originalText, Integer rating);
    List<Review> GetReviewsByProject(Long projectId); // 🟢 Add this
}
