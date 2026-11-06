package org.example.technicalsupport.dto;

public class AddResponseRequest {
    private Long responderId;
    private String responderName;
    private boolean isStaff;
    private String message;

    public Long getResponderId() { return responderId; }
    public void setResponderId(Long responderId) { this.responderId = responderId; }
    public String getResponderName() { return responderName; }
    public void setResponderName(String responderName) { this.responderName = responderName; }
    public boolean isStaff() { return isStaff; }
    public void setStaff(boolean staff) { isStaff = staff; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}
