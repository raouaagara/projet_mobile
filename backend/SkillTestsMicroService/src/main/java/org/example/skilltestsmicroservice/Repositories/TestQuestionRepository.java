package org.example.skilltestsmicroservice.Repositories;

import org.example.skilltestsmicroservice.Entities.TestQuestion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TestQuestionRepository extends JpaRepository<TestQuestion, Long> {
    List<TestQuestion> findBySkillTestId(Long skillTestId);
}
