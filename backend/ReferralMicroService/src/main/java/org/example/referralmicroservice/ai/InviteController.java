package org.example.referralmicroservice.ai;

import org.example.referralmicroservice.ai.InviteWriter.InviteRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

/** IA du module 5 : message d'invitation avec le code de parrainage. */
@RestController
@RequestMapping("/Referral/ai")
public class InviteController {

    private final InviteWriter writer;

    public InviteController(InviteWriter writer) {
        this.writer = writer;
    }

    @PostMapping("/invite")
    public Map<String, String> invite(@RequestBody InviteRequest request) {
        try {
            return Map.of("message", writer.write(request));
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }
}
