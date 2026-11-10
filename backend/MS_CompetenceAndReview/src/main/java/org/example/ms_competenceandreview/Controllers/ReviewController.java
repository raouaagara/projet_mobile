package org.example.ms_competenceandreview.Controllers;


import org.example.ms_competenceandreview.Entities.Review;

import org.example.ms_competenceandreview.Services.Interface.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.List;
import java.util.Map;


@RestController
@RequestMapping("/Review")
public class ReviewController {

    @Autowired
    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @PostMapping("/enhance")
    public Map<String, String> enhanceReview(@RequestBody Map<String, Object> payload) {
        String text = (String) payload.get("text");
        // Handle cases where rating might be passed as Integer or Double from JS
        Integer rating = Integer.parseInt(payload.get("rating").toString());

        String enhanced = reviewService.generateEnhancedText(text, rating);
        return Collections.singletonMap("enhancedText", enhanced);
    }

    @GetMapping("/GetReviewsByProject/{id}")
    public List<Review> GetReviewsByProject(@PathVariable Long id) {
        return reviewService.GetReviewsByProject(id);
    }

    @PostMapping("/AjouterReview")
    public ResponseEntity<?> AjouterReview(@RequestBody Review a) {
        try {
            if (a.getCreatedAt() == null) a.setCreatedAt(java.time.LocalDateTime.now());
            Review saved = reviewService.AjouterReview(a);
            return ResponseEntity.ok(saved);

        } catch (IllegalArgumentException e) {
            // 🚫 Rejected by AI moderation — tell the frontend why
            String reason = e.getMessage().replace("REJECTED: ", "");
            return ResponseEntity.badRequest().body(
                    Map.of("error", "Your review was rejected by our moderation system.", "reason", reason)
            );
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(
                    Map.of("error", "An unexpected error occurred.")
            );
        }
    }

    @PutMapping("/ModifierReview")
    public Review ModifierReview(@RequestBody Review a) {
        return reviewService.ModifierReview(a);
    }


    @DeleteMapping("/SupprimerReview/{id}")
    public void SupprimerReview(@PathVariable Long id) {
        reviewService.SupprimerReview(id);
    }
    @GetMapping("/GetReview/{id}")
    public Review GetReview(@PathVariable Long id) {
        return reviewService.GetReview(id);
    }
    @GetMapping("/GetAllReview")
    public List<Review> GetAllReview() {
        return reviewService.GetAllReview();
    }
    @GetMapping("/GetReviewsByFreelancer/{id}")
    public List<Review> GetReviewsByFreelancer(@PathVariable String id) {
        return reviewService.GetReviewsByFreelancer(id);
    }


    @GetMapping("/GetReviewsByClient/{id}")
    public List<Review> GetReviewsByClient(@PathVariable String id) {
        return reviewService.GetReviewsByClient(id);
    }
}