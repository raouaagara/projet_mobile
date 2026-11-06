package tn.esprit.communitymicroservice.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import tn.esprit.communitymicroservice.entities.Club;
import tn.esprit.communitymicroservice.repositories.ClubRepository;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ClubService {
    @Autowired
    private ClubRepository clubRepository;

    public Club createClub(Club club) {
        club.setCreatedAt(LocalDateTime.now());
        if (club.getStatus() == null) {
            club.setStatus("ACTIVE"); // the field default isn't applied when the JSON is read: creating failed
        }
        return clubRepository.save(club);
    }

    public List<Club> getAllClubs() {
        return clubRepository.findAll();
    }

    public Club getClubById(Long id) {
        return clubRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Club not found"));
    }

    public List<Club> searchClubsByInterest(String interest) {
        return clubRepository.findByInterestsContaining(interest);
    }

    public Club updateClub(Long id, Club updated) {
        Club club = getClubById(id);
        club.setName(updated.getName());
        club.setDescription(updated.getDescription());
        club.setBannerUrl(updated.getBannerUrl());
        club.setInterests(updated.getInterests());
        return clubRepository.save(club);
    }

    public void deleteClub(Long id) {
        clubRepository.deleteById(id);
    }

    public Club pauseClub(Long id) {
        Club club = getClubById(id);
        club.setStatus("PAUSED");
        return clubRepository.save(club);
    }

    public Club unpauseClub(Long id) {
        Club club = getClubById(id);
        club.setStatus("ACTIVE");
        return clubRepository.save(club);
    }
}
