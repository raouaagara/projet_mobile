package org.example.skilltestsmicroservice.ai;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

/** Une fonction d'IA indisponible répond 503 avec un message clair, que l'application affiche. */
@RestControllerAdvice
public class AiExceptionHandler {

    @ExceptionHandler(AiUnavailableException.class)
    public ResponseEntity<Map<String, String>> aiUnavailable(AiUnavailableException e) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("message", e.getMessage()));
    }
}
