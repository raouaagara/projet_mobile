package org.example.ms_competenceandreview.Services.Impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Catalogue de compétences par défaut : les 144 compétences que le service d'IA connaît, avec leur catégorie
 * (copie de backend/SkillExtractorAI/data/skills_lexicon.json dans resources/skills-catalog.json).
 */
@Component
public class DefaultSkillCatalog {

    public record Entry(String name, String category) {}

    private final List<Entry> entries;
    private final Map<String, String> categoryByName = new HashMap<>();

    public DefaultSkillCatalog() throws IOException {
        try (InputStream in = new ClassPathResource("skills-catalog.json").getInputStream()) {
            entries = List.of(new ObjectMapper().readValue(in, Entry[].class));
        }
        entries.forEach(e -> categoryByName.put(e.name().toLowerCase(Locale.ROOT), e.category()));
    }

    public List<Entry> entries() {
        return entries;
    }

    /** Catégorie d'une compétence connue de l'IA, sinon null. */
    public String categoryOf(String name) {
        return name == null ? null : categoryByName.get(name.toLowerCase(Locale.ROOT));
    }
}
