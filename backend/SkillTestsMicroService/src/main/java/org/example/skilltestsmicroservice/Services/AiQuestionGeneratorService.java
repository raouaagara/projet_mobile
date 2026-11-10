package org.example.skilltestsmicroservice.Services;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.skilltestsmicroservice.DTO.QuestionDTO;
import org.example.skilltestsmicroservice.ai.AiUnavailableException;
import org.example.skilltestsmicroservice.ai.GeminiClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class AiQuestionGeneratorService {

    /** gemini (default) or openai. */
    @Value("${ai.provider:gemini}")
    private String aiProvider;

    @Value("${ai.openai.api-key:}")
    private String openaiApiKey;

    private final WebClient.Builder webClientBuilder;
    private final KnowledgeBaseService knowledgeBase;
    private final GeminiClient gemini;

    @Autowired
    public AiQuestionGeneratorService(WebClient.Builder webClientBuilder, KnowledgeBaseService knowledgeBase,
                                      GeminiClient gemini) {
        this.webClientBuilder = webClientBuilder;
        this.knowledgeBase = knowledgeBase;
        this.gemini = gemini;
    }

    // Built-in questions: their keys are the categories offered for AI tests.
    private static final Map<String, List<QuestionDTO>> TEMPLATE_QUESTIONS = Map.of(
            "Web Development", List.of(
                    createQ("What does NgModule do in Angular?", "Defines a compilation context", "Renders HTML", "Handles HTTP", "Manages state", "A"),
                    createQ("Which decorator defines a component?", "@Component", "@Module", "@Service", "@Directive", "A"),
                    createQ("What is RxJS used for?", "Reactive programming", "Routing", "Forms", "Testing", "A"),
                    createQ("What is the virtual DOM?", "A lightweight copy of the real DOM", "A type of database", "A routing mechanism", "A testing framework", "A"),
                    createQ("What does REST stand for?", "Representational State Transfer", "Reliable State Transfer", "Remote State Transfer", "Representational Service Transfer", "A"),
                    createQ("Which HTTP method is used for creating resources?", "POST", "GET", "PUT", "DELETE", "A"),
                    createQ("What is TypeScript?", "A typed superset of JavaScript", "A new programming language", "A database", "A framework", "A")
            ),
            "Design", List.of(
                    createQ("What does UX stand for?", "User Experience", "User Export", "Unified Experience", "User Extension", "A"),
                    createQ("Which tool is commonly used for prototyping?", "Figma", "Excel", "Word", "Photoshop", "A"),
                    createQ("What is the purpose of a wireframe?", "Layout and structure of a page", "Final visual design", "Color palette", "Animation timing", "A"),
                    createQ("What does 'above the fold' mean?", "Content visible without scrolling", "Header section", "Navigation menu", "Footer content", "A"),
                    createQ("What is accessibility in design?", "Design usable by people with disabilities", "Design for mobile only", "Design for developers", "Design for print", "A"),
                    createQ("What is a design system?", "A collection of reusable components and standards", "A single template", "A color palette only", "A font library", "A")
            ),
            "Marketing", List.of(
                    createQ("What is SEO?", "Search Engine Optimization", "Social Engagement Optimization", "System Error Override", "Standard Entry Option", "A"),
                    createQ("What does CTR stand for?", "Click-Through Rate", "Cost To Revenue", "Content Type Ratio", "Customer Trust Rating", "A"),
                    createQ("What is a funnel in marketing?", "The path from awareness to conversion", "A type of email", "A social media tool", "A budget model", "A"),
                    createQ("What is A/B testing?", "Comparing two versions to see which performs better", "Testing accessibility", "Backup testing", "API testing", "A"),
                    createQ("What does KPI stand for?", "Key Performance Indicator", "Key Process Input", "Knowledge Panel Index", "Keyword Performance Index", "A")
            ),
            "Data Science", List.of(
                    createQ("What is overfitting in ML?", "Model performs well on training but poorly on new data", "Too many features", "Underfitting", "Data leakage", "A"),
                    createQ("What does EDA stand for?", "Exploratory Data Analysis", "External Data Access", "Event Driven Architecture", "Error Detection Algorithm", "A"),
                    createQ("What is a confusion matrix?", "Table showing true vs predicted classifications", "A type of neural network", "A clustering method", "A regression metric", "A"),
                    createQ("What is cross-validation?", "Splitting data to evaluate model performance", "Data validation", "Feature scaling", "Model deployment", "A"),
                    createQ("What does API stand for in data?", "Application Programming Interface", "Automated Process Integration", "Advanced Predictive Index", "Analytic Performance Indicator", "A")
            ),
            "Mobile Development", List.of(
                    createQ("What is React Native?", "Framework for building mobile apps with React", "A React library for web", "A database", "A testing tool", "A"),
                    createQ("What is Flutter?", "Google's UI toolkit for cross-platform apps", "A web framework", "A database", "A cloud service", "A"),
                    createQ("What does APK stand for?", "Android Package Kit", "App Performance Kit", "Application Process Kernel", "Automated Program Key", "A"),
                    createQ("What is an emulator?", "Software that mimics mobile device hardware", "A type of app", "A testing framework", "A deployment tool", "A"),
                    createQ("What is a native app?", "App built for a specific platform", "Web app", "Hybrid app", "Progressive web app", "A")
            )
    );

    private static QuestionDTO createQ(String q, String a, String b, String c, String d, String correct) {
        QuestionDTO dto = new QuestionDTO();
        dto.setQuestionText(q);
        dto.setOptionA(a);
        dto.setOptionB(b);
        dto.setOptionC(c);
        dto.setOptionD(d);
        dto.setCorrectOption(correct);
        return dto;
    }

    /**
     * Questions written by the AI (Gemini by default, OpenAI if chosen). When the AI can't answer,
     * AiUnavailableException explains why (HTTP 503) instead of serving built-in questions as "AI" ones.
     */
    public List<QuestionDTO> generateQuestions(String category, int count) {
        String knowledge = knowledgeBase.getKnowledgeForCategory(category);
        String prompt = buildPromptWithKnowledge(category, count, knowledge);
        List<QuestionDTO> questions;
        if ("openai".equalsIgnoreCase(aiProvider) && openaiApiKey != null && !openaiApiKey.isBlank()) {
            try {
                questions = generateWithOpenAI(prompt, count);
            } catch (Exception e) {
                System.err.println("⚠️ [AI TEST] OpenAI : " + e.getMessage());
                questions = List.of();
            }
        } else {
            questions = parseQuestions(gemini.generateJson(prompt), count);
        }
        if (questions.isEmpty()) {
            throw new AiUnavailableException("The AI couldn't write this test right now. Try again in a moment.");
        }
        return questions;
    }

    private String buildPromptWithKnowledge(String category, int count, String knowledge) {
        StringBuilder prompt = new StringBuilder();
        if (knowledge != null && !knowledge.isBlank()) {
            prompt.append("Use the following knowledge as the primary source for your questions:\n\n");
            prompt.append(knowledge);
            prompt.append("\n\nBased on this content, ");
        } else {
            prompt.append("Using your expertise, ");
        }
        prompt.append(String.format(
                "generate exactly %d multiple choice questions for the category: %s. " +
                "Each question must have exactly 4 options (A, B, C, D). " +
                "Return ONLY a valid JSON array of objects with these fields: questionText, optionA, optionB, optionC, optionD, correctOption (A, B, C or D). " +
                "No markdown, no code blocks, no explanation - only the JSON array.",
                count, category));
        return prompt.toString();
    }

    private List<QuestionDTO> generateWithOpenAI(String prompt, int count) throws Exception {

        WebClient client = webClientBuilder.build();
        String response = client.post()
                .uri("https://api.openai.com/v1/chat/completions")
                .header("Authorization", "Bearer " + openaiApiKey)
                .header("Content-Type", "application/json")
                .bodyValue(Map.of(
                        "model", "gpt-3.5-turbo",
                        "messages", List.of(Map.of("role", "user", "content", prompt)),
                        "temperature", 0.7
                ))
                .retrieve()
                .bodyToMono(String.class)
                .block();

        if (response == null) throw new RuntimeException("OpenAI returned null");

        String content = extractOpenAIContent(response);
        if (content == null) throw new RuntimeException("Could not parse OpenAI response");

        String cleaned = content.trim();
        if (cleaned.startsWith("```")) { // markdown code block around the JSON
            cleaned = cleaned.substring(cleaned.indexOf('\n') + 1, Math.max(cleaned.indexOf('\n') + 1, cleaned.lastIndexOf("```")));
        }
        return parseQuestions(new ObjectMapper().readTree(cleaned), count);
    }

    private String extractOpenAIContent(String json) {
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            Map<String, Object> root = mapper.readValue(json, Map.class);
            List<?> choices = (List<?>) root.get("choices");
            if (choices == null || choices.isEmpty()) return null;
            Map<String, Object> choice = (Map<String, Object>) choices.get(0);
            Map<String, Object> msg = (Map<String, Object>) choice.get("message");
            if (msg == null) return null;
            Object content = msg.get("content");
            return content != null ? content.toString() : null;
        } catch (Exception e) {
            return null;
        }
    }

    /** A JSON array of questions, or an object holding one under "questions". Invalid items are skipped. */
    private List<QuestionDTO> parseQuestions(JsonNode json, int maxCount) {
        JsonNode array = json.isArray() ? json : json.path("questions");
        List<QuestionDTO> result = new ArrayList<>();
        for (JsonNode item : array) {
            if (result.size() >= maxCount) break;
            String correct = item.path("correctOption").asText("").trim().toUpperCase();
            if (item.path("questionText").asText("").isBlank() || correct.isEmpty() || "ABCD".indexOf(correct.charAt(0)) < 0) {
                continue;
            }
            result.add(createQ(item.path("questionText").asText(), item.path("optionA").asText(), item.path("optionB").asText(),
                    item.path("optionC").asText(), item.path("optionD").asText(), correct.substring(0, 1)));
        }
        return result;
    }

    public List<String> getAvailableCategories() {
        return new ArrayList<>(TEMPLATE_QUESTIONS.keySet());
    }
}
