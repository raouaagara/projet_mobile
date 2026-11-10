package org.example.skilltestsmicroservice.Services;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

/**
 * Loads category knowledge from JSON file. This data is passed to the AI
 * so it can generate questions grounded in real domain content.
 */
@Service
public class KnowledgeBaseService {

    private Map<String, String> knowledgeByCategory = new HashMap<>();

    @PostConstruct
    public void load() {
        try {
            ClassPathResource resource = new ClassPathResource("knowledge/category-knowledge.json");
            if (!resource.exists()) return;
            try (InputStream is = resource.getInputStream()) {
                ObjectMapper mapper = new ObjectMapper();
                knowledgeByCategory = mapper.readValue(is, new TypeReference<>() {});
            }
        } catch (Exception e) {
            // Fallback empty - AI will use general knowledge
        }
    }

    public String getKnowledgeForCategory(String category) {
        return knowledgeByCategory.getOrDefault(category, "");
    }
}
