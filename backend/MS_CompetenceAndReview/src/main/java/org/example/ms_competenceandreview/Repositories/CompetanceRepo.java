package org.example.ms_competenceandreview.Repositories;

import org.example.ms_competenceandreview.Entities.Competance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CompetanceRepo extends JpaRepository<Competance, Long> {
    Optional<Competance> findFirstByNomIgnoreCase(String nom);
}
