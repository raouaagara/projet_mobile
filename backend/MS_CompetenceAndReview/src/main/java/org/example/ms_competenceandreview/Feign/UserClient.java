package org.example.ms_competenceandreview.Feign;

import org.example.ms_competenceandreview.DTO.UserDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.http.ResponseEntity;

@FeignClient(
        name = "UserMicroService",
        url = "http://localhost:8083",
        configuration = FeignConfig.class
)
public interface UserClient {
    @GetMapping("/users/{id}")
    UserDTO getUserById(@PathVariable("id") Long id);
}