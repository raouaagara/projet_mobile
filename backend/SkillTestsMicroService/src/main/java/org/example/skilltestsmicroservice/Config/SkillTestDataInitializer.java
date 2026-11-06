package org.example.skilltestsmicroservice.Config;

import org.example.skilltestsmicroservice.Entities.SkillTest;
import org.example.skilltestsmicroservice.Entities.TestQuestion;
import org.example.skilltestsmicroservice.Repositories.SkillTestRepository;
import org.example.skilltestsmicroservice.Repositories.TestQuestionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class SkillTestDataInitializer implements CommandLineRunner {

    @Autowired
    private SkillTestRepository testRepo;

    @Autowired
    private TestQuestionRepository questionRepo;

    @Override
    public void run(String... args) {
        if (testRepo.count() > 0) return;

        SkillTest angular = new SkillTest();
        angular.setTitle("Angular Fundamentals");
        angular.setDescription("Test your knowledge of Angular framework basics.");
        angular.setCategory("Web Development");
        angular.setDurationMinutes(15);
        angular.setPassScore(70);
        angular.setActive(true);
        testRepo.save(angular);

        addQuestion(angular, "What does NgModule do?", "Defines a compilation context", "Renders HTML", "Handles HTTP", "Manages state", "A");
        addQuestion(angular, "Which decorator defines a component?", "@Component", "@Module", "@Service", "@Directive", "A");
        addQuestion(angular, "What is RxJS used for?", "Reactive programming", "Routing", "Forms", "Testing", "A");

        SkillTest design = new SkillTest();
        design.setTitle("UI/UX Design Basics");
        design.setDescription("Core principles of user interface and experience design.");
        design.setCategory("Design");
        design.setDurationMinutes(10);
        design.setPassScore(70);
        design.setActive(true);
        testRepo.save(design);

        addQuestion(design, "What does UX stand for?", "User Experience", "User Export", "Unified Experience", "User Extension", "A");
        addQuestion(design, "Which tool is commonly used for prototyping?", "Figma", "Excel", "Word", "Photoshop", "A");
    }

    private void addQuestion(SkillTest test, String q, String a, String b, String c, String d, String correct) {
        TestQuestion qu = new TestQuestion();
        qu.setSkillTest(test);
        qu.setQuestionText(q);
        qu.setOptionA(a);
        qu.setOptionB(b);
        qu.setOptionC(c);
        qu.setOptionD(d);
        qu.setCorrectOption(correct);
        questionRepo.save(qu);
    }
}
