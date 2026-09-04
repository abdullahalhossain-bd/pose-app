package com.example.betagiesheva.Model;

import java.io.Serializable;

/* loaded from: classes4.dex */
public class Person implements Serializable {
    private String address;
    private String imageUrl;
    private String name;
    private String number;

    public Person(String name, String address, String number, String imageUrl) {
        this.name = name;
        this.address = address;
        this.number = number;
        this.imageUrl = imageUrl;
    }

    public String getName() {
        return this.name;
    }

    public String getAddress() {
        return this.address;
    }

    public String getNumber() {
        return this.number;
    }

    public String getImageUrl() {
        return this.imageUrl;
    }
}
