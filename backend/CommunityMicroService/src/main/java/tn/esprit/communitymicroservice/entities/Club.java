package tn.esprit.communitymicroservice.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "clubs")
public class Club {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    private String bannerUrl;

    private String interests;

    private Long creatorId;

    private LocalDateTime createdAt;

    @Column(nullable = false)
    private String status = "ACTIVE"; // ACTIVE or PAUSED
}

