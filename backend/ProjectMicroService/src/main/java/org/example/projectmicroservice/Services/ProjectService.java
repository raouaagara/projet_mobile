package org.example.projectmicroservice.Services;


import org.example.projectmicroservice.Entities.*;
import org.example.projectmicroservice.Repositories.NotificationRepository;
import org.example.projectmicroservice.Repositories.ProjectRepository;
import org.example.projectmicroservice.Repositories.ProposalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ProjectService {
    @Autowired
    private ProjectRepository projectRepo;

    @Autowired
    private ProposalRepository proposalRepo;

    @Autowired
    private NotificationRepository notificationRepo;

    // --- Project Methods ---
    public Project createProject(Project project) {
        if (projectRepo.existsByTitleAndClientIdAndStatus(project.getTitle(), project.getClientId(), Status.OPEN)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "You already have an open project with this title.");
        }
        return projectRepo.save(project);
    }

    public List<Project> getAllProjects() {
        return projectRepo.findAll();
    }

    public Project getProjectById(Long id) {
        return projectRepo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Project not found"));
    }

    public void deleteProject(Long id) {
        if (!projectRepo.existsById(id)) {
            throw new RuntimeException("Projet introuvable");
        }
        projectRepo.deleteById(id);
    }


    public Project updateProjectStatus(Long id, Status status) {
        Project project = projectRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Projet introuvable"));

        project.setStatus(status);
        return projectRepo.save(project);
    }


    public Project updateProject(Long id, Project projectDetails) {
        Project project = projectRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Projet introuvable"));

        project.setTitle(projectDetails.getTitle());
        project.setDescription(projectDetails.getDescription());
        project.setBudget(projectDetails.getBudget());
        project.setCategory(projectDetails.getCategory());
        project.setExperienceLevel(projectDetails.getExperienceLevel());
        project.setJobType(projectDetails.getJobType());
        if (projectDetails.getRequiredCompetenceIds() != null) {
            project.setRequiredCompetenceIds(projectDetails.getRequiredCompetenceIds());
        }

        if (projectDetails.getImage() != null) {
            project.setImage(projectDetails.getImage());
        }

        return projectRepo.save(project);
    }

    // --- Proposal Methods ---
    public Proposal createProposal(Long projectId, Proposal proposal) {
        Project project = getProjectById(projectId);
        if (project.getStatus() != null && project.getStatus() != Status.OPEN) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "This project is no longer accepting proposals.");
        }
        if (proposal.getFreelancerId() != null
                && proposalRepo.existsByProjectIdAndFreelancerId(projectId, proposal.getFreelancerId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "You already sent a proposal for this project.");
        }
        if (proposal.getStatus() == null) {
            proposal.setStatus(StatusProposal.PENDING);
        }
        proposal.setProject(project);
        return proposalRepo.save(proposal);
    }
    public List<Proposal> getProposalsForProject(Long projectId) {
        return proposalRepo.findByProjectId(projectId);
    }
    public List<Proposal> getProposalsForFreelancer(Long freelancerId) {
        return proposalRepo.findByFreelancerId(freelancerId);
    }
    public Proposal updateProposalStatus(Long proposalId, StatusProposal newStatus) {
        Proposal proposal = proposalRepo.findById(proposalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Proposal not found"));

        boolean changed = proposal.getStatus() != newStatus;
        proposal.setStatus(newStatus);
        Proposal saved = proposalRepo.save(proposal);

        // Tell the freelancer when the client answers
        if (changed && newStatus != StatusProposal.PENDING && proposal.getFreelancerId() != null) {
            Notification notif = new Notification();
            notif.setRecipientId(proposal.getFreelancerId());
            notif.setProjectId(proposal.getProject().getId());
            notif.setMessage((newStatus == StatusProposal.ACCEPTED
                    ? "Your proposal was accepted for: "
                    : "Your proposal was declined for: ") + proposal.getProject().getTitle());
            notificationRepo.save(notif);
        }
        return saved;
    }
    /** {@code previous}: the user's earlier reaction, if they are changing it (it is removed). */
    public Project reactToProject(Long id, String reactionType, String previous) {
        Project project = getProjectById(id);
        if (previous != null && previous.equalsIgnoreCase(reactionType)) {
            return project;
        }
        if (previous != null) {
            addReaction(project, previous, -1);
        }
        addReaction(project, reactionType, 1);
        return projectRepo.save(project);
    }

    private void addReaction(Project project, String reactionType, int delta) {
        switch (reactionType.toUpperCase()) {
            case "LIKE": project.setLikes(Math.max(0, project.getLikes() + delta)); break;
            case "LOVE": project.setLoves(Math.max(0, project.getLoves() + delta)); break;
            case "HAHA": project.setHahas(Math.max(0, project.getHahas() + delta)); break;
            case "SUPPORT": project.setSupports(Math.max(0, project.getSupports() + delta)); break;
        }
    }
    public Proposal getProposalById(Long proposalId) {
        return proposalRepo.findById(proposalId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Proposal not found with ID: " + proposalId));
    }
}
