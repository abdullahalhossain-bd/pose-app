package com.example.betagiesheva.Model;

import java.io.Serializable;
import java.util.Arrays;
import java.util.List;

public class UnifiedGovtOfficer implements Serializable {

    // Officer Type Constants
    public static final String TYPE_POLICE = "পুলিশ";
    public static final String TYPE_NURSE = "নার্স";
    public static final String TYPE_UPAZILA_DOCTOR = "উপজেলা ডাক্তার";
    public static final String TYPE_FIRE_SERVICE = "ফায়ার সার্ভিস";
    public static final String TYPE_VETERINARY_DOCTOR = "পশু চিকিৎসক";
    public static final String TYPE_LAW_ORDER = "আইন-শৃঙ্খলা";
    public static final String TYPE_EDUCATION = "শিক্ষা";
    public static final String TYPE_AGRICULTURE = "কৃষি";
    public static final String TYPE_HEALTH_ENVIRONMENT = "স্বাস্থ্য ও পরিবেশ";
    public static final String TYPE_ENGINEERING_ICT = "প্রকৌশল ও আইসিটি";
    public static final String TYPE_LAND_REVENUE = "ভূমি ও রাজস্ব";
    public static final String TYPE_HUMAN_RESOURCE = "মানব সম্পদ";
    public static final String TYPE_OTHER = "অন্যান্য";

    private String id;
    private String officerName;
    private String rank;
    private String mobileNumber;
    private String image;
    private String officerType;

    // Constructor
    public UnifiedGovtOfficer(String id, String officerName, String rank,
                              String mobileNumber, String image, String officerType) {
        this.id = id;
        this.officerName = officerName;
        this.rank = rank;
        this.mobileNumber = mobileNumber;
        this.image = image;
        this.officerType = officerType;
    }

    // Getters
    public String getId() {
        return id;
    }

    public String getOfficerName() {
        return officerName;
    }

    public String getRank() {
        return rank;
    }

    public String getMobileNumber() {
        return mobileNumber;
    }

    public String getImage() {
        return image;
    }

    public String getOfficerType() {
        return officerType;
    }

    // Setters
    public void setId(String id) {
        this.id = id;
    }

    public void setOfficerName(String officerName) {
        this.officerName = officerName;
    }

    public void setRank(String rank) {
        this.rank = rank;
    }

    public void setMobileNumber(String mobileNumber) {
        this.mobileNumber = mobileNumber;
    }

    public void setImage(String image) {
        this.image = image;
    }

    public void setOfficerType(String officerType) {
        this.officerType = officerType;
    }

    // Get all officer types for filter menu
    public static List<String> getAllOfficerTypes() {
        return Arrays.asList(
                TYPE_POLICE,
                TYPE_NURSE,
                TYPE_UPAZILA_DOCTOR,
                TYPE_FIRE_SERVICE,
                TYPE_VETERINARY_DOCTOR,
                TYPE_LAW_ORDER,
                TYPE_EDUCATION,
                TYPE_AGRICULTURE,
                TYPE_HEALTH_ENVIRONMENT,
                TYPE_ENGINEERING_ICT,
                TYPE_LAND_REVENUE,
                TYPE_HUMAN_RESOURCE,
                TYPE_OTHER
        );
    }
}