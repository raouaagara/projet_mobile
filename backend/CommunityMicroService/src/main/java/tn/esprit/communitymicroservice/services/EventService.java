package tn.esprit.communitymicroservice.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import tn.esprit.communitymicroservice.entities.Event;
import tn.esprit.communitymicroservice.repositories.EventRepository;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class EventService {
    @Autowired
    private EventRepository eventRepository;

    public Event createEvent(Event event) {
        event.setCreatedAt(LocalDateTime.now());
        if (event.getStatus() == null) {
            // Members' events wait for an admin (the column is required: without this, creating failed).
            event.setStatus(tn.esprit.communitymicroservice.entities.EventStatus.PENDING);
        }
        return eventRepository.save(event);
    }

    public List<Event> getAllEvents() {
        return eventRepository.findAll();
    }

    public Event getEventById(Long id) {
        return eventRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));
    }

    public List<Event> getEventsByGroupId(Long groupId) {
        return eventRepository.findByGroupId(groupId);
    }

    public List<Event> getEventsByClubId(Long clubId) {
        return eventRepository.findByClubId(clubId);
    }

    public Event updateEvent(Long id, Event updated) {
        Event event = getEventById(id);
        event.setTitle(updated.getTitle());
        event.setDescription(updated.getDescription());
        event.setLocation(updated.getLocation());
        event.setStartDate(updated.getStartDate());
        event.setEndDate(updated.getEndDate());
        return eventRepository.save(event);
    }

    public void deleteEvent(Long id) {
        eventRepository.deleteById(id);
    }
}
