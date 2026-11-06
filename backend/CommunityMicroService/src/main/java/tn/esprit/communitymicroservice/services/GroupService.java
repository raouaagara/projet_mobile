package tn.esprit.communitymicroservice.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tn.esprit.communitymicroservice.entities.Group;
import tn.esprit.communitymicroservice.repositories.GroupRepository;
import tn.esprit.communitymicroservice.repositories.GroupMemberRepository;
import tn.esprit.communitymicroservice.repositories.PostRepository;
import tn.esprit.communitymicroservice.repositories.EventRepository;

import java.util.List;

@Service
public class GroupService {
    @Autowired
    private GroupRepository groupRepository;
    
    @Autowired
    private GroupMemberRepository groupMemberRepository;
    
    @Autowired
    private PostRepository postRepository;
    
    @Autowired
    private EventRepository eventRepository;

    public Group createGroup(Group group) {
        return groupRepository.save(group);
    }

    public List<Group> getAllGroups() {
        return groupRepository.findAll();
    }

    public Group getGroupById(Long id) {
        return groupRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Group not found"));
    }

    public Group updateGroup(Long id, Group updated) {
        Group g = getGroupById(id);
        g.setName(updated.getName());
        g.setDescription(updated.getDescription());
        g.setBannerUrl(updated.getBannerUrl());
        g.setType(updated.getType());
        return groupRepository.save(g);
    }

    @Transactional
    public void deleteGroup(Long id) {
        try {
            System.out.println("Starting deletion of group " + id);
            
            // First, we need to delete comments and reactions for all posts in this group
            System.out.println("Deleting comments and reactions for posts in group " + id);
            List<tn.esprit.communitymicroservice.entities.Post> posts = postRepository.findByGroupId(id);
            for (tn.esprit.communitymicroservice.entities.Post post : posts) {
                // Delete by post ID to trigger cascade deletion
                postRepository.deleteById(post.getId());
            }
            
            // Delete all related events
            System.out.println("Deleting events for group " + id);
            eventRepository.deleteByGroupId(id);
            
            // Delete all group members
            System.out.println("Deleting members for group " + id);
            groupMemberRepository.deleteByGroupId(id);
            
            // Finally delete the group
            System.out.println("Deleting group " + id);
            groupRepository.deleteById(id);
            
            System.out.println("Group " + id + " deleted successfully");
        } catch (Exception e) {
            System.err.println("Error deleting group " + id + ": " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Failed to delete group: " + e.getMessage());
        }
    }
}
