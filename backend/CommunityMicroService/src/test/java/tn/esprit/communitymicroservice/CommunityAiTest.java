package tn.esprit.communitymicroservice;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import tn.esprit.communitymicroservice.ai.CommunityAi;
import tn.esprit.communitymicroservice.ai.CommunityAi.PostDraftRequest;
import tn.esprit.communitymicroservice.ai.CommunityAi.Profile;
import tn.esprit.communitymicroservice.ai.ContentModerator;
import tn.esprit.communitymicroservice.ai.GeminiClient;
import tn.esprit.communitymicroservice.entities.*;
import tn.esprit.communitymicroservice.repositories.ClubRepository;
import tn.esprit.communitymicroservice.repositories.EventRepository;
import tn.esprit.communitymicroservice.repositories.GroupMemberRepository;
import tn.esprit.communitymicroservice.repositories.GroupRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** Community moderation, recommendations and the post writer, with a fake Gemini (no network). */
class CommunityAiTest {

    private final AtomicInteger calls = new AtomicInteger();
    private String lastPrompt;

    private GeminiClient answering(String json) {
        return new GeminiClient("test-key", "test-model") {
            @Override
            public JsonNode generateJson(String prompt) {
                calls.incrementAndGet();
                lastPrompt = prompt;
                try {
                    return new ObjectMapper().readTree(json);
                } catch (Exception e) {
                    throw new IllegalStateException(e);
                }
            }

            @Override
            public String generate(String prompt) {
                lastPrompt = prompt;
                return json;
            }
        };
    }

    @Test
    void moderationBlocksWithTheReasonAndCaches() {
        ContentModerator moderator = new ContentModerator(answering(
                "{\"category\": \"scam\", \"reason\": \"Les paiements se font sur Workify.\"}"));

        var e = assertThrows(ResponseStatusException.class,
                () -> moderator.requireAllowed("Payez-moi en crypto, je double votre argent en 24h"));
        assertEquals(422, e.getStatusCode().value());
        assertEquals("Les paiements se font sur Workify.", e.getReason());
        assertThrows(ResponseStatusException.class,
                () -> moderator.requireAllowed("Payez-moi en crypto, je double votre argent en 24h"));
        assertEquals(1, calls.get());
    }

    @Test
    void moderationLetsNormalShortOrUncheckedTextThrough() {
        assertDoesNotThrow(() -> new ContentModerator(answering("{\"category\": \"none\"}"))
                .requireAllowed("I disagree, the deadline was too short for this job."));
        assertDoesNotThrow(() -> new ContentModerator(answering("{\"category\": \"spam\"}")).requireAllowed("ok 👍"));
        assertDoesNotThrow(() -> new ContentModerator(new GeminiClient("", "m"))
                .requireAllowed("Without a key nothing is checked here."));
    }

    private CommunityAi community(String json, Group joined, Group open, Club club, Event event) {
        GroupRepository groups = mock(GroupRepository.class);
        GroupMemberRepository members = mock(GroupMemberRepository.class);
        ClubRepository clubs = mock(ClubRepository.class);
        EventRepository events = mock(EventRepository.class);
        when(groups.findAll()).thenReturn(List.of(joined, open));
        GroupMember membership = new GroupMember();
        membership.setGroup(joined);
        when(members.findByUserId(7L)).thenReturn(List.of(membership));
        when(clubs.findAll()).thenReturn(List.of(club));
        when(events.findAll()).thenReturn(List.of(event));
        return new CommunityAi(groups, members, clubs, events, answering(json));
    }

    private static Group group(long id, String name) {
        Group g = new Group();
        g.setId(id);
        g.setName(name);
        g.setType(GroupType.PUBLIC);
        return g;
    }

    @Test
    void recommendsOnlyRealItemsTheUserIsNotIn() {
        Club club = new Club();
        club.setId(3L);
        club.setName("Mobile devs club");
        club.setInterests("Flutter, Android");
        Event event = new Event();
        event.setId(9L);
        event.setTitle("Flutter meetup Tunis");
        event.setStatus(EventStatus.APPROVED);
        event.setStartDate(LocalDateTime.now().plusDays(5));
        CommunityAi ai = community("""
                {"picks": [{"kind": "GROUP", "id": 2, "reason": "Flutter devs share jobs here."},
                           {"kind": "GROUP", "id": 1, "reason": "already joined"},
                           {"kind": "CLUB", "id": 77, "reason": "invented"},
                           {"kind": "EVENT", "id": 9, "reason": "A meetup about your main skill."},
                           {"kind": "GROUP", "id": 2, "reason": "twice"}]}""",
                group(1, "Joined group"), group(2, "Flutter Tunisia"), club, event);

        var picks = ai.recommend(new Profile(7L, "FREELANCER", List.of("Flutter", "Firebase"), "Mobile developer"));

        assertEquals(List.of("Flutter Tunisia", "Flutter meetup Tunis"), picks.stream().map(CommunityAi.Pick::name).toList());
        assertFalse(lastPrompt.contains("Joined group")); // not offered: already a member
        assertTrue(lastPrompt.contains("CLUB 3: Mobile devs club") && lastPrompt.contains("Interests: Flutter, Android"));
        assertTrue(lastPrompt.contains("Skills: Flutter, Firebase"));
    }

    @Test
    void postDraftUsesTheNotesAndNeedsAFewWords() {
        CommunityAi ai = community("Hi everyone! I'm looking for tips on pricing my first Flutter app.",
                group(1, "a"), group(2, "b"), new Club(), new Event());

        String text = ai.draftPost(new PostDraftRequest("tips pricing first flutter app", "Flutter Tunisia"));

        assertTrue(text.startsWith("Hi everyone!"));
        assertTrue(lastPrompt.contains("in \"Flutter Tunisia\"") && lastPrompt.contains("tips pricing first flutter app"));
        assertThrows(IllegalArgumentException.class, () -> ai.draftPost(new PostDraftRequest("hey", null)));
    }
}
