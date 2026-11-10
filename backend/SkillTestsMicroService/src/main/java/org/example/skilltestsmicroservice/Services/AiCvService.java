package org.example.skilltestsmicroservice.Services;

import com.fasterxml.jackson.databind.JsonNode;
import org.example.skilltestsmicroservice.ai.GeminiClient;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI CV assistant (Premium): Gemini analyses a CV, as text or as an image, and rewrites it for a target domain.
 * Without AI, {@link org.example.skilltestsmicroservice.ai.AiUnavailableException} explains why (HTTP 503):
 * no rule-based imitation presented as AI.
 */
@Service
public class AiCvService {

    private final GeminiClient gemini;

    public AiCvService(GeminiClient gemini) {
        this.gemini = gemini;
    }

    public Map<String, Object> analyzeAndImproveCV(String cvText, String targetDomain) {
        return toResult(gemini.generateJson(buildPrompt(cvText, targetDomain)));
    }

    public Map<String, Object> analyzeAndImproveCVFromImage(String imageBase64, String mimeType, String targetDomain) {
        return toResult(gemini.generateJson(buildImagePrompt(targetDomain), imageBase64, mimeType));
    }

    private static final String ANSWER_FORMAT = """
            Answer with this JSON object only:
            {
              "improvedCV": "the complete improved CV, professional and ATS-friendly, with keywords for the domain",
              "suggestions": ["5 to 7 specific suggestions"],
              "missingSkills": ["3 to 5 skills that would strengthen this CV for the domain"],
              "strengthAreas": ["3 to 5 current strengths"],
              "summary": "2 or 3 sentences on what you improved"
            }
            Use action verbs and measurable achievements, keep the CV's language, and never invent
            experience, diplomas or companies the CV doesn't mention.
            """;

    private String buildPrompt(String cvText, String targetDomain) {
        return """
                You are an expert CV consultant for freelancers. Improve the CV below for the domain "%s":
                find its strengths and weaknesses, rewrite it professionally, and suggest skills to add.

                CV:
                %s

                %s""".formatted(targetDomain, cvText, ANSWER_FORMAT);
    }

    private String buildImagePrompt(String targetDomain) {
        return """
                You are an expert CV consultant for freelancers. The image is a CV: read all its text,
                then improve it for the domain "%s": find its strengths and weaknesses, rewrite it
                professionally, and suggest skills to add.

                %s""".formatted(targetDomain, ANSWER_FORMAT);
    }

    private static Map<String, Object> toResult(JsonNode json) {
        Map<String, Object> result = new HashMap<>();
        result.put("improvedCV", json.path("improvedCV").asText(""));
        result.put("suggestions", list(json.path("suggestions")));
        result.put("missingSkills", list(json.path("missingSkills")));
        result.put("strengthAreas", list(json.path("strengthAreas")));
        result.put("summary", json.path("summary").asText(""));
        return result;
    }

    private static List<String> list(JsonNode node) {
        List<String> values = new ArrayList<>();
        if (node.isArray()) node.forEach(item -> values.add(item.asText()));
        return values;
    }
}
