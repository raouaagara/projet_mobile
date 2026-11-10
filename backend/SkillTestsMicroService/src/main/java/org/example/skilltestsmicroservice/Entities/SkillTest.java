package org.example.skilltestsmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "skill_tests")
@Data
public class SkillTest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String description;
    private String category;  // Web Dev, Design, Marketing, etc.
    private Integer durationMinutes;
    private Integer passScore;  // percentage to pass (e.g. 70)
    private Boolean active = true;

    // Scheduling fields
    @Column(name = "scheduled_start_date")
    private LocalDateTime scheduledStartDate;
    
    @Column(name = "expiry_date")
    private LocalDateTime expiryDate;

    @OneToMany(mappedBy = "skillTest", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<TestQuestion> questions = new ArrayList<>();

    @OneToMany(mappedBy = "skillTest", cascade = CascadeType.REMOVE)
    @JsonIgnore
    private List<Certification> certifications = new ArrayList<>();
}
