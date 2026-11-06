package org.example.technicalsupport.controller;

import org.example.technicalsupport.service.HelpAssistantService;
import org.example.technicalsupport.service.HelpAssistantService.Answer;
import org.example.technicalsupport.service.HelpAssistantService.Turn;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

/** The help assistant before a support request (under /api/tickets so the gateway already routes it). */
@RestController
@RequestMapping("/api/tickets/assistant")
public class HelpAssistantController {

    public record AskRequest(String question, List<Turn> history) {}

    private final HelpAssistantService assistant;

    public HelpAssistantController(HelpAssistantService assistant) {
        this.assistant = assistant;
    }

    @PostMapping("/ask")
    public Answer ask(@RequestBody AskRequest request) {
        try {
            return assistant.ask(request.question(), request.history());
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }
}
