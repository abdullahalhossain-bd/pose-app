package com.example.betagiesheva.Model;

import java.io.Serializable;

public class UnifiedGovtItem implements Serializable {

    private int id;
    private String name;
    private String address;
    private String phoneNumber;
    private ItemType itemType;
    private String imgUrl;
    private String union;
    private String createdAt;
    private String updatedAt;

    // Constructor
    public UnifiedGovtItem() {
        this.id = 0;
        this.name = "";
        this.address = "";
        this.phoneNumber = "";
        this.itemType = null;
        this.imgUrl = "";
        this.union = "";
        this.createdAt = "";
        this.updatedAt = "";
    }

    // Constructor with parameters
    public UnifiedGovtItem(int id, String name, String address, String phoneNumber,
                          ItemType itemType, String imgUrl, String union, String createdAt, String updatedAt) {
        this.id = id;
        this.name = name;
        this.address = address;
        this.phoneNumber = phoneNumber;
        this.itemType = itemType;
        this.imgUrl = imgUrl;
        this.union = union;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    // Getters and Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public ItemType getItemType() {
        return itemType;
    }

    public void setItemType(ItemType itemType) {
        this.itemType = itemType;
    }

    public String getImgUrl() {
        return imgUrl;
    }

    public void setImgUrl(String imgUrl) {
        this.imgUrl = imgUrl;
    }

    public String getUnion() {
        return union;
    }

    public void setUnion(String union) {
        this.union = union;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }

    // Enum for item types
    public enum ItemType {
        COURIER("কুরিয়ার"),
        BANK("ব্যাংক"),
        COACHING_CENTER("কোচিং সেন্টার");

        private final String displayName;

        ItemType(String displayName) {
            this.displayName = displayName;
        }

        public String getDisplayName() {
            return displayName;
        }

        public static ItemType fromDisplayName(String displayName) {
            for (ItemType type : ItemType.values()) {
                if (type.displayName.equals(displayName)) {
                    return type;
                }
            }
            return null;
        }
    }

    // Helper method to get display name of item type
    public String getItemTypeDisplayName() {
        return itemType != null ? itemType.getDisplayName() : "";
    }
}
