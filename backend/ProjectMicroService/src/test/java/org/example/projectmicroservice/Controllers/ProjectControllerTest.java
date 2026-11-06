package org.example.projectmicroservice.Controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.projectmicroservice.Entities.Project;
import org.example.projectmicroservice.Repositories.NotificationRepository;
import org.example.projectmicroservice.Services.ProjectService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

@WebMvcTest(ProjectController.class)
class ProjectControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ProjectService projectService;

    @MockitoBean
    private NotificationRepository notificationRepository; // Need to mock because it's Autowired in Controller

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldCreateNewProject() throws Exception {
        Project project = new Project();
        project.setTitle("New Web App");
        project.setBudget(2000.0);

        when(projectService.createProject(any(Project.class))).thenReturn(project);

        mockMvc.perform(post("/Project/newproject")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(project)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("New Web App"));
    }
}