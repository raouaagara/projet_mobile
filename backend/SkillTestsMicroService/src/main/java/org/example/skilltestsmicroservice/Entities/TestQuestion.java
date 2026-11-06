package org.example.skilltestsmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "test_questions")
@Data
public class TestQuestion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "skill_test_id")
    private SkillTest skillTest;

    private String questionText;
    private String optionA;
    private String optionB;
    private String optionC;
    private String optionD;
    @Column(name = "correct_option")
    @JsonIgnore  // Don't expose correct answer to frontend
    private String correctOption;
}
