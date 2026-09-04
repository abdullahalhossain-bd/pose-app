package com.example.betagiesheva.Model;

import java.io.Serializable;

public class Complaint implements Serializable {

    private String userId;
    private String type;
    private String title;
    private String details;
    private String location;
    private String department;
    private String priority;
    private String contactNumber;
    private String email;
    private String complainantName;
    private String complaintDate;
    private String imageUrl;

    // Constructor with all fields
    public Complaint(String userId, String type, String title, String details, String location,
                     String department, String priority, String contactNumber, String email,
                     String complainantName, String complaintDate, String imageUrl) {
        this.userId = userId;
        this.type = type;
        this.title = title;
        this.details = details;
        this.location = location;
        this.department = department;
        this.priority = priority;
        this.contactNumber = contactNumber;
        this.email = email;
        this.complainantName = complainantName;
        this.complaintDate = complaintDate;
        this.imageUrl = imageUrl;
    }

    // Legacy constructor for backward compatibility
    public Complaint(String userId, String type, String details, String location, String imageUrl) {
        this.userId = userId;
        this.type = type;
        this.details = details;
        this.location = location;
        this.imageUrl = imageUrl;
    }

    // Getters
    public String getUserId() {
        return userId;
    }

    public String getType() {
        return type;
    }

    public String getTitle() {
        return title;
    }

    public String getDetails() {
        return details;
    }

    public String getLocation() {
        return location;
    }

    public String getDepartment() {
        return department;
    }

    public String getPriority() {
        return priority;
    }

    public String getContactNumber() {
        return contactNumber;
    }

    public String getEmail() {
        return email;
    }

    public String getComplainantName() {
        return complainantName;
    }

    public String getComplaintDate() {
        return complaintDate;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    // Setters
    public void setUserId(String userId) {
        this.userId = userId;
    }

    public void setType(String type) {
        this.type = type;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void setDetails(String details) {
        this.details = details;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public void setDepartment(String department) {
        this.department = department;
    }

    public void setPriority(String priority) {
        this.priority = priority;
    }

    public void setContactNumber(String contactNumber) {
        this.contactNumber = contactNumber;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setComplainantName(String complainantName) {
        this.complainantName = complainantName;
    }

    public void setComplaintDate(String complaintDate) {
        this.complaintDate = complaintDate;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
}
