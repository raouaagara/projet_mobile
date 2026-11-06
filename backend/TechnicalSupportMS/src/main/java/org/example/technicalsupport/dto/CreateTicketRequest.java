package org.example.technicalsupport.dto;

public class CreateTicketRequest {
    private Long userId;
    private String userEmail;
    private String userName;
    private String title;
    private String description;
    private String priority;   // "LOW", "MEDIUM", "HIGH", "CRITICAL" or null
    private String category;   // enum name or null for auto-detect

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }
    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
}
