package org.example.usermicroservice.Controllers;


import org.example.usermicroservice.Entities.SecurityConfig;
import org.example.usermicroservice.Entities.User;
import org.example.usermicroservice.Repositories.UserRepository;
import org.example.usermicroservice.Services.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.List;

@RestController
@RequestMapping("/users")
public class UserController {

    @Autowired
    private UserService userService;
    @Autowired
    private SecurityConfig jwtUtil;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        try {
            User savedUser = userService.registerUser(user);
            return new ResponseEntity<>(savedUser, HttpStatus.CREATED);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User loginData) {
        try {
            User loggedInUser = userService.loginUser(loginData); // ou userRepository si tu n'utilises pas le service

            // 🟢 On génère le token sécurisé
            String token = jwtUtil.generateToken(
                    loggedInUser.getId(),
                    loggedInUser.getEmail(),
                    loggedInUser.getRole().name()
            );


            return ResponseEntity.ok(Collections.singletonMap("token", token));

        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        }
    }

    @GetMapping("/all")
    public List<User> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        return userService.getUserById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        try {
            userService.deleteUser(id);
            return ResponseEntity.ok("Utilisateur supprimé avec succès.");
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody User userDetails) {
        try {
            User updatedUser = userService.updateUser(id, userDetails);
            return ResponseEntity.ok(updatedUser);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body("Erreur lors de la mise à jour: " + e.getMessage());
        }
    }


    @Autowired
    private UserRepository userRepo;

    @PostMapping("/{userId}/competences")
    public ResponseEntity<?> addCompetencesToUser(@PathVariable Long userId, @RequestBody List<Long> competenceIds) {
        try {
            User user = userRepo.findById(userId)
                    .orElseThrow(() -> new RuntimeException("L'utilisateur avec l'ID " + userId + " N'EXISTE PAS dans la base de données MySQL !"));

            user.setCompetenceIds(competenceIds);
            userRepo.save(user);

            return ResponseEntity.ok("Competences updated successfully");

        } catch (Exception e) {
            e.printStackTrace(); // Affiche la cause dans IntelliJ

            return ResponseEntity.internalServerError().body("ERREUR BACKEND USER : " + e.getMessage());
        }
    }
    @PostMapping("/{id}/upload-cv")
    public ResponseEntity<?> uploadCv(@PathVariable Long id, @RequestParam("file") org.springframework.web.multipart.MultipartFile file) {
        System.out.println("🚨 [USER-MS] Début de l'upload du CV pour le User ID: " + id);
        try {
            User user = userRepo.findById(id).orElseThrow(() -> new RuntimeException("User not found"));
            String fileName = file.getOriginalFilename();

            // 🟢 NOUVEAU : On vérifie et on crée le dossier "uploads" automatiquement !
            java.nio.file.Path uploadDir = java.nio.file.Paths.get("uploads");
            if (!java.nio.file.Files.exists(uploadDir)) {
                java.nio.file.Files.createDirectories(uploadDir);
                System.out.println("✅ [USER-MS] Dossier 'uploads' créé avec succès !");
            }

            // Sauvegarde du fichier
            java.nio.file.Path filePath = uploadDir.resolve(fileName).normalize();
            file.transferTo(filePath);

            user.setCvFileName(fileName);
            userRepo.save(user);

            java.util.Map<String, String> response = new java.util.HashMap<>();
            response.put("message", "CV uploaded successfully");

            System.out.println("✅ [USER-MS] Fichier sauvegardé : " + fileName);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.err.println("❌ [USER-CRASH] Erreur Upload : " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("ERREUR UPLOAD : " + e.getMessage());
        }
    }
    @GetMapping("/download-cv/{filename:.+}")
    public ResponseEntity<org.springframework.core.io.Resource> downloadUserCv(@PathVariable String filename) {
        try {
            java.nio.file.Path filePath = java.nio.file.Paths.get("uploads").resolve(filename).normalize();
            org.springframework.core.io.Resource resource = new org.springframework.core.io.UrlResource(filePath.toUri());

            if (resource.exists() || resource.isReadable()) {
                return ResponseEntity.ok()
                        .header(org.springframework.http.HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                throw new RuntimeException("Fichier introuvable");
            }
        } catch (Exception e) {
            throw new RuntimeException("Erreur : " + e.getMessage());
        }
    }
}
