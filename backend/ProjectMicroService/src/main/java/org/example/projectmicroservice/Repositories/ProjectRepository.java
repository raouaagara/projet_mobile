package org.example.projectmicroservice.Repositories;

import org.example.projectmicroservice.Entities.Project;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.example.projectmicroservice.Entities.Status;

@Repository
public interface ProjectRepository extends JpaRepository<Project, Long> {
    boolean existsByTitleAndClientIdAndStatus(String title, Long clientId, Status status);
}
