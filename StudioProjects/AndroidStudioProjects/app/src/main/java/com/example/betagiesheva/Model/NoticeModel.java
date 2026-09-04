package com.example.betagiesheva.Model;

import java.io.Serializable;
import java.util.ArrayList;

public class NoticeModel implements Serializable {

    private String id;
    private String title;
    private String description;
    private String type; // গুরুত্বপূর্ণ, সাধারণ, ইভেন্ট, ছুটি
    private String date;
    private String department;
    private String imageUrl;
    private int attachmentCount;
    private ArrayList<String> attachmentUrls;

    // Constructor with attachment count
    public NoticeModel(String id, String title, String description,
                       String type, String date, String department,
                       String imageUrl, int attachmentCount) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.type = type != null && !type.isEmpty() ? type : "সাধারণ"; // Default type
        this.date = date;
        this.department = department;
        this.imageUrl = imageUrl;
        this.attachmentCount = attachmentCount;
        this.attachmentUrls = new ArrayList<>();
    }

    // Getters
    public String getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public String getType() {
        return type;
    }

    public String getDate() {
        return date;
    }

    public String getDepartment() {
        return department;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public int getAttachmentCount() {
        return attachmentCount;
    }

    public ArrayList<String> getAttachmentUrls() {
        return attachmentUrls;
    }

    // Setters
    public void setId(String id) {
        this.id = id;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setType(String type) {
        this.type = type;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public void setDepartment(String department) {
        this.department = department;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public void setAttachmentCount(int attachmentCount) {
        this.attachmentCount = attachmentCount;
    }

    // Add a single attachment URL
    public void addAttachmentUrl(String url) {
        if (url != null && !url.isEmpty()) {
            attachmentUrls.add(url);
        }
    }

    // Set a single attachment (for backward compatibility)
    public void setAttachmentUrl(String attachmentUrl) {
        if (attachmentUrl != null && !attachmentUrl.isEmpty()) {
            attachmentUrls.clear();
            attachmentUrls.add(attachmentUrl);
        }
    }

    // Set multiple attachments at once
    public void setAttachmentUrls(ArrayList<String> urls) {
        this.attachmentUrls = urls != null ? urls : new ArrayList<>();
        this.attachmentCount = this.attachmentUrls.size();
    }

    // Get first attachment URL (for backward compatibility)
    public String getFirstAttachmentUrl() {
        return attachmentUrls.isEmpty() ? "" : attachmentUrls.get(0);
    }
}