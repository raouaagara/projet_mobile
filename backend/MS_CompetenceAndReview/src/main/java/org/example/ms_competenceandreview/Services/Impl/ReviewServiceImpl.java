package org.example.ms_competenceandreview.Services.Impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.ms_competenceandreview.DTO.UserDTO;
import org.example.ms_competenceandreview.Entities.Review;
import org.example.ms_competenceandreview.ai.AiUnavailableException;
import org.example.ms_competenceandreview.ai.GeminiClient;
import org.example.ms_competenceandreview.Repositories.ReviewRepo;
import org.example.ms_competenceandreview.Services.Interface.ReviewService;
import org.example.ms_competenceandreview.Feign.UserClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;


@Service
public class ReviewServiceImpl implements ReviewService {
    @Autowired
    ReviewRepo reviewRepo;

    @Autowired
    GeminiClient gemini;

    @Override
    public Review AjouterReview(Review review) {
        if (review.getDescription() != null && !review.getDescription().isBlank()) {

            if (containsBadWords(review.getDescription())) {
                throw new IllegalArgumentException("REJECTED: Your review contains inappropriate language.");
            }

        }

        if (review.getCreatedAt() == null) {
            review.setCreatedAt(java.time.LocalDateTime.now());
        }
        return reviewRepo.save(review);
    }


    /** Modération par Gemini. Sans IA (pas de clé, ou panne), l'avis est publié : l'IA ne bloque jamais un avis. */
    private boolean containsBadWords(String text) {
        if (!gemini.isConfigured()) {
            System.err.println("⚠️ [MODERATION] GEMINI_API_KEY non définie : modération ignorée.");
            return false;
        }
        try {
            return gemini.generateJson("""
                    You moderate reviews on Workify, a freelancing platform.
                    Does this review contain insults, profanity, hate speech, threats or spam?
                    Criticism of the work, even harsh, is allowed.
                    Answer with this JSON object only: {"inappropriate": true or false}

                    Review: %s
                    """.formatted(text)).path("inappropriate").asBoolean(false);
        } catch (AiUnavailableException e) {
            System.err.println("⚠️ [MODERATION] Gemini indisponible, avis accepté sans modération : " + e.getMessage());
            return false;
        }
    }


    /** "Improve with AI" : Gemini réécrit le brouillon. Sans IA, AiUnavailableException explique pourquoi (503). */
    @Override
    public String generateEnhancedText(String originalText, Integer rating) {
        String ratingContext = switch (rating == null ? 3 : Math.max(1, Math.min(5, rating))) {
            case 5 -> "very satisfied (5/5 stars)";
            case 4 -> "satisfied (4/5 stars)";
            case 3 -> "neutral (3/5 stars)";
            case 2 -> "dissatisfied (2/5 stars)";
            default -> "very dissatisfied (1/5 stars)";
        };
        return gemini.generate("""
                You are a review assistant for Workify, a freelancing platform that connects clients with
                freelancers (web and mobile development, design, marketing, data...).
                A %s user wrote this review draft:
                "%s"

                Rewrite it as a clear, professional review, using ONLY what the draft says:
                - keep its opinion, sentiment and every fact;
                - add nothing: no new praise, criticism, detail, wish or recommendation
                  (for example, don't add "would work together again" or remarks on communication
                  unless the draft says so);
                - keep technical terms (React, API, UI/UX, deadline...);
                - same language as the draft (French or English), no marketing tone;
                - as long as the draft needs: a short draft gives one or two sentences.
                Answer with the review text only.
                """.formatted(ratingContext, originalText));
    }

    @Override
    public List<Review> GetReviewsByProject(Long projectId) {
        List<Review> reviews = reviewRepo.findByProjectId(projectId);

        for (Review review : reviews) {
            try {
                // 🟢 FIX: Use freelancerId for FREELANCER reviews, clientId for CLIENT reviews
                String idToResolve = "FREELANCER".equalsIgnoreCase(review.getReviewerRole())
                        ? review.getFreelancerId()
                        : review.getClientId();

                if (idToResolve != null) {
                    Long userId = Long.parseLong(idToResolve);
                    UserDTO user = userClient.getUserById(userId);

                    if (user != null) {
                        String fullName = (user.getFirstName() != null ? user.getFirstName() : "")
                                + " "
                                + (user.getLastName() != null ? user.getLastName() : "");
                        review.setReviewerName(fullName.trim());
                    }
                }
            } catch (Exception e) {
                System.err.println("Feign error for review " + review.getId() + ": " + e.getMessage());
                review.setReviewerName("Unknown User");
            }
        }
        return reviews;
    }


    @Override
    public List<Review> GetReviewsByFreelancer(String freelancerId) {
        return reviewRepo.findByFreelancerId(freelancerId);
    }

    @Override
    public List<Review> GetReviewsByClient(String clientId) {
        return reviewRepo.findByClientId(clientId);
    }

    @Override
    public Review ModifierReview(Review review) {
        return reviewRepo.save(review);
    }

    @Override
    public void SupprimerReview(Long id) {
        reviewRepo.deleteById(id);

    }

    @Override
    public Review GetReview(Long id) {
        return reviewRepo.findById(id).orElseThrow();
    }

    @Override
    public List<Review> GetAllReview() {
        return reviewRepo.findAll();
    }


    @Autowired
    private UserClient userClient;


}
