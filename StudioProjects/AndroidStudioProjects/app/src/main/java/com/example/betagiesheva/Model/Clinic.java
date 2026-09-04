package com.example.betagiesheva.Model;

import android.os.Parcel;
import android.os.Parcelable;

import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;

public class Clinic implements Parcelable {
    private String address;
    private String complaintPhoneNumber;
    private String email;
    private String establishDate;
    private String founderName;
    private String id;
    private String img;
    private String name;
    private String operatingHours;
    private String phoneNumber;
    private String placeName;
    private Map<String, Object> services;
    private String transportInfo;
    private String union; // Added union field

    public Clinic() {
        // Default constructor
    }

    public Clinic(String name, String address, String img, String placeName, String phoneNumber,
                  String transportInfo, String operatingHours, String establishDate, String founderName,
                  Map<String, Object> services, String complaintPhoneNumber, String email, String union) {
        this.name = name;
        this.address = address;
        this.img = img;
        this.placeName = placeName;
        this.phoneNumber = phoneNumber;
        this.transportInfo = transportInfo;
        this.operatingHours = operatingHours;
        this.establishDate = establishDate;
        this.founderName = founderName;
        this.services = services;
        this.complaintPhoneNumber = complaintPhoneNumber;
        this.email = email;
        this.union = union;
    }

    // Parcelable implementation
    protected Clinic(Parcel in) {
        address = in.readString();
        complaintPhoneNumber = in.readString();
        email = in.readString();
        establishDate = in.readString();
        founderName = in.readString();
        id = in.readString();
        img = in.readString();
        name = in.readString();
        operatingHours = in.readString();
        phoneNumber = in.readString();
        placeName = in.readString();
        transportInfo = in.readString();
        union = in.readString(); // Added union field
        // Read services map from parcel (if present)
        try {
            this.services = in.readHashMap(getClass().getClassLoader());
        } catch (Exception e) {
            this.services = null;
        }
    }

    public static final Creator<Clinic> CREATOR = new Creator<Clinic>() {
        @Override
        public Clinic createFromParcel(Parcel in) {
            return new Clinic(in);
        }

        @Override
        public Clinic[] newArray(int size) {
            return new Clinic[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(address);
        dest.writeString(complaintPhoneNumber);
        dest.writeString(email);
        dest.writeString(establishDate);
        dest.writeString(founderName);
        dest.writeString(id);
        dest.writeString(img);
        dest.writeString(name);
        dest.writeString(operatingHours);
        dest.writeString(phoneNumber);
        dest.writeString(placeName);
        dest.writeString(transportInfo);
        dest.writeString(union); // Added union field
        // Write services map to parcel so it can be reconstructed on the other side
        try {
            dest.writeMap(this.services == null ? new HashMap<String, Object>() : this.services);
        } catch (Exception e) {
            dest.writeMap(new HashMap<String, Object>());
        }
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getImg() { return img; }
    public void setImg(String img) { this.img = img; }
    public String getPlaceName() { return placeName; }
    public void setPlaceName(String placeName) { this.placeName = placeName; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public String getTransportInfo() { return transportInfo; }
    public void setTransportInfo(String transportInfo) { this.transportInfo = transportInfo; }
    public String getOperatingHours() { return operatingHours; }
    public void setOperatingHours(String operatingHours) { this.operatingHours = operatingHours; }
    public String getEstablishDate() { return establishDate; }
    public void setEstablishDate(String establishDate) { this.establishDate = establishDate; }
    public String getFounderName() { return founderName; }
    public void setFounderName(String founderName) { this.founderName = founderName; }
    public Map<String, Object> getServices() { return services; }
    public void setServices(Map<String, Object> services) { this.services = services; }
    public String getComplaintPhoneNumber() { return complaintPhoneNumber; }
    public void setComplaintPhoneNumber(String complaintPhoneNumber) { this.complaintPhoneNumber = complaintPhoneNumber; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getUnion() { return union; } // Added getter
    public void setUnion(String union) { this.union = union; } // Added setter

    /**
     * Return the services as a List of strings.
     * The underlying `services` field may be a map where keys or nested values
     * contain the human-readable service names. This method attempts to
     * extract reasonable string values for display.
     */
    public List<String> getServicesList() {
        List<String> list = new ArrayList<>();
        if (this.services == null || this.services.isEmpty()) return list;

        for (Map.Entry<String, Object> entry : this.services.entrySet()) {
            Object val = entry.getValue();
            if (val == null) continue;

            if (val instanceof String) {
                String s = (String) val;
                if (!s.isEmpty()) list.add(s);
            } else if (val instanceof Map) {
                // nested map: try to find a name-like field
                Map<?, ?> m = (Map<?, ?>) val;
                if (m.containsKey("name")) {
                    Object o = m.get("name");
                    if (o != null) list.add(o.toString());
                } else if (m.containsKey("service")) {
                    Object o = m.get("service");
                    if (o != null) list.add(o.toString());
                } else if (m.containsKey("test")) {
                    Object o = m.get("test");
                    if (o != null) list.add(o.toString());
                } else {
                    // fallback to map key
                    if (entry.getKey() != null && !entry.getKey().isEmpty()) {
                        list.add(entry.getKey());
                    }
                }
            } else {
                // fallback to toString()
                list.add(val.toString());
            }
        }

        return list;
    }
}