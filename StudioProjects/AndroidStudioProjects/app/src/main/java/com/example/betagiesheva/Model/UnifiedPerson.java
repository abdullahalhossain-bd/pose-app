package com.example.betagiesheva.Model;

import android.os.Parcel;
import android.os.Parcelable;

public class UnifiedPerson implements Parcelable {

    private String id;
    private String name;
    private String phone;
    private String address;
    private String union;
    private String imageUrl;
    private String personType;

    // Type constants (Bengali)
    public static final String TYPE_GHATOK = "ঘটক";
    public static final String TYPE_JOURNALIST = "সাংবাদিক";
    public static final String TYPE_COACHING_CENTER = "কোচিং";
    public static final String TYPE_DEED_WRITER = "দলিল লেখক";
    public static final String TYPE_SURVEYOR = "জরিপকারী";

    // Empty constructor (required for Firebase / Gson)
    public UnifiedPerson() {
    }

    // Full constructor
    public UnifiedPerson(String id, String name, String phone, String address,
                         String union, String imageUrl, String personType) {
        this.id = id;
        this.name = name;
        this.phone = phone;
        this.address = address;
        this.union = union;
        this.imageUrl = imageUrl;
        this.personType = personType;
    }

    // Parcelable constructor
    protected UnifiedPerson(Parcel in) {
        id = in.readString();
        name = in.readString();
        phone = in.readString();
        address = in.readString();
        union = in.readString();
        imageUrl = in.readString();
        personType = in.readString();
    }

    public static final Creator<UnifiedPerson> CREATOR = new Creator<UnifiedPerson>() {
        @Override
        public UnifiedPerson createFromParcel(Parcel in) {
            return new UnifiedPerson(in);
        }

        @Override
        public UnifiedPerson[] newArray(int size) {
            return new UnifiedPerson[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(id);
        dest.writeString(name);
        dest.writeString(phone);
        dest.writeString(address);
        dest.writeString(union);
        dest.writeString(imageUrl);
        dest.writeString(personType);
    }

    public static String getEnglishType(String title) {
        return title;
    }

    // Getters & Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getUnion() {
        return union;
    }

    public void setUnion(String union) {
        this.union = union;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getPersonType() {
        return personType;
    }

    public void setPersonType(String personType) {
        this.personType = personType;
    }

    // Helper: Bengali display name
    public static String getBengaliTypeName(String type) {
        if (type == null) return "";
        switch (type) {
            case TYPE_GHATOK:
                return "ঘটক";
            case TYPE_JOURNALIST:
                return "সাংবাদিক";
            case TYPE_COACHING_CENTER:
                return "কোচিং সেন্টার";
            case TYPE_DEED_WRITER:
                return "দলিল লেখক";
            case TYPE_SURVEYOR:
                return "সার্ভেয়ার";
            default:
                return "";
        }
    }
}
