package org.example.ms_competenceandreview.services;

import org.example.ms_competenceandreview.Entities.Review;
import org.example.ms_competenceandreview.Repositories.ReviewRepo;
import org.example.ms_competenceandreview.Services.Impl.ReviewServiceImpl;
import org.example.ms_competenceandreview.Feign.UserClient;
import org.example.ms_competenceandreview.ai.GeminiClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReviewServiceImplTest {

    @Mock
    private ReviewRepo reviewRepo;

    @Mock
    private UserClient userClient; // Mocking Feign

    @Mock
    private GeminiClient gemini; // not configured: moderation is skipped

    @InjectMocks
    private ReviewServiceImpl reviewService;

    private Review testReview;

    @BeforeEach
    void setUp() {
        testReview = new Review();
        testReview.setId(1L);
        testReview.setDescription("Great work");
        testReview.setRating(5);
        testReview.setProjectId(100L);
    }

    @Test
    void testAjouterReview() {
        // Arrange
        when(reviewRepo.save(any(Review.class))).thenReturn(testReview);

        // Act
        Review result = reviewService.AjouterReview(testReview);

        // Assert
        assertNotNull(result);
        assertEquals("Great work", result.getDescription());
        verify(reviewRepo, times(1)).save(testReview);
    }

    @Test
    void testGetReviewById() {
        // Arrange
        when(reviewRepo.findById(1L)).thenReturn(Optional.of(testReview));

        // Act
        Review result = reviewService.GetReview(1L);

        // Assert
        assertNotNull(result);
        assertEquals(1L, result.getId());
    }
}
