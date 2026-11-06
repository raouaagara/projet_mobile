package tn.esprit.communitymicroservice.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tn.esprit.communitymicroservice.entities.Group;
import tn.esprit.communitymicroservice.services.GroupService;

import java.util.List;

@RestController
@RequestMapping("/api/groups")
@CrossOrigin(origins = "*")
public class GroupController {
    @Autowired
    private GroupService groupService;

    @Autowired
    private tn.esprit.communitymicroservice.services.GroupMemberService groupMemberService;

    @PostMapping
    public ResponseEntity<Group> create(@RequestBody Group group, @RequestParam(required = false) Long creatorId) {
        try {
            Group created = groupService.createGroup(group);
            if (creatorId != null) {
                groupMemberService.addCreator(created, creatorId); // the creator is the group's first admin
            }
            return ResponseEntity.ok(created);
        } catch (Exception e) {
            System.err.println("Error creating group: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping
    public ResponseEntity<List<Group>> getAll() {
        try {
            List<Group> groups = groupService.getAllGroups();
            return ResponseEntity.ok(groups);
        } catch (Exception e) {
            System.err.println("Error getting groups: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<Group> getById(@PathVariable Long id) {
        try {
            Group group = groupService.getGroupById(id);
            return ResponseEntity.ok(group);
        } catch (Exception e) {
            System.err.println("Error getting group: " + e.getMessage());
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<Group> update(@PathVariable Long id, @RequestBody Group group) {
        try {
            Group updated = groupService.updateGroup(id, group);
            return ResponseEntity.ok(updated);
        } catch (Exception e) {
            System.err.println("Error updating group: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        try {
            System.out.println("Deleting group with ID: " + id);
            groupService.deleteGroup(id);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            System.err.println("Error deleting group " + id + ": " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}

