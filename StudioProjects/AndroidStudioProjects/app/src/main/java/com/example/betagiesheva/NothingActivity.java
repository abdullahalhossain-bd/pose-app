package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.gms.maps.model.LatLng;
/* loaded from: classes4.dex */
public class NothingActivity extends AppCompatActivity {
    private static final LatLng BETAGI_HEALTH_COMPLEX_LOCATION = new LatLng(22.4137598d, 90.1598276d);
    final String fullText = "বেতাগী উপজেলা স্বাস্থ্য কমপ্লেক্স বেতাগী উপজেলার অন্যতম গুরুত্বপূর্ণ একটি স্বাস্থ্যসেবা কেন্দ্র। এটি উপজেলা পর্যায়ে বিভিন্ন ধরনের প্রাথমিক ও জরুরি চিকিৎসা সেবা প্রদান করে থাকে। আধুনিক চিকিৎসা সরঞ্জাম এবং অভিজ্ঞ চিকিৎসক ও নার্সদের সমন্বয়ে পরিচালিত এই স্বাস্থ্য কমপ্লেক্সটি রোগীদের জন্য সর্বোত্তম সেবা নিশ্চিত করতে প্রতিশ্রুতিবদ্ধ। এখানে বহির্বিভাগ, অন্তর্বিভাগ, শিশু ও মাতৃসেবা, টিকাদান কর্মসূচি এবং অন্যান্য স্বাস্থ্যসেবা কার্যক্রম পরিচালিত হয়। এছাড়াও, স্থানীয় জনগণের জন্য স্বাস্থ্য সচেতনতা বৃদ্ধি এবং জরুরি চিকিৎসা ক্ষেত্রে তাৎক্ষণিক সেবা প্রদানের জন্য এটি অত্যন্ত গুরুত্বপূর্ণ ভূমিকা পালন করে।";

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_nothing);
        LinearLayout liner1 = (LinearLayout) findViewById(R.id.liner1);
        LinearLayout liner3 = (LinearLayout) findViewById(R.id.liner3);
        final TextView animalHospitalInfo = (TextView) findViewById(R.id.hospital_info);
        final TextView moreButton = (TextView) findViewById(R.id.more);
        ImageView backButton = (ImageView) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.NothingActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                NothingActivity.this.m749lambda$onCreate$0$comexamplebetagiesevaNothingActivity(view);
            }
        });
        Button callButton = (Button) findViewById(R.id.call);
        liner1.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.NothingActivity.1
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                Intent intent = new Intent("android.intent.action.VIEW", Uri.parse("http://health.betagi.barguna.gov.bd/"));
                NothingActivity.this.startActivity(intent);
            }
        });
        liner3.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.NothingActivity.2
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                Uri gmmIntentUri = Uri.parse("geo:" + NothingActivity.BETAGI_HEALTH_COMPLEX_LOCATION.latitude + "," + NothingActivity.BETAGI_HEALTH_COMPLEX_LOCATION.longitude + "?q=Health+Complex");
                Intent mapIntent = new Intent("android.intent.action.VIEW", gmmIntentUri);
                mapIntent.setPackage("com.google.android.apps.maps");
                if (mapIntent.resolveActivity(NothingActivity.this.getPackageManager()) != null) {
                    NothingActivity.this.startActivity(mapIntent);
                    return;
                }
                String mapsUrl = "https://www.google.com/maps/search/?api=1&query=" + NothingActivity.BETAGI_HEALTH_COMPLEX_LOCATION.latitude + "," + NothingActivity.BETAGI_HEALTH_COMPLEX_LOCATION.longitude;
                Intent browserIntent = new Intent("android.intent.action.VIEW", Uri.parse(mapsUrl));
                NothingActivity.this.startActivity(browserIntent);
            }
        });
        moreButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.NothingActivity.3
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                animalHospitalInfo.setText("বেতাগী উপজেলা স্বাস্থ্য কমপ্লেক্স বেতাগী উপজেলার অন্যতম গুরুত্বপূর্ণ একটি স্বাস্থ্যসেবা কেন্দ্র। এটি উপজেলা পর্যায়ে বিভিন্ন ধরনের প্রাথমিক ও জরুরি চিকিৎসা সেবা প্রদান করে থাকে। আধুনিক চিকিৎসা সরঞ্জাম এবং অভিজ্ঞ চিকিৎসক ও নার্সদের সমন্বয়ে পরিচালিত এই স্বাস্থ্য কমপ্লেক্সটি রোগীদের জন্য সর্বোত্তম সেবা নিশ্চিত করতে প্রতিশ্রুতিবদ্ধ। এখানে বহির্বিভাগ, অন্তর্বিভাগ, শিশু ও মাতৃসেবা, টিকাদান কর্মসূচি এবং অন্যান্য স্বাস্থ্যসেবা কার্যক্রম পরিচালিত হয়। এছাড়াও, স্থানীয় জনগণের জন্য স্বাস্থ্য সচেতনতা বৃদ্ধি এবং জরুরি চিকিৎসা ক্ষেত্রে তাৎক্ষণিক সেবা প্রদানের জন্য এটি অত্যন্ত গুরুত্বপূর্ণ ভূমিকা পালন করে।");
                moreButton.setVisibility(8);
            }
        });
        callButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.NothingActivity.4
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                Intent callIntent = new Intent("android.intent.action.DIAL");
                callIntent.setData(Uri.parse("tel:01730-324406"));
                NothingActivity.this.startActivity(callIntent);
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-NothingActivity  reason: not valid java name */
    public /* synthetic */ void m749lambda$onCreate$0$comexamplebetagiesevaNothingActivity(View v) {
        finish();
    }
}
