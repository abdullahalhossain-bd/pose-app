package com.example.betagiesheva.Model;

import android.os.Parcel;
import android.os.Parcelable;

import androidx.annotation.NonNull;

public class UnifiedBusinessItem implements Parcelable {

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

    private String id;
    private String user_id;
    private String name;
    private String proprietor_name;
    private String phone;
    private String address;
    private String union_name;
    private String business_type;
    private String details;
    private String image; // JSON কী 'image', তাই এখানেও 'image' রাখা হয়েছে
    private String created_at;
    private String updated_at;

    // পূর্ণাঙ্গ কনস্ট্রাক্টর (এটি ডাটা এসাইন করার জন্য জরুরি)
    public UnifiedBusinessItem(String id, String user_id, String name, String proprietor_name,
                               String phone, String address, String union_name,
                               String business_type, String details, String image,
                               String created_at, String updated_at) {
        this.id = id;
        this.user_id = user_id;
        this.name = name;
        this.proprietor_name = proprietor_name;
        this.phone = phone;
        this.address = address;
        this.union_name = union_name;
        this.business_type = business_type;
        this.details = details;
        this.image = image;
        this.created_at = created_at;
        this.updated_at = updated_at;
    }

    protected UnifiedBusinessItem(Parcel in) {
        id = in.readString();
        user_id = in.readString();
        name = in.readString();
        proprietor_name = in.readString();
        phone = in.readString();
        address = in.readString();
        union_name = in.readString();
        business_type = in.readString();
        details = in.readString();
        image = in.readString();
        created_at = in.readString();
        updated_at = in.readString();
    }

    public static final Creator<UnifiedBusinessItem> CREATOR = new Creator<UnifiedBusinessItem>() {
        @Override
        public UnifiedBusinessItem createFromParcel(Parcel in) {
            return new UnifiedBusinessItem(in);
        }

        @Override
        public UnifiedBusinessItem[] newArray(int size) {
            return new UnifiedBusinessItem[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(id);
        dest.writeString(user_id);
        dest.writeString(name);
        dest.writeString(proprietor_name);
        dest.writeString(phone);
        dest.writeString(address);
        dest.writeString(union_name);
        dest.writeString(business_type);
        dest.writeString(details);
        dest.writeString(image);
        dest.writeString(created_at);
        dest.writeString(updated_at);
    }

    // Getters
    public String getId() { return id != null ? id : ""; }
    public String getName() { return name != null ? name : ""; }
    public String getProprietorName() { return proprietor_name != null ? proprietor_name : ""; }
    public String getPhone() { return phone != null ? phone : ""; }
    public String getAddress() { return address != null ? address : ""; }
    public String getUnionName() { return union_name != null ? union_name : ""; }
    public String getBusinessType() { return business_type != null ? business_type : ""; }
    public String getDetails() { return details != null ? details : ""; }
    public String getImage() { return image != null ? image : ""; }
    public String getCreatedAt() { return created_at != null ? created_at : ""; }
}