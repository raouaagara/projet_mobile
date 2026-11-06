package org.example.skilltestsmicroservice.Repositories;

import org.example.skilltestsmicroservice.Entities.Certification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CertificationRepository extends JpaRepository<Certification, Long> {
    List<Certification> findByUserId(Long userId);
    List<Certification> findByUserIdAndPassedTrue(Long userId);
}
