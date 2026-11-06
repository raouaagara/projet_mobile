package tn.esprit.communitymicroservice.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import tn.esprit.communitymicroservice.entities.Group;
import tn.esprit.communitymicroservice.entities.GroupType;
import tn.esprit.communitymicroservice.entities.Role;
import tn.esprit.communitymicroservice.repositories.GroupRepository;
import org.springframework.stereotype.Service;
import tn.esprit.communitymicroservice.entities.GroupMember;
import tn.esprit.communitymicroservice.repositories.GroupMemberRepository;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class GroupMemberService {
    @Autowired
    private GroupMemberRepository groupMemberRepository;

    @Autowired
    private GroupRepository groupRepository;

    /**
     * [userId] joins [groupId] as a member: public groups only, once.
     * (The raw POST /api/group-members stays for admins adding people to private groups.)
     */
    public GroupMember join(Long groupId, Long userId) {
        if (groupId == null || userId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "groupId and userId are required");
        }
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "This group doesn't exist."));
        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "You're already a member of this group.");
        }
        if (group.getType() != null && group.getType() != GroupType.PUBLIC) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "This group is private: ask one of its admins to add you.");
        }
        GroupMember member = new GroupMember();
        member.setGroup(group);
        member.setUserId(userId);
        member.setRole(Role.MEMBER);
        return addMember(member);
    }

    /** The creator of a group becomes its first admin. */
    public GroupMember addCreator(Group group, Long userId) {
        GroupMember member = new GroupMember();
        member.setGroup(group);
        member.setUserId(userId);
        member.setRole(Role.ADMIN);
        return addMember(member);
    }

    public GroupMember addMember(GroupMember member) {
        member.setJoinedAt(LocalDateTime.now());
        return groupMemberRepository.save(member);
    }

    public List<GroupMember> getAllMembers() {
        return groupMemberRepository.findAll();
    }

    public GroupMember getMemberById(Long id) {
        return groupMemberRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Member not found"));
    }

    public List<GroupMember> getMembersByGroupId(Long groupId) {
        return groupMemberRepository.findByGroupId(groupId);
    }

    public List<GroupMember> getMembersByUserId(Long userId) {
        return groupMemberRepository.findByUserId(userId);
    }

    public GroupMember updateMemberRole(Long id, GroupMember updated) {
        GroupMember member = getMemberById(id);
        member.setRole(updated.getRole());
        return groupMemberRepository.save(member);
    }

    public void removeMember(Long id) {
        groupMemberRepository.deleteById(id);
    }

    public Long countMembersByGroupId(Long groupId) {
        return groupMemberRepository.countByGroupId(groupId);
    }
}
