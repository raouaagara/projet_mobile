package org.example.subscriptionmicroservice.Repositories;

import org.example.subscriptionmicroservice.Entities.PromoCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PromoCodeRepository extends JpaRepository<PromoCode, Long> {
    Optional<PromoCode> findByCode(String code);
    
    List<PromoCode> findByUserId(Long userId);
    
    List<PromoCode> findByUserIdAndIsActiveTrue(Long userId);
    
    List<PromoCode> findByUserIdAndUsedAtIsNull(Long userId);
    
    List<PromoCode> findByUserIdAndUsedAtIsNullAndExpiresAtAfter(Long userId, LocalDateTime now);
    
    boolean existsByUserIdAndType(Long userId, PromoCode.PromoCodeType type);
    
    Optional<PromoCode> findByUserIdAndType(Long userId, PromoCode.PromoCodeType type);
    
    List<PromoCode> findByExpiresAtBeforeAndIsActiveTrue(LocalDateTime date);
}
