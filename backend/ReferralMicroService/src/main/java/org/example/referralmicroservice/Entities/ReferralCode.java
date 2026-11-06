package org.example.referralmicroservice.Entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "referral_codes")
@Data
public class ReferralCode {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long userId;
    @Column(unique = true)
    private String code;

    @OneToMany(mappedBy = "referralCodeRef", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<Referral> referrals = new ArrayList<>();
}
