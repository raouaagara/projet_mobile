package org.example.skilltestsmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "certifications")
@Data
public class Certification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;
    private String userName;  // optional, for admin display

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "skill_test_id")
    @JsonIgnore
    private SkillTest skillTest;

    private String testTitle;  // denormalized for display
    private String category;   // denormalized for display

    public Long getSkillTestId() {
        return skillTest != null ? skillTest.getId() : null;
    }
    private Integer score;     // percentage
    private Boolean passed;
    private LocalDateTime completedAt = LocalDateTime.now();
}
