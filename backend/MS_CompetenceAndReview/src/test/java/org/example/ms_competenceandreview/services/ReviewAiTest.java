package org.example.ms_competenceandreview.services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.ms_competenceandreview.Entities.Review;
import org.example.ms_competenceandreview.Repositories.ReviewRepo;
import org.example.ms_competenceandreview.Services.Impl.ReviewServiceImpl;
import org.example.ms_competenceandreview.ai.AiUnavailableException;
import org.example.ms_competenceandreview.ai.GeminiClient;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/** Review moderation and "Improve with AI", with a fake Gemini (no network). */
class ReviewAiTest {

    private static GeminiClient answering(String answer) {
        return new GeminiClient("test-key", "test-model") {
            @Override
            public String generate(String prompt) {
                return answer;
            }

            @Override
            public JsonNode generateJson(String prompt) {
                try {
                    return new ObjectMapper().readTree(answer);
                } catch (Exception e) {
                    throw new IllegalStateException(e);
                }
            }
        };
    }

    private static ReviewServiceImpl service(GeminiClient gemini, ReviewRepo repo) {
        ReviewServiceImpl service = new ReviewServiceImpl();
        ReflectionTestUtils.setField(service, "gemini", gemini);
        ReflectionTestUtils.setField(service, "reviewRepo", repo);
        return service;
    }

    private static Review review(String text) {
        Review review = new Review();
        review.setDescription(text);
        review.setRating(1);
        return review;
    }

    @Test
    void insultingReview_isRejected() {
        ReviewRepo repo = mock(ReviewRepo.class);
        var service = service(answering("{\"inappropriate\": true}"), repo);
        assertThrows(IllegalArgumentException.class, () -> service.AjouterReview(review("you are an idiot")));
        verify(repo, never()).save(any());
    }

    @Test
    void harshButFairReview_isPublished() {
        ReviewRepo repo = mock(ReviewRepo.class);
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        var service = service(answering("{\"inappropriate\": false}"), repo);
        assertNotNull(service.AjouterReview(review("Late by two weeks and the app crashes.")));
    }

    @Test
    void withoutKey_reviewsArePublishedAndImproveSaysWhy() {
        ReviewRepo repo = mock(ReviewRepo.class);
        when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));
        var service = service(new GeminiClient("", "test-model"), repo);

        assertNotNull(service.AjouterReview(review("Good work")));
        var e = assertThrows(AiUnavailableException.class, () -> service.generateEnhancedText("good work", 4));
        assertTrue(e.getMessage().contains("GEMINI_API_KEY"));
    }

    @Test
    void improve_returnsGeminisRewrite() {
        var service = service(answering("Great collaboration: clean code delivered on time."), mock(ReviewRepo.class));
        assertEquals("Great collaboration: clean code delivered on time.", service.generateEnhancedText("good work", 5));
    }
}
