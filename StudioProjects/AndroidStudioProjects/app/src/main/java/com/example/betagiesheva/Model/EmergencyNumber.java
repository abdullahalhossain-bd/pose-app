package com.example.betagiesheva.Model;

/**
 * Emergency number entry (e.g., বেতাগী থানা → 01769-690062).
 *
 * Package was previously `com.myapp.sirajganjcity.Models` (template leftover);
 * fixed to `com.example.betagiesheva.Model` so the file is reachable by
 * EmergencyNumbersActivity and EmergencyAdapter.
 */
public class EmergencyNumber {
    private String name;
    private String number;
    private String type;

    public EmergencyNumber(String name, String number) {
        this.name = name;
        this.number = number;
    }

    public EmergencyNumber(String name, String number, String type) {
        this.name = name;
        this.number = number;
        this.type = type;
    }

    public String getName()   { return this.name; }
    public String getNumber() { return this.number; }
    public String getType()   { return this.type != null ? this.type : ""; }

    public void setName(String name)       { this.name = name; }
    public void setNumber(String number)   { this.number = number; }
    public void setType(String type)       { this.type = type; }
}
