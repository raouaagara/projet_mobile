package org.example.referralmicroservice.Controllers;

import org.example.referralmicroservice.Entities.Referral;
import org.example.referralmicroservice.Entities.ReferralCode;
import org.example.referralmicroservice.Entities.ReferralReward;
import org.example.referralmicroservice.Services.ReferralService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/Referral")
@CrossOrigin(origins = "http://localhost")
public class ReferralController {

    @Autowired
    private ReferralService service;

    @GetMapping("/code/{userId}")
    public String getReferralCode(@PathVariable Long userId) {
        return service.getOrCreateReferralCode(userId);
    }

    @GetMapping("/referrals/{userId}")
    public List<Referral> getUserReferrals(@PathVariable Long userId) {
        return service.getReferralsByUser(userId);
    }

    @GetMapping("/rewards/{userId}")
    public List<ReferralReward> getUserRewards(@PathVariable Long userId) {
        return service.getUserRewards(userId);
    }

    @GetMapping("/earned/{userId}")
    public double getTotalEarned(@PathVariable Long userId) {
        return service.getTotalEarned(userId);
    }

    @PostMapping("/use/{code}")
    public Referral useReferralCode(@PathVariable String code, @RequestParam Long referredUserId) {
        return service.createReferral(code, referredUserId);
    }

    @GetMapping("/admin/codes")
    public java.util.List<ReferralCode> getAllReferralCodes() {
        return service.getAllReferralCodes();
    }

    @PostMapping("/admin/codes")
    public ReferralCode createReferralCode(@RequestBody ReferralCode rc) {
        return service.createReferralCode(rc);
    }

    @GetMapping("/admin/codes/{id}")
    public ReferralCode getReferralCodeById(@PathVariable Long id) {
        return service.getReferralCodeById(id);
    }

    @PutMapping("/admin/codes/{id}")
    public ReferralCode updateReferralCode(@PathVariable Long id, @RequestBody ReferralCode rc) {
        return service.updateReferralCode(id, rc);
    }

    @DeleteMapping("/admin/codes/{id}")
    public void deleteReferralCode(@PathVariable Long id) {
        service.deleteReferralCode(id);
    }

    @GetMapping("/admin/referrals")
    public java.util.List<Referral> getAllReferrals() {
        return service.getAllReferrals();
    }

    @GetMapping("/admin/referrals/{id}")
    public Referral getReferralById(@PathVariable Long id) {
        return service.getReferralById(id);
    }

    @PutMapping("/admin/referrals/{id}")
    public Referral updateReferral(@PathVariable Long id, @RequestBody Referral r) {
        return service.updateReferral(id, r);
    }

    @DeleteMapping("/admin/referrals/{id}")
    public void deleteReferral(@PathVariable Long id) {
        service.deleteReferral(id);
    }

    @GetMapping("/admin/rewards")
    public java.util.List<ReferralReward> getAllReferralRewards() {
        return service.getAllReferralRewards();
    }

    @PostMapping("/admin/rewards")
    public ReferralReward createReferralReward(@RequestParam Long referralId, @RequestParam Long userId,
                                               @RequestParam String rewardType, @RequestParam Double amount) {
        return service.createReferralReward(referralId, userId, rewardType, amount);
    }

    @GetMapping("/admin/rewards/{id}")
    public ReferralReward getReferralRewardById(@PathVariable Long id) {
        return service.getReferralRewardById(id);
    }

    @PutMapping("/admin/rewards/{id}")
    public ReferralReward updateReferralReward(@PathVariable Long id, @RequestBody ReferralReward rw) {
        return service.updateReferralReward(id, rw);
    }

    @DeleteMapping("/admin/rewards/{id}")
    public void deleteReferralReward(@PathVariable Long id) {
        service.deleteReferralReward(id);
    }
}

