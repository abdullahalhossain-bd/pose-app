package com.example.betagiesheva.Model;

import android.os.Parcel;
import android.os.Parcelable;

public class UnifiedSpecialistDoctor implements Parcelable {
    private String id;
    private String name;
    private String qualifications;
    private String specialization;
    private String doctorType;
    private String workplace;
    private String chamber;
    private String visitingHours;
    private String phoneNumber;
    private String imageUrl;
    private String address;
    private String union; // Added union field

    private String createdAt;
    private String updatedAt;

    public UnifiedSpecialistDoctor() {
        // Empty constructor
    }

    protected UnifiedSpecialistDoctor(Parcel in) {
        id = in.readString();
        name = in.readString();
        qualifications = in.readString();
        specialization = in.readString();
        doctorType = in.readString();
        workplace = in.readString();
        chamber = in.readString();
        visitingHours = in.readString();
        phoneNumber = in.readString();
        imageUrl = in.readString();
        address = in.readString();
        union = in.readString(); // Added union field

        createdAt = in.readString();
        updatedAt = in.readString();
    }

    public static final Creator<UnifiedSpecialistDoctor> CREATOR = new Creator<UnifiedSpecialistDoctor>() {
        @Override
        public UnifiedSpecialistDoctor createFromParcel(Parcel in) {
            return new UnifiedSpecialistDoctor(in);
        }

        @Override
        public UnifiedSpecialistDoctor[] newArray(int size) {
            return new UnifiedSpecialistDoctor[size];
        }
    };

    // Getters and Setters
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

    public String getQualifications() {
        return qualifications;
    }

    public void setQualifications(String qualifications) {
        this.qualifications = qualifications;
    }

    public String getSpecialization() {
        return specialization;
    }

    public void setSpecialization(String specialization) {
        this.specialization = specialization;
    }

    public String getDoctorType() {
        return doctorType;
    }

    public void setDoctorType(String doctorType) {
        this.doctorType = doctorType;
    }

    public String getWorkplace() {
        return workplace;
    }

    public void setWorkplace(String workplace) {
        this.workplace = workplace;
    }

    public String getChamber() {
        return chamber;
    }

    public void setChamber(String chamber) {
        this.chamber = chamber;
    }

    public String getVisitingHours() {
        return visitingHours;
    }

    public void setVisitingHours(String visitingHours) {
        this.visitingHours = visitingHours;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
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

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(id);
        dest.writeString(name);
        dest.writeString(qualifications);
        dest.writeString(specialization);
        dest.writeString(doctorType);
        dest.writeString(workplace);
        dest.writeString(chamber);
        dest.writeString(visitingHours);
        dest.writeString(phoneNumber);
        dest.writeString(imageUrl);
        dest.writeString(address);
        dest.writeString(union); // Added union field
        dest.writeString(createdAt);
        dest.writeString(updatedAt);
    }
}