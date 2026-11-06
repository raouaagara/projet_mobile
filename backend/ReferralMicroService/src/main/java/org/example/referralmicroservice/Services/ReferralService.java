package org.example.referralmicroservice.Services;

import org.example.referralmicroservice.Entities.Referral;
import org.example.referralmicroservice.Entities.ReferralCode;
import org.example.referralmicroservice.Entities.ReferralReward;
import org.example.referralmicroservice.Repositories.ReferralCodeRepository;
import org.example.referralmicroservice.Repositories.ReferralRepository;
import org.example.referralmicroservice.Repositories.ReferralRewardRepository;
import org.example.referralmicroservice.Entities.RewardTransaction;
import org.example.referralmicroservice.Entities.UserWallet;
import org.example.referralmicroservice.Repositories.RewardTransactionRepository;
import org.example.referralmicroservice.Repositories.UserWalletRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class ReferralService {

    @Autowired
    private ReferralRepository referralRepo;

    @Autowired
    private ReferralCodeRepository codeRepo;

    @Autowired
    private ReferralRewardRepository rewardRepo;

    @Autowired
    private WalletService walletService;

    @Autowired
    private UserWalletRepository walletRepo;

    @Autowired
    private RewardTransactionRepository transactionRepo;

    @Autowired
    private ReferralGuard guard;

    /** What the referrer earns in their reward wallet when someone joins with their code. */
    public static final double REFERRAL_BONUS = 5.0;

    public String getOrCreateReferralCode(Long userId) {
        return codeRepo.findByUserId(userId)
                .map(ReferralCode::getCode)
                .orElseGet(() -> {
                    String code = "CATCH-" + userId + "-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
                    ReferralCode rc = new ReferralCode();
                    rc.setUserId(userId);
                    rc.setCode(code);
                    return codeRepo.save(rc).getCode();
                });
    }

    public ReferralCode createReferralCode(ReferralCode rc) {
        return codeRepo.save(rc);
    }

    public ReferralCode getReferralCodeById(Long id) {
        return codeRepo.findById(id).orElseThrow(() -> new RuntimeException("ReferralCode not found"));
    }

    public ReferralCode updateReferralCode(Long id, ReferralCode updates) {
        ReferralCode existing = getReferralCodeById(id);
        if (updates.getUserId() != null) existing.setUserId(updates.getUserId());
        if (updates.getCode() != null) existing.setCode(updates.getCode());
        return codeRepo.save(existing);
    }

    public void deleteReferralCode(Long id) {
        codeRepo.deleteById(id);
    }

    public List<ReferralCode> getAllReferralCodes() {
        return codeRepo.findAll();
    }

    /**
     * [referredUserId] joined with [code]: records the referral and rewards the referrer
     * (it used to create no reward, so "earned" stayed at 0). One referral per new user, not your own code.
     */
    @Transactional
    public Referral createReferral(String code, Long referredUserId) {
        if (referredUserId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "referredUserId is required");
        }
        ReferralCode rc = codeRepo.findByCode(code == null ? "" : code.trim())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "This referral code doesn't exist."));
        if (rc.getUserId().equals(referredUserId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "You can't use your own referral code.");
        }
        if (referralRepo.existsByReferredUserId(referredUserId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "You already used a referral code.");
        }
        ReferralGuard.Check check = guard.check(referralRepo.findByReferrerUserId(rc.getUserId()), referredUserId,
                java.time.LocalDateTime.now());
        Referral r = new Referral();
        r.setReferrerUserId(rc.getUserId());
        r.setReferredUserId(referredUserId);
        r.setReferralCode(code);
        r.setReferralCodeRef(rc);
        r.setStatus(check.suspicious() ? "UNDER_REVIEW" : "COMPLETED");
        Referral saved = referralRepo.save(r);
        if (check.suspicious()) {
            // Kept for an admin to check; the bonus waits (see ReferralGuard).
            System.err.println("⚠️ [REFERRAL] held for review, code " + code + ": " + String.join("; ", check.reasons()));
            return saved;
        }

        ReferralReward reward = new ReferralReward();
        reward.setReferral(saved);
        reward.setUserId(rc.getUserId());
        reward.setRewardType("REFERRAL_SIGNUP");
        reward.setAmount(REFERRAL_BONUS);
        reward.setClaimed(true);
        rewardRepo.save(reward);

        UserWallet wallet = walletService.getOrCreateWallet(rc.getUserId());
        wallet.setBalance(wallet.getBalance() + REFERRAL_BONUS);
        wallet.setTotalEarned(wallet.getTotalEarned() + REFERRAL_BONUS);
        wallet.setUpdatedAt(java.time.LocalDateTime.now());
        walletRepo.save(wallet);
        transactionRepo.save(new RewardTransaction(rc.getUserId(), REFERRAL_BONUS, RewardTransaction.RewardType.REFERRAL_BONUS,
                wallet.getCertificationsCount(), wallet.getCurrentTier(), "Referral bonus: a friend joined with your code"));
        return saved;
    }

    public Referral getReferralById(Long id) {
        return referralRepo.findById(id).orElseThrow(() -> new RuntimeException("Referral not found"));
    }

    public Referral updateReferral(Long id, Referral updates) {
        Referral existing = getReferralById(id);
        if (updates.getReferrerUserId() != null) existing.setReferrerUserId(updates.getReferrerUserId());
        if (updates.getReferredUserId() != null) existing.setReferredUserId(updates.getReferredUserId());
        if (updates.getStatus() != null) existing.setStatus(updates.getStatus());
        return referralRepo.save(existing);
    }

    public void deleteReferral(Long id) {
        referralRepo.deleteById(id);
    }

    public List<Referral> getAllReferrals() {
        return referralRepo.findAll();
    }

    public ReferralReward createReferralReward(Long referralId, Long userId, String rewardType, Double amount) {
        Referral referral = getReferralById(referralId);
        ReferralReward rw = new ReferralReward();
        rw.setReferral(referral);
        rw.setUserId(userId);
        rw.setRewardType(rewardType);
        rw.setAmount(amount);
        return rewardRepo.save(rw);
    }

    public ReferralReward getReferralRewardById(Long id) {
        return rewardRepo.findById(id).orElseThrow(() -> new RuntimeException("ReferralReward not found"));
    }

    public ReferralReward updateReferralReward(Long id, ReferralReward updates) {
        ReferralReward existing = getReferralRewardById(id);
        if (updates.getUserId() != null) existing.setUserId(updates.getUserId());
        if (updates.getRewardType() != null) existing.setRewardType(updates.getRewardType());
        if (updates.getAmount() != null) existing.setAmount(updates.getAmount());
        if (updates.getClaimed() != null) existing.setClaimed(updates.getClaimed());
        return rewardRepo.save(existing);
    }

    public void deleteReferralReward(Long id) {
        rewardRepo.deleteById(id);
    }

    public List<ReferralReward> getAllReferralRewards() {
        return rewardRepo.findAll();
    }

    public List<Referral> getReferralsByUser(Long userId) {
        return referralRepo.findByReferrerUserId(userId);
    }

    public List<ReferralReward> getUserRewards(Long userId) {
        return rewardRepo.findByUserId(userId);
    }

    public double getTotalEarned(Long userId) {
        return rewardRepo.findByUserId(userId).stream()
                .filter(ReferralReward::getClaimed)
                .mapToDouble(r -> r.getAmount() != null ? r.getAmount() : 0)
                .sum();
    }
}
