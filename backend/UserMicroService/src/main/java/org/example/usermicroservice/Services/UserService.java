package org.example.usermicroservice.Services;

import org.example.usermicroservice.Entities.User;
import org.example.usermicroservice.Repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public User registerUser(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new RuntimeException("Cet email est déjà utilisé !");
        }
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        return userRepository.save(user);
    }

    public User loginUser(User loginData) {
        Optional<User> userOpt = userRepository.findByEmail(loginData.getEmail());

        if (userOpt.isPresent()) {
            User user = userOpt.get();
            if (passwordEncoder.matches(loginData.getPassword(), user.getPassword())) {
                return user; // Succès
            }
        }
        throw new RuntimeException("Email ou mot de passe incorrect.");
    }

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public Optional<User> getUserById(Long id) {
        return userRepository.findById(id);
    }

    public void deleteUser(Long id) {
        if (!userRepository.existsById(id)) {
            throw new RuntimeException("Utilisateur introuvable.");
        }
        userRepository.deleteById(id);
    }

    public User updateUser(Long id, User userDetails) {

        User existingUser = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Utilisateur introuvable."));

        existingUser.setFirstName(userDetails.getFirstName());
        existingUser.setLastName(userDetails.getLastName());
        existingUser.setBio(userDetails.getBio());
        existingUser.setLocation(userDetails.getLocation());
        existingUser.setProfilePictureUrl(userDetails.getProfilePictureUrl());
        existingUser.setWebsite(userDetails.getWebsite());
        existingUser.setLinkedinUrl(userDetails.getLinkedinUrl());
        existingUser.setCoverPictureUrl(userDetails.getCoverPictureUrl());
        return userRepository.save(existingUser);
    }
}