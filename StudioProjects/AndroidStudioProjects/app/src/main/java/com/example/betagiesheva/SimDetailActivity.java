package com.example.betagiesheva;

import android.os.Bundle;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

public class SimDetailActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sim_detail);

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setDisplayShowHomeEnabled(true);
        }

        String simType = getIntent().getStringExtra("simType");
        String displayName = getIntent().getStringExtra("displayName");

        if (getSupportActionBar() != null) {
            getSupportActionBar().setTitle(displayName);
        }

        TextView contentTextView = findViewById(R.id.sim_content);

        // Set content based on SIM type
        switch (simType) {
            case "gp":
                contentTextView.setText(getGpContent());
                break;
            case "banglalink":
                contentTextView.setText(getBanglalinkContent());
                break;
            case "teletalk":
                contentTextView.setText(getTeletalkContent());
                break;
            case "robi":
                contentTextView.setText(getRobiContent());
                break;
            case "airtel":
                contentTextView.setText(getAirtelContent());
                break;
            case "helpcenter":
                contentTextView.setText(getHelpCenterContent());
                break;
            default:
                contentTextView.setText("তথ্য পাওয়া যায়নি");
        }
    }

    private String getGpContent() {
        return "গ্রামীনফোন সিমের তথ্য:\n\n" +
                "• ব্যালেন্স জানতে: *566#\n" +
                "• ইন্টারনেট ব্যালেন্স: *121*1*4#\n" +
                "• মিনিট চেক: *566*10#\n" +
                "• অফার জানতে: *121*1*2#\n" +
                "• কাস্টমার কেয়ার: 121";
    }

    private String getBanglalinkContent() {
        return "বাংলালিংক সিমের তথ্য:\n\n" +
                "• ব্যালেন্স জানতে: *124#\n" +
                "• ইন্টারনেট ব্যালেন্স: *5000*515#\n" +
                "• মিনিট চেক: *124*2#\n" +
                "• অফার জানতে: *121*1*2#\n" +
                "• কাস্টমার কেয়ার: 121";
    }

    private String getTeletalkContent() {
        return "টেলিটক সিমের তথ্য:\n\n" +
                "• ব্যালেন্স জানতে: *152#\n" +
                "• ইন্টারনেট ব্যালেন্স: *152#\n" +
                "• মিনিট চেক: *152# অপশন ১\n" +
                "• অফার জানতে: *111#\n" +
                "• কাস্টমার কেয়ার: 121";
    }

    private String getRobiContent() {
        return "রবি সিমের তথ্য:\n\n" +
                "• ব্যালেন্স জানতে: *222#\n" +
                "• ইন্টারনেট ব্যালেন্স: *8444*88#\n" +
                "• মিনিট চেক: *222*2#\n" +
                "• অফার জানতে: *123*0*1#\n" +
                "• কাস্টমার কেয়ার: 121";
    }

    private String getAirtelContent() {
        return "এয়ারটেল সিমের তথ্য:\n\n" +
                "• ব্যালেন্স জানতে: *778#\n" +
                "• ইন্টারনেট ব্যালেন্স: *778*56#\n" +
                "• মিনিট চেক: *778*5#\n" +
                "• অফার জানতে: *121*1*3#\n" +
                "• কাস্টমার কেয়ার: 121";
    }

    private String getHelpCenterContent() {
        return "হেল্প সেন্টার:\n\n" +
                "• গ্রামীনফোন: 121\n" +
                "• বাংলালিংক: 121\n" +
                "• টেলিটক: 121\n" +
                "• রবি: 121\n" +
                "• এয়ারটেল: 121\n\n" +
                "• জরুরী সেবা: 999\n" +
                "• জাতীয় জরুরী সেবা: 333";
    }
}