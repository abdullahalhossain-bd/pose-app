package com.example.betagiesheva;

import androidx.annotation.NonNull;

public class UnifiedBusinessItem {

    // Business type constants
    public static final String TYPE_PHARMACY = "ফার্মেসি";
    public static final String TYPE_AMBULANCE = "অ্যাম্বুলেন্স";
    public static final String TYPE_NURSERY = "নার্সারি দোকান";
    public static final String TYPE_RESTAURANT = "রেস্টুরেন্ট";
    public static final String TYPE_TRAINING_CENTER = "প্রশিক্ষণ কেন্দ্র";
    public static final String TYPE_BEAUTY_PARLOR = "বিউটি পার্লার";
    public static final String TYPE_CAR_MECHANIC = "গাড়ি মেকার";
    public static final String TYPE_ELECTRICIAN = "ইলেক্ট্রনিকাল মেকার";
    public static final String TYPE_BUILDING_CONTRACTOR = "রাজমিস্ত্রি";
    public static final String TYPE_CARPENTER = "কাঠমিস্ত্রী";
    public static final String TYPE_PAINTER = "রং মিস্ত্রী";
    public static final String TYPE_TAILOR = "ট্রেইলর";
    public static final String TYPE_GROCERY_SHOP = "গ্রোসারি শপ";
    public static final String TYPE_FURNITURE_SHOP = "ফার্নিচার শপ";
    public static final String TYPE_CONCRETE_SHOP = "কংক্রিট শপ";
    public static final String TYPE_DECORATORS_SHOP = "ডেকারোটার্স শপ";
    public static final String TYPE_ELECTRONICS_SHOP = "ইলেকট্রনিক্স শপ";
    public static final String TYPE_JEWELERS_SHOP = "জুয়েলার্স শপ";
    public static final String TYPE_LIBRARY = "লাইব্রেরি";
    public static final String TYPE_CLOTHING_SHOP = "কাপরের দোকান";
    public static final String TYPE_ONLINE_SERVICE = "অনলাইন সার্ভিস";

    // Private fields matching database columns
    private String id;
    private String user_id;
    private String name;
    private String address;
    private String union_name;
    private String phone;
    private String business_type;
    private String image_url;
    private String details;
    private String proprietor_name;
    private String created_at;
    private String updated_at;

    // Empty constructor (required for JSON parsing)
    public UnifiedBusinessItem() {}

    // Full constructor
    public UnifiedBusinessItem(String id, String user_id, String name, String address,
                               String union_name, String phone, String business_type,
                               String image_url, String details, String proprietor_name,
                               String created_at, String updated_at) {
        this.id = id;
        this.user_id = user_id;
        this.name = name;
        this.address = address;
        this.union_name = union_name;
        this.phone = phone;
        this.business_type = business_type;
        this.image_url = image_url;
        this.details = details;
        this.proprietor_name = proprietor_name;
        this.created_at = created_at;
        this.updated_at = updated_at;
    }

    // Getters
    public String getId() {
        return id != null ? id : "";
    }

    public String getUserId() {
        return user_id != null ? user_id : "";
    }

    public String getName() {
        return name != null ? name : "";
    }

    public String getAddress() {
        return address != null ? address : "";
    }

    public String getUnionName() {
        return union_name != null ? union_name : "";
    }

    public String getPhone() {
        return phone != null ? phone : "";
    }

    public String getBusinessType() {
        return business_type != null ? business_type : "";
    }

    public String getImageUrl() {
        return image_url != null ? image_url : "";
    }

    public String getDetails() {
        return details != null ? details : "";
    }

    public String getProprietorName() {
        return proprietor_name != null ? proprietor_name : "";
    }

    public String getCreatedAt() {
        return created_at != null ? created_at : "";
    }

    public String getUpdatedAt() {
        return updated_at != null ? updated_at : "";
    }

    // Setters
    public void setId(String id) {
        this.id = id;
    }

    public void setUserId(String user_id) {
        this.user_id = user_id;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public void setUnionName(String union_name) {
        this.union_name = union_name;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public void setBusinessType(String business_type) {
        this.business_type = business_type;
    }

    public void setImageUrl(String image_url) {
        this.image_url = image_url;
    }

    public void setDetails(String details) {
        this.details = details;
    }

    public void setProprietorName(String proprietor_name) {
        this.proprietor_name = proprietor_name;
    }

    public void setCreatedAt(String created_at) {
        this.created_at = created_at;
    }

    public void setUpdatedAt(String updated_at) {
        this.updated_at = updated_at;
    }

    // Utility methods
    public boolean hasImage() {
        return image_url != null && !image_url.isEmpty() &&
                !image_url.equals("null") && !image_url.equals("NULL");
    }

    public boolean hasDetails() {
        return details != null && !details.isEmpty() &&
                !details.equals("null") && !details.equals("NULL");
    }

    public boolean hasProprietor() {
        return proprietor_name != null && !proprietor_name.isEmpty() &&
                !proprietor_name.equals("null") && !proprietor_name.equals("NULL");
    }

    public String getDisplayName() {
        if (hasProprietor()) {
            return name + " (" + proprietor_name + ")";
        }
        return name;
    }

    public String getFormattedCreatedDate() {
        if (created_at == null || created_at.isEmpty()) {
            return "";
        }

        try {
            // Parse the timestamp and format it (e.g., "2025-01-15 10:30:00" -> "2025-01-15")
            String[] parts = created_at.split(" ");
            if (parts.length >= 1) {
                return parts[0]; // Return date part only
            }
            return created_at;
        } catch (Exception e) {
            return created_at;
        }
    }

    public boolean isValid() {
        return id != null && !id.isEmpty() &&
                name != null && !name.isEmpty() &&
                phone != null && !phone.isEmpty();
    }

    @NonNull
    @Override
    public String toString() {
        return "UnifiedBusinessItem{" +
                "id='" + id + '\'' +
                ", user_id='" + user_id + '\'' +
                ", name='" + name + '\'' +
                ", address='" + address + '\'' +
                ", union_name='" + union_name + '\'' +
                ", phone='" + phone + '\'' +
                ", business_type='" + business_type + '\'' +
                ", image_url='" + image_url + '\'' +
                ", details='" + details + '\'' +
                ", proprietor_name='" + proprietor_name + '\'' +
                ", created_at='" + created_at + '\'' +
                ", updated_at='" + updated_at + '\'' +
                '}';
    }
}