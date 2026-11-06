package org.example.ms_competenceandreview.Services.Impl;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.ms_competenceandreview.Entities.Competance;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * Client du service Python "SkillExtractorAI" (backend/SkillExtractorAI) :
 * extraction des compétences d'un CV PDF en français ou en anglais (lexique bilingue + modèle d'IA multilingue).
 */
@Component
public class SkillExtractorClient {

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ExtractedSkill(Long id, String name, double confidence, String method, String evidence) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record ExtractionResponse(String language, boolean semanticEnabled,
                                     List<ExtractedSkill> skills, List<String> otherSkills) {}

    private final RestClient restClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public SkillExtractorClient(@Value("${skill-extractor.url:http://localhost:8093}") String baseUrl) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(3));
        factory.setReadTimeout(Duration.ofSeconds(60));
        this.restClient = RestClient.builder().baseUrl(baseUrl).requestFactory(factory).build();
    }

    /** Envoie le PDF et le catalogue ; renvoie les compétences trouvées, triées par confiance. */
    public ExtractionResponse extract(byte[] pdf, String fileName, List<Competance> catalog) throws Exception {
        String catalogJson = objectMapper.writeValueAsString(
                catalog.stream().map(c -> Map.of("id", c.getId(), "name", c.getNom())).toList());

        MultiValueMap<String, Object> form = new LinkedMultiValueMap<>();
        form.add("file", new ByteArrayResource(pdf) {
            @Override
            public String getFilename() {
                return fileName != null ? fileName : "cv.pdf";
            }
        });
        form.add("catalog", catalogJson);

        return restClient.post()
                .uri("/extract")
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(form)
                .retrieve()
                .body(ExtractionResponse.class);
    }
}
