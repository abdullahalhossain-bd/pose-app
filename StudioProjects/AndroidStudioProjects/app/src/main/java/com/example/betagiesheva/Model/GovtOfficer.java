package com.example.betagiesheva.Model;

public class GovtOfficer {

    // Officer type constants
    public static final String LAW_ORDER = "আইন শৃঙ্খলা বিষয়ক";
    public static final String EDUCATION = "শিক্ষা বিষয়ক";
    public static final String AGRICULTURE = "কৃষি,মৎস্য ও প্রাণী";
    public static final String HEALTH_ENVIRONMENT = "স্বাস্থ্য ও পরিবেশ বিষয়ক";
    public static final String ENGINEERING_ICT = "প্রকৌশলী ও ict";
    public static final String HUMAN_RESOURCE = "মানব সম্পদ উন্নয়ন";
    public static final String LAND_REVENUE = "ভূমি ও রাজস্ব";
    public static final String OTHER = "অনন্য";
    public static final String POLICE = "পুলিশ";
    public static final String NURSE = "নার্স";
    public static final String UPAZILA_DOCTOR = "উপজেলা ডাক্তার";
    public static final String FIRE_SERVICE = "ফায়ার সার্ভিস";
    public static final String VETERINARY_DOCTOR = "পশু ডাক্তার";

    private String id;
    private String officer_name;
    private String rank;
    private String mobile_number;
    private String image;
    private String officer_type;

    // Constructor
    public GovtOfficer(String id, String officer_name, String rank,
                       String mobile_number, String image, String officer_type) {
        this.id = id;
        this.officer_name = officer_name;
        this.rank = rank;
        this.mobile_number = mobile_number;
        this.image = image;
        this.officer_type = officer_type;
    }

    // Getters
    public String getId() {
        return id != null ? id : "";
    }

    public String getOfficerName() {
        return officer_name != null ? officer_name : "";
    }

    public String getRank() {
        return rank != null ? rank : "";
    }

    public String getMobileNumber() {
        return mobile_number != null ? mobile_number : "";
    }

    public String getImage() {
        return image != null ? image : "";
    }

    public String getOfficerType() {
        return officer_type != null ? officer_type : "";
    }

    // Static method to get all officer types
    public static String[] getAllTypes() {
        return new String[]{
                LAW_ORDER, EDUCATION, AGRICULTURE, HEALTH_ENVIRONMENT,
                ENGINEERING_ICT, HUMAN_RESOURCE, LAND_REVENUE, OTHER,
                POLICE, NURSE, UPAZILA_DOCTOR, FIRE_SERVICE, VETERINARY_DOCTOR
        };
    }
}
