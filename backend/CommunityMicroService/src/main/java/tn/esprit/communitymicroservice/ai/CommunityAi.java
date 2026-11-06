package tn.esprit.communitymicroservice.ai;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;
import tn.esprit.communitymicroservice.entities.Club;
import tn.esprit.communitymicroservice.entities.Event;
import tn.esprit.communitymicroservice.entities.EventStatus;
import tn.esprit.communitymicroservice.entities.Group;
import tn.esprit.communitymicroservice.entities.GroupMember;
import tn.esprit.communitymicroservice.entities.GroupType;
import tn.esprit.communitymicroservice.repositories.ClubRepository;
import tn.esprit.communitymicroservice.repositories.EventRepository;
import tn.esprit.communitymicroservice.repositories.GroupMemberRepository;
import tn.esprit.communitymicroservice.repositories.GroupRepository;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/** Community AI (Gemini): groups, clubs and events picked for a user, and a post written from a few words. */
@Service
public class CommunityAi {

    /** What the app knows about the user (skills come from module 1). */
    public record Profile(Long userId, String role, List<String> skills, String bio) {}

    /** {@code kind}: GROUP, CLUB or EVENT; {@code id}: its id; {@code reason}: one sentence for the user. */
    public record Pick(String kind, Long id, String name, String reason) {}

    public record PostDraftRequest(String idea, String where) {}

    static final int MAX_CANDIDATES = 30;
    static final int MAX_PICKS = 6;

    private final GroupRepository groups;
    private final GroupMemberRepository members;
    private final ClubRepository clubs;
    private final EventRepository events;
    private final GeminiClient gemini;

    public CommunityAi(GroupRepository groups, GroupMemberRepository members, ClubRepository clubs,
                       EventRepository events, GeminiClient gemini) {
        this.groups = groups;
        this.members = members;
        this.clubs = clubs;
        this.events = events;
        this.gemini = gemini;
    }

    /** Groups the user isn't in, active clubs, and approved upcoming events, ranked for them by the AI. */
    public List<Pick> recommend(Profile profile) {
        Long userId = profile.userId();
        Set<Long> joined = new HashSet<>();
        if (userId != null) {
            for (GroupMember m : members.findByUserId(userId)) if (m.getGroup() != null) joined.add(m.getGroup().getId());
        }
        LocalDateTime now = LocalDateTime.now();
        List<Group> openGroups = groups.findAll().stream()
                .filter(g -> !joined.contains(g.getId()) && g.getType() != GroupType.INVITE_ONLY)
                .limit(MAX_CANDIDATES).toList();
        List<Club> activeClubs = clubs.findAll().stream()
                .filter(c -> !"PAUSED".equalsIgnoreCase(c.getStatus()) && !Objects.equals(c.getCreatorId(), userId))
                .limit(MAX_CANDIDATES).toList();
        List<Event> upcoming = events.findAll().stream()
                .filter(e -> e.getStatus() == EventStatus.APPROVED && e.getStartDate() != null && e.getStartDate().isAfter(now))
                .limit(MAX_CANDIDATES).toList();
        if (openGroups.isEmpty() && activeClubs.isEmpty() && upcoming.isEmpty()) return List.of();

        StringBuilder catalog = new StringBuilder();
        for (Group g : openGroups) {
            catalog.append("GROUP ").append(g.getId()).append(": ").append(g.getName()).append(" - ")
                    .append(cut(g.getDescription())).append('\n');
        }
        for (Club c : activeClubs) {
            catalog.append("CLUB ").append(c.getId()).append(": ").append(c.getName()).append(" - ")
                    .append(cut(c.getDescription())).append(" Interests: ").append(Objects.toString(c.getInterests(), ""))
                    .append('\n');
        }
        for (Event e : upcoming) {
            catalog.append("EVENT ").append(e.getId()).append(": ").append(e.getTitle()).append(" on ")
                    .append(e.getStartDate().toLocalDate()).append(" at ").append(Objects.toString(e.getLocation(), "online"))
                    .append(" - ").append(cut(e.getDescription())).append('\n');
        }
        String prompt = """
                You recommend community spaces on Workify, a freelance marketplace, to one user.
                Pick at most %d items from the list below that really fit this user (their skills, their role, their bio).
                Only items from the list, with their exact kind and id. Fewer is better than weak picks; none if nothing fits.
                Return JSON: {"picks": [{"kind": "GROUP|CLUB|EVENT", "id": 12, "reason": "one short sentence, in English, why it fits them"}]}

                USER
                Role: %s
                Skills: %s
                Bio: %s

                LIST
                %s""".formatted(MAX_PICKS, text(profile.role()),
                profile.skills() == null || profile.skills().isEmpty() ? "none" : String.join(", ", profile.skills()),
                text(profile.bio()), catalog);

        Map<String, Map<Long, String>> names = Map.of(
                "GROUP", byId(openGroups, Group::getId, Group::getName),
                "CLUB", byId(activeClubs, Club::getId, Club::getName),
                "EVENT", byId(upcoming, Event::getId, Event::getTitle));
        JsonNode json = gemini.generateJson(prompt);
        List<Pick> picks = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        for (JsonNode p : json.path("picks")) {
            String kind = p.path("kind").asText("").strip().toUpperCase();
            long id = p.path("id").asLong(-1);
            String name = names.getOrDefault(kind, Map.of()).get(id);
            // Only real, distinct items: an invented id is dropped.
            if (name == null || !seen.add(kind + id) || picks.size() == MAX_PICKS) continue;
            picks.add(new Pick(kind, id, name, p.path("reason").asText("").strip()));
        }
        return picks;
    }

    /** A clear community post from the user's few words, in their language. */
    public String draftPost(PostDraftRequest req) {
        String idea = req.idea() == null ? "" : req.idea().strip();
        if (idea.length() < 5) throw new IllegalArgumentException("Write a few words about your post first.");
        return gemini.generate("""
                Write a post for the community space of Workify, a freelance marketplace%s, from the author's notes.
                In the language of the notes, first person, friendly and clear, 40 to 120 words, plain text (no markdown,
                at most 2 emojis, no hashtags). If the notes ask a question, end with that question to the community.
                Use ONLY what the notes say; never invent experience, numbers, links or events.

                Notes: %s
                """.formatted(req.where() == null || req.where().isBlank() ? "" : ", in \"" + req.where().strip() + "\"",
                idea.length() > 1500 ? idea.substring(0, 1500) : idea)).strip();
    }

    private static <T> Map<Long, String> byId(List<T> items, Function<T, Long> id, Function<T, String> name) {
        return items.stream().filter(i -> id.apply(i) != null)
                .collect(Collectors.toMap(id, i -> Objects.toString(name.apply(i), ""), (a, b) -> a));
    }

    private static String cut(String s) {
        if (s == null || s.isBlank()) return "";
        String t = s.strip().replaceAll("\\s+", " ");
        return t.length() > 160 ? t.substring(0, 160) + "…" : t;
    }

    private static String text(String s) {
        return s == null || s.isBlank() ? "not given" : s.strip();
    }
}
