package org.example.projectmicroservice.DTO;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/** Une compétence du catalogue du service Competence (champs en français, comme son JSON). */
@JsonIgnoreProperties(ignoreUnknown = true)
public record CompetenceDto(Long id, String nom, String categorie) {}
