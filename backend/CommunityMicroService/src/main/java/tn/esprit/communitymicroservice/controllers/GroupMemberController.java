package tn.esprit.communitymicroservice.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import tn.esprit.communitymicroservice.entities.GroupMember;
import tn.esprit.communitymicroservice.services.GroupMemberService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/group-members")
public class GroupMemberController {
    @Autowired
    private GroupMemberService groupMemberService;

    /** Join a public group. Body: {"groupId": 1, "userId": 7} */
    @PostMapping("/join")
    public GroupMember join(@RequestBody Map<String, Object> body) {
        return groupMemberService.join(toLong(body.get("groupId")), toLong(body.get("userId")));
    }

    private static Long toLong(Object value) {
        try {
            return value == null ? null : Long.valueOf(value.toString());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    @PostMapping
    public GroupMember addMember(@RequestBody GroupMember member) {
        return groupMemberService.addMember(member);
    }

    @GetMapping
    public List<GroupMember> getAllMembers() {
        return groupMemberService.getAllMembers();
    }

    @GetMapping("/{id}")
    public GroupMember getMemberById(@PathVariable Long id) {
        return groupMemberService.getMemberById(id);
    }

    @GetMapping("/group/{groupId}")
    public List<GroupMember> getMembersByGroupId(@PathVariable Long groupId) {
        return groupMemberService.getMembersByGroupId(groupId);
    }

    @GetMapping("/user/{userId}")
    public List<GroupMember> getMembersByUserId(@PathVariable Long userId) {
        return groupMemberService.getMembersByUserId(userId);
    }

    @PutMapping("/{id}")
    public GroupMember updateMemberRole(@PathVariable Long id, @RequestBody GroupMember member) {
        return groupMemberService.updateMemberRole(id, member);
    }

    @DeleteMapping("/{id}")
    public void removeMember(@PathVariable Long id) {
        groupMemberService.removeMember(id);
    }

    @GetMapping("/group/{groupId}/count")
    public Long countMembersByGroupId(@PathVariable Long groupId) {
        return groupMemberService.countMembersByGroupId(groupId);
    }
}
