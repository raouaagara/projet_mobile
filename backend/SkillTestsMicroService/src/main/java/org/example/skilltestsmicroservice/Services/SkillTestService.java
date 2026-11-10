package org.example.skilltestsmicroservice.Services;

import org.example.skilltestsmicroservice.DTO.QuestionDTO;
import org.example.skilltestsmicroservice.Entities.Certification;
import org.example.skilltestsmicroservice.Entities.SkillTest;
import org.example.skilltestsmicroservice.Entities.TestQuestion;
import org.example.skilltestsmicroservice.Repositories.CertificationRepository;
import org.example.skilltestsmicroservice.Repositories.SkillTestRepository;
import org.example.skilltestsmicroservice.Repositories.TestQuestionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SkillTestService {

    private static final int AI_QUESTION_COUNT = 5;
    private static final int AI_PASS_SCORE = 70;
    private static final int AI_DURATION_MINUTES = 15;

    @Autowired
    private SkillTestRepository testRepo;

    @Autowired
    private TestQuestionRepository questionRepo;

    @Autowired
    private CertificationRepository certRepo;

    @Autowired
    private AiQuestionGeneratorService aiGenerator;

    public List<SkillTest> getAllTests() {
        return testRepo.findAll();
    }

    public List<SkillTest> getAllActiveTests() {
        return testRepo.findByActiveTrue();
    }

    public SkillTest getTestById(Long id) {
        return testRepo.findById(id).orElseThrow(() -> new RuntimeException("Test not found"));
    }

    public SkillTest createTest(SkillTest test) {
        return testRepo.save(test);
    }

    public SkillTest updateTest(Long id, SkillTest updates) {
        SkillTest existing = getTestById(id);
        if (updates.getTitle() != null) existing.setTitle(updates.getTitle());
        if (updates.getDescription() != null) existing.setDescription(updates.getDescription());
        if (updates.getCategory() != null) existing.setCategory(updates.getCategory());
        if (updates.getDurationMinutes() != null) existing.setDurationMinutes(updates.getDurationMinutes());
        if (updates.getPassScore() != null) existing.setPassScore(updates.getPassScore());
        if (updates.getActive() != null) existing.setActive(updates.getActive());
        return testRepo.save(existing);
    }

    public void deleteTest(Long id) {
        testRepo.deleteById(id);
    }

    public List<TestQuestion> getQuestionsForTest(Long testId) {
        return questionRepo.findBySkillTestId(testId);
    }

    public SkillTest generateAiTest(Long userId, String category, boolean hasAiAccess, String userName) {
        if (!hasAiAccess) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Premium or Enterprise subscription required for AI-generated tests.");
        }
        List<QuestionDTO> questions = aiGenerator.generateQuestions(category, AI_QUESTION_COUNT);

        SkillTest test = new SkillTest();
        test.setTitle(category + " - AI Generated Test");
        test.setDescription("AI-generated skill test for " + category);
        test.setCategory(category);
        test.setDurationMinutes(AI_DURATION_MINUTES);
        test.setPassScore(AI_PASS_SCORE);
        test.setActive(true);
        test = testRepo.save(test);

        for (QuestionDTO dto : questions) {
            TestQuestion q = new TestQuestion();
            q.setSkillTest(test);
            q.setQuestionText(dto.getQuestionText());
            q.setOptionA(dto.getOptionA());
            q.setOptionB(dto.getOptionB());
            q.setOptionC(dto.getOptionC());
            q.setOptionD(dto.getOptionD());
            q.setCorrectOption(dto.getCorrectOption());
            questionRepo.save(q);
        }
        return test;
    }

    public List<String> getAvailableCategories() {
        return aiGenerator.getAvailableCategories();
    }

    public Certification submitTest(Long userId, Long testId, Map<String, String> answers) {
        return submitTest(userId, testId, answers, null);
    }

    public Certification submitTest(Long userId, Long testId, Map<String, String> answers, String userName) {
        SkillTest test = getTestById(testId);
        List<TestQuestion> questions = getQuestionsForTest(testId);

        int correct = 0;
        for (TestQuestion q : questions) {
            String userAnswer = answers.get(String.valueOf(q.getId()));
            if (userAnswer != null && userAnswer.equalsIgnoreCase(q.getCorrectOption())) {
                correct++;
            }
        }

        int score = questions.isEmpty() ? 0 : (correct * 100) / questions.size();
        boolean passed = score >= test.getPassScore();

        Certification cert = new Certification();
        cert.setUserId(userId);
        cert.setUserName(userName);
        cert.setSkillTest(test);
        cert.setTestTitle(test.getTitle());
        cert.setCategory(test.getCategory());
        cert.setScore(score);
        cert.setPassed(passed);

        return certRepo.save(cert);
    }

    public List<Certification> getUserCertifications(Long userId) {
        return certRepo.findByUserId(userId);
    }

    public List<Certification> getAllCertifications() {
        return certRepo.findAll();
    }

    public List<Certification> getPassedCertifications() {
        return certRepo.findAll().stream().filter(Certification::getPassed).collect(Collectors.toList());
    }

    public Map<String, Long> getStatsByCategory() {
        return certRepo.findAll().stream()
                .filter(Certification::getPassed)
                .collect(Collectors.groupingBy(c -> c.getCategory() != null ? c.getCategory() : "Other", Collectors.counting()));
    }

    public Certification getCertificationById(Long id) {
        return certRepo.findById(id).orElseThrow(() -> new RuntimeException("Certification not found"));
    }

    public void deleteCertification(Long id) {
        certRepo.deleteById(id);
    }

    public TestQuestion getQuestionById(Long id) {
        return questionRepo.findById(id).orElseThrow(() -> new RuntimeException("Question not found"));
    }

    public TestQuestion createQuestion(Long testId, TestQuestion question) {
        SkillTest test = getTestById(testId);
        question.setSkillTest(test);
        return questionRepo.save(question);
    }

    public TestQuestion updateQuestion(Long id, TestQuestion updates) {
        TestQuestion existing = getQuestionById(id);
        if (updates.getQuestionText() != null) existing.setQuestionText(updates.getQuestionText());
        if (updates.getOptionA() != null) existing.setOptionA(updates.getOptionA());
        if (updates.getOptionB() != null) existing.setOptionB(updates.getOptionB());
        if (updates.getOptionC() != null) existing.setOptionC(updates.getOptionC());
        if (updates.getOptionD() != null) existing.setOptionD(updates.getOptionD());
        if (updates.getCorrectOption() != null) existing.setCorrectOption(updates.getCorrectOption());
        return questionRepo.save(existing);
    }

    public void deleteQuestion(Long id) {
        questionRepo.deleteById(id);
    }

    public Map<String, Object> getTestStatistics(Long testId) {
        SkillTest test = getTestById(testId);
        List<Certification> attempts = certRepo.findAll().stream()
                .filter(c -> c.getSkillTest() != null && c.getSkillTest().getId().equals(testId))
                .collect(Collectors.toList());

        int totalAttempts = attempts.size();
        double averageScore = attempts.isEmpty() ? 0 : 
            attempts.stream().mapToInt(Certification::getScore).average().orElse(0);
        long passedCount = attempts.stream().filter(Certification::getPassed).count();
        double passRate = totalAttempts == 0 ? 0 : (passedCount * 100.0) / totalAttempts;

        // Calculate most failed questions (questions with lowest correct rate)
        List<TestQuestion> questions = getQuestionsForTest(testId);
        
        Map<String, Object> stats = Map.of(
            "testId", testId,
            "testTitle", test.getTitle(),
            "totalAttempts", totalAttempts,
            "averageScore", Math.round(averageScore * 100.0) / 100.0,
            "passRate", Math.round(passRate * 100.0) / 100.0,
            "passedCount", passedCount,
            "failedCount", totalAttempts - passedCount,
            "questionCount", questions.size()
        );

        return stats;
    }
}
