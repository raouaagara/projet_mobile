package org.example.skilltestsmicroservice.Controllers;

import org.example.skilltestsmicroservice.DTO.GenerateAiTestRequest;
import org.example.skilltestsmicroservice.Entities.Certification;
import org.example.skilltestsmicroservice.Entities.SkillTest;
import org.example.skilltestsmicroservice.Entities.TestQuestion;
import org.example.skilltestsmicroservice.Services.AiCvService;
import org.example.skilltestsmicroservice.Services.SkillTestService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/SkillTests")
@CrossOrigin(origins = "*")
public class SkillTestController {

    @Autowired
    private SkillTestService service;

    @Autowired
    private AiCvService aiCvService;

    @GetMapping("/tests")
    public List<SkillTest> getAllTests() {
        return service.getAllActiveTests();
    }

    @GetMapping("/admin/tests")
    public List<SkillTest> getAllTestsAdmin() {
        return service.getAllTests();
    }

    @PostMapping("/admin/tests")
    public SkillTest createTest(@RequestBody SkillTest test) {
        return service.createTest(test);
    }

    @PutMapping("/admin/tests/{id}")
    public SkillTest updateTest(@PathVariable Long id, @RequestBody SkillTest test) {
        return service.updateTest(id, test);
    }

    @DeleteMapping("/admin/tests/{id}")
    public void deleteTest(@PathVariable Long id) {
        service.deleteTest(id);
    }

    @GetMapping("/tests/{id}")
    public SkillTest getTest(@PathVariable Long id) {
        return service.getTestById(id);
    }

    @GetMapping("/tests/{id}/questions")
    public List<TestQuestion> getQuestions(@PathVariable Long id) {
        return service.getQuestionsForTest(id);
    }

    @GetMapping("/categories")
    public List<String> getCategories() {
        return service.getAvailableCategories();
    }

    @PostMapping("/ai/generate")
    public SkillTest generateAiTest(@RequestBody GenerateAiTestRequest request) {
        return service.generateAiTest(
                request.getUserId(),
                request.getCategory(),
                Boolean.TRUE.equals(request.getHasAiAccess()),
                request.getUserName()
        );
    }

    @PostMapping("/submit")
    public Certification submit(@RequestParam Long userId, @RequestParam Long testId, @RequestBody Map<String, String> answers) {
        return service.submitTest(userId, testId, answers, null);
    }

    @PostMapping("/submit-with-name")
    public Certification submitWithName(@RequestParam Long userId, @RequestParam Long testId,
                                       @RequestParam(required = false) String userName,
                                       @RequestBody Map<String, String> answers) {
        return service.submitTest(userId, testId, answers, userName);
    }

    @GetMapping("/certifications/user/{userId}")
    public List<Certification> getUserCertifications(@PathVariable Long userId) {
        return service.getUserCertifications(userId);
    }

    @GetMapping("/admin/all-certifications")
    public List<Certification> getAllCertifications() {
        return service.getAllCertifications();
    }

    @GetMapping("/admin/passed-certifications")
    public List<Certification> getPassedCertifications() {
        return service.getPassedCertifications();
    }

    @GetMapping("/admin/stats-by-category")
    public Map<String, Long> getStatsByCategory() {
        return service.getStatsByCategory();
    }

    @GetMapping("/admin/certifications/{id}")
    public Certification getCertification(@PathVariable Long id) {
        return service.getCertificationById(id);
    }

    @DeleteMapping("/admin/certifications/{id}")
    public void deleteCertification(@PathVariable Long id) {
        service.deleteCertification(id);
    }

    @PostMapping("/admin/tests/{testId}/questions")
    public TestQuestion createQuestion(@PathVariable Long testId, @RequestBody TestQuestion question) {
        return service.createQuestion(testId, question);
    }

    @PutMapping("/admin/questions/{id}")
    public TestQuestion updateQuestion(@PathVariable Long id, @RequestBody TestQuestion question) {
        return service.updateQuestion(id, question);
    }

    @DeleteMapping("/admin/questions/{id}")
    public void deleteQuestion(@PathVariable Long id) {
        service.deleteQuestion(id);
    }

    // Test Statistics
    @GetMapping("/admin/tests/{id}/statistics")
    public Map<String, Object> getTestStatistics(@PathVariable Long id) {
        return service.getTestStatistics(id);
    }

    // AI CV Generator Endpoints
    @PostMapping("/ai/cv/analyze-text")
    public Map<String, Object> analyzeCVText(@RequestBody Map<String, String> request) {
        String cvText = request.get("cvText");
        String targetDomain = request.get("targetDomain");
        return aiCvService.analyzeAndImproveCV(cvText, targetDomain);
    }

    @PostMapping("/ai/cv/analyze-image")
    public Map<String, Object> analyzeCVImage(@RequestBody Map<String, String> request) {
        String imageBase64 = request.get("imageBase64");
        String mimeType = request.get("mimeType");
        String targetDomain = request.get("targetDomain");
        return aiCvService.analyzeAndImproveCVFromImage(imageBase64, mimeType, targetDomain);
    }
}
