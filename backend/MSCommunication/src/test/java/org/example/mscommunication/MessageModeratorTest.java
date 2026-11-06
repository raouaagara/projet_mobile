package org.example.mscommunication;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class MessageModeratorTest {

    private final MessageModerator moderator = new MessageModerator();

    private String category(String text) {
        return moderator.check(text).map(MessageModerator.Verdict::category).orElse("ok");
    }

    @Test
    void blocksThreatsInsultsHateAndHarassment() {
        assertEquals("violence", category("If you don't pay I will kill you"));
        assertEquals("violence", category("Je vais te tuer"));
        assertEquals("violence", category("va crève"));
        assertEquals("hate", category("I hate you and your work"));
        assertEquals("hate", category("je te déteste"));
        assertEquals("harassment", category("You are an idiot"));
        assertEquals("harassment", category("you're so useless"));
        assertEquals("harassment", category("f**k you"));
        assertEquals("harassment", category("Espèce de connard"));
        assertEquals("harassment", category("ferme ta gueule"));
        assertEquals("sexual", category("send nudes"));
    }

    @Test
    void letsNormalWorkMessagesThrough() {
        assertEquals("ok", category("Hello, I finished the login screen, can you review it?"));
        assertEquals("ok", category("I hate this bug, it crashes on Android 12"));
        assertEquals("ok", category("We need to kill the process before the deploy"));
        assertEquals("ok", category("Le client est d'accord pour le paiement demain"));
        assertEquals("ok", category("Bonjour, je vais te tutoyer si ça te va"));
        assertEquals("ok", category(""));
        assertTrue(moderator.check(null).isEmpty());
    }
}
