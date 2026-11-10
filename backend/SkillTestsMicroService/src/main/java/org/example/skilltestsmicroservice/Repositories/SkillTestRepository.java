package org.example.skilltestsmicroservice.Repositories;

import org.example.skilltestsmicroservice.Entities.SkillTest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface SkillTestRepository extends JpaRepository<SkillTest, Long> {
    List<SkillTest> findByActiveTrue();
    List<SkillTest> findByCategory(String category);
}
