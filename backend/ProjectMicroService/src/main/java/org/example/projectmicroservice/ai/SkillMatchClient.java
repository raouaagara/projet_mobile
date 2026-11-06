package org.example.projectmicroservice.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * Client du service Python "SkillExtractorAI" (backend/SkillExtractorAI) :
 * score de correspondance freelancer ↔ offres (/match) et compétences trouvées dans un texte (/extract/text).
 */
@Component
public class SkillMatchClient {

    public record Job(Long id, String text, List<String> requiredSkills) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Match(Long id, int score, List<String> matched, List<String> related, List<String> missing) {}

    public record CatalogSkill(Long id, String name) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record FoundSkill(Long id, String name, double confidence, String method) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Extraction(List<FoundSkill> skills) {}

    private final RestClient restClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public SkillMatchClient(@Value("${skill-extractor.url:http://localhost:8093}") String baseUrl) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(3));
        factory.setReadTimeout(Duration.ofSeconds(60));
        this.restClient = RestClient.builder().baseUrl(baseUrl).requestFactory(factory).build();
    }

    /** Scores each job for a freelancer who has the skills {@code profile}, in the same order. */
    public List<Match> match(List<String> profile, List<Job> jobs) {
        try {
            String json = post("/match", Map.of("profile", profile, "jobs", jobs));
            return Arrays.asList(objectMapper.readValue(json, Match[].class));
        } catch (Exception e) {
            System.err.println("⚠️ [MATCH-AI] " + e.getMessage());
            throw new AiUnavailableException("The matching AI is offline right now. Try again in a moment.");
        }
    }

    /** Catalog skills found in a text (exact names, aliases, and by meaning in French or English). */
    public List<FoundSkill> skillsIn(String text, List<CatalogSkill> catalog) {
        try {
            String json = post("/extract/text", Map.of("text", text, "catalog", catalog));
            Extraction extraction = objectMapper.readValue(json, Extraction.class);
            return extraction.skills() == null ? List.of() : extraction.skills();
        } catch (Exception e) {
            System.err.println("⚠️ [MATCH-AI] " + e.getMessage());
            throw new AiUnavailableException("The skills AI is offline right now. Try again in a moment.");
        }
    }

    private String post(String path, Object body) throws Exception {
        return restClient.post()
                .uri(path)
                .contentType(MediaType.APPLICATION_JSON)
                .body(objectMapper.writeValueAsString(body))
                .retrieve()
                .body(String.class);
    }
}
