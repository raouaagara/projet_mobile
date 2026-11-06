package org.example.ms_competenceandreview.Repositories;

import org.example.ms_competenceandreview.Entities.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReviewRepo extends JpaRepository<Review, Long> {

    List<Review> findByFreelancerId(String freelancerId);

    List<Review> findByClientId(String clientId);
    List<Review> findByProjectId(Long projectId);
}
