package org.example.projectmicroservice.OpenFeign;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.projectmicroservice.DTO.CompetenceDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.util.Arrays;
import java.util.List;

/**
 * Catalogue des compétences (module 1) : sert à lire le nom des compétences.
 * Appel direct par URL (COMPETENCE_URL) et lecture JSON avec notre ObjectMapper : un client Feign
 * échouait sur le Codespace.
 */
@Component
public class CompetenceClient {

    private final RestClient restClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public CompetenceClient(@Value("${competence.url:http://localhost:8084}") String baseUrl) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(3));
        factory.setReadTimeout(Duration.ofSeconds(20));
        this.restClient = RestClient.builder().baseUrl(baseUrl).requestFactory(factory).build();
    }

    public List<CompetenceDto> getAll() {
        String json = restClient.get().uri("/Competance/GetAllCompetance").retrieve().body(String.class);
        try {
            return Arrays.asList(objectMapper.readValue(json == null ? "[]" : json, CompetenceDto[].class));
        } catch (Exception e) {
            throw new IllegalStateException("Unreadable skills catalog: " + e.getMessage(), e);
        }
    }
}
