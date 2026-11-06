package org.example.subscriptionmicroservice.ai;

import org.example.subscriptionmicroservice.ai.PlanAdvisor.Activity;
import org.example.subscriptionmicroservice.ai.PlanAdvisor.Advice;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

/** IA du module 5 : le plan qui convient au freelancer. */
@RestController
@RequestMapping("/Subscription/ai")
public class PlanAdvisorController {

    public record AdviseRequest(Long userId, Activity activity) {}

    private final PlanAdvisor advisor;

    public PlanAdvisorController(PlanAdvisor advisor) {
        this.advisor = advisor;
    }

    @PostMapping("/advise")
    public Advice advise(@RequestBody AdviseRequest request) {
        if (request.userId() == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "userId is required");
        try {
            return advisor.advise(request.userId(), request.activity());
        } catch (IllegalStateException e) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
        }
    }
}
