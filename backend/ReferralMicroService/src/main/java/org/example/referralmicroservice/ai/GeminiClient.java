package org.example.referralmicroservice.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Appels à l'API Gemini (Google AI Studio). La clé vient de la variable d'environnement GEMINI_API_KEY,
 * jamais du code ; le modèle se change avec GEMINI_MODEL. Sans clé, ou si l'appel échoue,
 * lève {@link AiUnavailableException} avec un message lisible par l'utilisateur.
 */
@Component
public class GeminiClient {

    private final String apiKey;
    private final String model;
    private final RestClient restClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public GeminiClient(@Value("${gemini.api.key:}") String apiKey,
                        @Value("${gemini.model:gemini-3.5-flash-lite}") String model) {
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.model = model;
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(10));
        factory.setReadTimeout(Duration.ofSeconds(60));
        this.restClient = RestClient.builder()
                .baseUrl("https://generativelanguage.googleapis.com/v1beta")
                .requestFactory(factory)
                .build();
    }

    public boolean isConfigured() {
        return !apiKey.isEmpty();
    }

    /** Réponse en texte libre. */
    public String generate(String prompt) {
        return call(List.of(Map.of("text", prompt)), false);
    }

    /** Réponse en JSON (Gemini garantit un JSON valide). */
    public JsonNode generateJson(String prompt) {
        String text = call(List.of(Map.of("text", prompt)), true);
        try {
            return objectMapper.readTree(text);
        } catch (Exception e) {
            throw new AiUnavailableException("The AI gave an answer we couldn't read. Try again.");
        }
    }

    private String call(List<Map<String, Object>> parts, boolean json) {
        if (!isConfigured()) {
            throw new AiUnavailableException("AI isn't set up on the server yet (GEMINI_API_KEY is missing).");
        }
        Map<String, Object> body = new HashMap<>();
        body.put("contents", List.of(Map.of("role", "user", "parts", parts)));
        if (json) body.put("generationConfig", Map.of("responseMimeType", "application/json"));
        try {
            String response = restClient.post()
                    .uri("/models/{model}:generateContent", model)
                    .header("x-goog-api-key", apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(objectMapper.writeValueAsString(body))
                    .retrieve()
                    .body(String.class);
            String text = objectMapper.readTree(response == null ? "{}" : response)
                    .path("candidates").path(0).path("content").path("parts").path(0).path("text").asText("");
            if (text.isBlank()) throw new AiUnavailableException("The AI gave an empty answer. Try again.");
            return text.trim();
        } catch (RestClientResponseException e) {
            System.err.println("⚠️ [GEMINI] " + e.getStatusCode() + " : " + e.getResponseBodyAsString());
            throw new AiUnavailableException("The AI service refused the request (HTTP " + e.getStatusCode().value()
                    + "). Check GEMINI_API_KEY and GEMINI_MODEL on the server.");
        } catch (ResourceAccessException e) {
            throw new AiUnavailableException("The AI service can't be reached right now. Try again in a moment.");
        } catch (AiUnavailableException e) {
            throw e;
        } catch (Exception e) {
            System.err.println("⚠️ [GEMINI] " + e.getMessage());
            throw new AiUnavailableException("The AI request failed. Try again.");
        }
    }
}
