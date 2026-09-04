package com.example.betagiesheva.Model;

import android.os.Parcel;
import android.os.Parcelable;

public class Donor implements Parcelable {
    private String id;
    private String name;
    private String address;
    private String bloodGroup;
    private String phone;
    private String image;

    public Donor() {
    }

    public Donor(String id, String name, String address, String bloodGroup, String phone, String image) {
        this.id = id;
        this.name = name;
        this.address = address;
        this.bloodGroup = bloodGroup;
        this.phone = phone;
        this.image = image;
    }

    protected Donor(Parcel in) {
        id = in.readString();
        name = in.readString();
        address = in.readString();
        bloodGroup = in.readString();
        phone = in.readString();
        image = in.readString();
    }

    public static final Creator<Donor> CREATOR = new Creator<Donor>() {
        @Override
        public Donor createFromParcel(Parcel in) {
            return new Donor(in);
        }

        @Override
        public Donor[] newArray(int size) {
            return new Donor[size];
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
        dest.writeString(address);
        dest.writeString(bloodGroup);
        dest.writeString(phone);
        dest.writeString(image);
    }

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

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getBloodGroup() {
        return bloodGroup;
    }

    public void setBloodGroup(String bloodGroup) {
        this.bloodGroup = bloodGroup;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }
}