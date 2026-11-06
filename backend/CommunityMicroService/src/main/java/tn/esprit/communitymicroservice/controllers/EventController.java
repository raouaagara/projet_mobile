package tn.esprit.communitymicroservice.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import tn.esprit.communitymicroservice.entities.Event;
import tn.esprit.communitymicroservice.entities.EventStatus;
import tn.esprit.communitymicroservice.services.EventService;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/events")
public class EventController {
    @Autowired
    private EventService eventService;

    @PostMapping
    public Event createEvent(@RequestBody Event event) {
        return eventService.createEvent(event);
    }

    @GetMapping
    public List<Event> getAllEvents() {
        return eventService.getAllEvents();
    }

    @GetMapping("/{id}")
    public Event getEventById(@PathVariable Long id) {
        return eventService.getEventById(id);
    }

    @GetMapping("/group/{groupId}")
    public List<Event> getEventsByGroupId(@PathVariable Long groupId) {
        return eventService.getEventsByGroupId(groupId);
    }

    @GetMapping("/club/{clubId}")
    public List<Event> getEventsByClubId(@PathVariable Long clubId) {
        return eventService.getEventsByClubId(clubId);
    }

    @PutMapping("/{id}")
    public Event updateEvent(@PathVariable Long id, @RequestBody Event event) {
        return eventService.updateEvent(id, event);
    }

    @DeleteMapping("/{id}")
    public void deleteEvent(@PathVariable Long id) {
        eventService.deleteEvent(id);
    }

    @PutMapping("/{id}/approve")
    public Event approveEvent(@PathVariable Long id) {
        Event event = eventService.getEventById(id);
        event.setStatus(EventStatus.APPROVED);
        return eventService.updateEvent(id, event);
    }

    @PutMapping("/{id}/reject")
    public Event rejectEvent(@PathVariable Long id) {
        Event event = eventService.getEventById(id);
        event.setStatus(EventStatus.REJECTED);
        return eventService.updateEvent(id, event);
    }

    @GetMapping("/pending")
    public List<Event> getPendingEvents() {
        List<Event> allEvents = eventService.getAllEvents();
        return allEvents.stream()
                .filter(event -> EventStatus.PENDING.equals(event.getStatus()))
                .collect(Collectors.toList());
    }
}
