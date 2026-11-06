package org.example.ms_competenceandreview.Controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.ms_competenceandreview.Entities.Review;
import org.example.ms_competenceandreview.Services.Interface.ReviewService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(ReviewController.class)
class ReviewControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ReviewService reviewService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldReturnReviewsByProject() throws Exception {
        Review r = new Review();
        r.setDescription("Standardized Test Review");

        when(reviewService.GetReviewsByProject(1L))
                .thenReturn(Collections.singletonList(r));

        mockMvc.perform(get("/Review/GetReviewsByProject/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].description").value("Standardized Test Review"));
    }
}