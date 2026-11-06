package org.example.skilltestsmicroservice;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.skilltestsmicroservice.DTO.QuestionDTO;
import org.example.skilltestsmicroservice.Services.AiCvService;
import org.example.skilltestsmicroservice.Services.AiQuestionGeneratorService;
import org.example.skilltestsmicroservice.Services.KnowledgeBaseService;
import org.example.skilltestsmicroservice.ai.AiUnavailableException;
import org.example.skilltestsmicroservice.ai.GeminiClient;
import org.junit.jupiter.api.Test;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

/** AI tests and the AI CV assistant, with a fake Gemini (no network). */
class AiFeaturesTest {

    private static final GeminiClient NO_KEY = new GeminiClient("", "test-model");

    private static GeminiClient answering(String json) {
        return new GeminiClient("test-key", "test-model") {
            @Override
            public JsonNode generateJson(String prompt) {
                return read(json);
            }

            @Override
            public JsonNode generateJson(String prompt, String imageBase64, String mimeType) {
                return read(json);
            }

            private JsonNode read(String text) {
                try {
                    return new ObjectMapper().readTree(text);
                } catch (Exception e) {
                    throw new IllegalStateException(e);
                }
            }
        };
    }

    private static AiQuestionGeneratorService generator(GeminiClient gemini) {
        return new AiQuestionGeneratorService(WebClient.builder(), mock(KnowledgeBaseService.class), gemini);
    }

    @Test
    void questions_comeFromGemini_andInvalidOnesAreSkipped() {
        List<QuestionDTO> questions = generator(answering("""
                [
                  {"questionText": "What is a Widget in Flutter?", "optionA": "A UI building block", "optionB": "A database",
                   "optionC": "A server", "optionD": "A test", "correctOption": "a"},
                  {"questionText": "", "optionA": "x", "optionB": "y", "optionC": "z", "optionD": "w", "correctOption": "A"},
                  {"questionText": "Which tool builds an APK?", "optionA": "npm", "optionB": "flutter build apk",
                   "optionC": "pip", "optionD": "maven", "correctOption": "Z"}
                ]
                """)).generateQuestions("Mobile Development", 10);

        assertEquals(1, questions.size());
        assertEquals("What is a Widget in Flutter?", questions.get(0).getQuestionText());
        assertEquals("A", questions.get(0).getCorrectOption());
    }

    @Test
    void questions_wrappedInAnObject_areRead() {
        List<QuestionDTO> questions = generator(answering("""
                {"questions": [{"questionText": "Q?", "optionA": "a", "optionB": "b", "optionC": "c", "optionD": "d", "correctOption": "B"}]}
                """)).generateQuestions("Web Development", 5);
        assertEquals("B", questions.get(0).getCorrectOption());
    }

    @Test
    void questions_withoutKeyOrWithoutUsableAnswer_sayWhy() {
        var noKey = assertThrows(AiUnavailableException.class, () -> generator(NO_KEY).generateQuestions("Web Development", 5));
        assertTrue(noKey.getMessage().contains("GEMINI_API_KEY"));
        assertThrows(AiUnavailableException.class, () -> generator(answering("[]")).generateQuestions("Web Development", 5));
    }

    @Test
    void cvAssistant_returnsTheFieldsTheAppReads() {
        Map<String, Object> result = new AiCvService(answering("""
                {"improvedCV": "Ghassen H. - Flutter developer", "suggestions": ["Add metrics"],
                 "missingSkills": ["Firebase"], "strengthAreas": ["Flutter"], "summary": "Clearer and more focused."}
                """)).analyzeAndImproveCV("my cv", "Mobile Development");

        assertEquals("Ghassen H. - Flutter developer", result.get("improvedCV"));
        assertEquals(List.of("Add metrics"), result.get("suggestions"));
        assertEquals(List.of("Firebase"), result.get("missingSkills"));
        assertEquals(List.of("Flutter"), result.get("strengthAreas"));
        assertEquals("Clearer and more focused.", result.get("summary"));
    }

    @Test
    void cvAssistant_withoutKey_saysWhyInsteadOfAFakeResult() {
        var service = new AiCvService(NO_KEY);
        assertThrows(AiUnavailableException.class, () -> service.analyzeAndImproveCV("my cv", "Mobile Development"));
        assertThrows(AiUnavailableException.class, () -> service.analyzeAndImproveCVFromImage("aGk=", "image/png", "Web"));
    }
}
