package tn.esprit.communitymicroservice.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import tn.esprit.communitymicroservice.entities.Club;
import tn.esprit.communitymicroservice.services.ClubService;

import java.util.List;

@RestController
@RequestMapping("/api/clubs")
public class ClubController {
    @Autowired
    private ClubService clubService;

    @PostMapping
    public Club createClub(@RequestBody Club club) {
        return clubService.createClub(club);
    }

    @GetMapping
    public List<Club> getAllClubs() {
        return clubService.getAllClubs();
    }

    @GetMapping("/{id}")
    public Club getClubById(@PathVariable Long id) {
        return clubService.getClubById(id);
    }

    @GetMapping("/search")
    public List<Club> searchClubsByInterest(@RequestParam String interest) {
        return clubService.searchClubsByInterest(interest);
    }

    @PutMapping("/{id}")
    public Club updateClub(@PathVariable Long id, @RequestBody Club club) {
        return clubService.updateClub(id, club);
    }

    @DeleteMapping("/{id}")
    public void deleteClub(@PathVariable Long id) {
        clubService.deleteClub(id);
    }

    @PutMapping("/{id}/pause")
    public Club pauseClub(@PathVariable Long id) {
        return clubService.pauseClub(id);
    }

    @PutMapping("/{id}/unpause")
    public Club unpauseClub(@PathVariable Long id) {
        return clubService.unpauseClub(id);
    }
}
