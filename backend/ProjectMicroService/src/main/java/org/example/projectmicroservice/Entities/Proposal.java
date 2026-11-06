package org.example.projectmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Proposal {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Double bidAmount;
    private LocalDate estimationEndDate;
    @Enumerated(EnumType.STRING)
    private StatusProposal status;

    private Long freelancerId;

    /** Lettre de motivation (facultative), écrite par le freelancer ou avec l'IA. */
    @Column(columnDefinition = "TEXT")
    private String coverLetter;

    @ManyToOne
    @JoinColumn(name = "project_id")
    @JsonIgnoreProperties("proposals")
    private Project project;


    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Double getBidAmount() {
        return bidAmount;
    }

    public void setBidAmount(Double bidAmount) {
        this.bidAmount = bidAmount;
    }

    public LocalDate getEstimationEndDate() {
        return estimationEndDate;
    }

    public void setEstimationEndDate(LocalDate estimationEndDate) {
        this.estimationEndDate = estimationEndDate;
    }


    public Long getFreelancerId() {
        return freelancerId;
    }

    public void setFreelancerId(Long freelancerId) {
        this.freelancerId = freelancerId;
    }

    public String getCoverLetter() {
        return coverLetter;
    }

    public void setCoverLetter(String coverLetter) {
        this.coverLetter = coverLetter;
    }

    public Project getProject() {
        return project;
    }

    public StatusProposal getStatus() {
        return status;
    }

    public void setStatus(StatusProposal status) {
        this.status = status;
    }

    public void setProject(Project project) {
        this.project = project;
    }
}
