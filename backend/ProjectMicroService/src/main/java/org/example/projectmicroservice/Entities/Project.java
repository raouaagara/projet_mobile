package org.example.projectmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

@Entity
@Getter
@Setter
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Project {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Lob
    @Column(columnDefinition = "LONGTEXT")
    private String description;

    @Lob
    @Column(columnDefinition = "LONGTEXT")
    private String image;

    private String ExperienceLevel;

    private Double budget;

    private LocalDate postedAt;

    @Enumerated(EnumType.STRING)
    private Status status;

    @Enumerated(EnumType.STRING)
    private ProjectCategory category;

    @Enumerated(EnumType.STRING)
    private JobType jobType;

    private Long clientId;

    // Fixed: Changed from int to Integer and kept defaults
    @Column(columnDefinition = "integer default 0")
    private Integer likes = 0;

    @Column(columnDefinition = "integer default 0")
    private Integer loves = 0;

    @Column(columnDefinition = "integer default 0")
    private Integer hahas = 0;

    @Column(columnDefinition = "integer default 0")
    private Integer supports = 0;

    @ElementCollection
    @CollectionTable(name = "project_competences", joinColumns = @JoinColumn(name = "project_id"))
    @Column(name = "competence_id")
    private List<Long> requiredCompetenceIds;

    @JsonIgnore
    @OneToMany(mappedBy = "project", cascade = CascadeType.ALL)
    private List<Proposal> proposals;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }

    public String getExperienceLevel() {
        return ExperienceLevel;
    }

    public void setExperienceLevel(String experienceLevel) {
        ExperienceLevel = experienceLevel;
    }

    public Double getBudget() {
        return budget;
    }

    public void setBudget(Double budget) {
        this.budget = budget;
    }

    public LocalDate getPostedAt() {
        return postedAt;
    }

    public void setPostedAt(LocalDate postedAt) {
        this.postedAt = postedAt;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public ProjectCategory getCategory() {
        return category;
    }

    public void setCategory(ProjectCategory category) {
        this.category = category;
    }

    public JobType getJobType() {
        return jobType;
    }

    public void setJobType(JobType jobType) {
        this.jobType = jobType;
    }

    public Long getClientId() {
        return clientId;
    }

    public void setClientId(Long clientId) {
        this.clientId = clientId;
    }

    public void setLikes(Integer likes) {
        this.likes = likes;
    }

    public void setLoves(Integer loves) {
        this.loves = loves;
    }

    public void setHahas(Integer hahas) {
        this.hahas = hahas;
    }

    public void setSupports(Integer supports) {
        this.supports = supports;
    }

    public List<Long> getRequiredCompetenceIds() {
        return requiredCompetenceIds;
    }

    public void setRequiredCompetenceIds(List<Long> requiredCompetenceIds) {
        this.requiredCompetenceIds = requiredCompetenceIds;
    }

    public List<Proposal> getProposals() {
        return proposals;
    }

    public void setProposals(List<Proposal> proposals) {
        this.proposals = proposals;
    }

    /**
     * Helper methods to ensure we never return null to the frontend
     * even if the database has NULL values.
     */
    public Integer getLikes() { return likes == null ? 0 : likes; }
    public Integer getLoves() { return loves == null ? 0 : loves; }
    public Integer getHahas() { return hahas == null ? 0 : hahas; }
    public Integer getSupports() { return supports == null ? 0 : supports; }
}