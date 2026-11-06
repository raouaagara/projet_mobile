package tn.esprit.communitymicroservice.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import tn.esprit.communitymicroservice.entities.Group;

@Repository
public interface GroupRepository extends JpaRepository<Group, Long> {
}

