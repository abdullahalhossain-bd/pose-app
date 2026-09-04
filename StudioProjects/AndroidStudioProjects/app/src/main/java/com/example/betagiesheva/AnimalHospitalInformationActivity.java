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
public class AnimalHospitalInformationActivity extends AppCompatActivity {
    private static final LatLng ANIMAL_HOSPITAL_LOCATION = new LatLng(22.4138d, 90.1598d);
    final String fullText = "বেতাগী প্রাণী হাসপাতাল একটি গুরুত্বপূর্ণ প্রতিষ্ঠান, যা এলাকার পশুসম্পদ সুরক্ষা ও উন্নয়নের জন্য নিবেদিত। এটি প্রতিষ্ঠিত হয়েছিল ১৯৮৫ সালে, যখন স্থানীয় পশুপ্রেমীদের প্রচেষ্টায় এবং সরকারি সহায়তায় হাসপাতালটি গড়ে তোলা হয়। প্রতিষ্ঠার মূল উদ্যোক্তা ছিলেন ডা. আব্দুল করিম, যিনি প্রাণীদের প্রতি তার গভীর ভালোবাসা এবং সেবার মনোভাব থেকে এটি প্রতিষ্ঠা করেন। হাসপাতালটিতে গরু, ছাগল, হাঁস-মুরগি সহ বিভিন্ন প্রাণীর চিকিৎসা প্রদান করা হয়। এখানে রোগ নির্ণয়, টিকা প্রদান এবং অপারেশন সহ আধুনিক চিকিৎসা সেবা পাওয়া যায়। প্রাণী মালিকদের সঠিক পরামর্শ এবং যত্ন সম্পর্কে সচেতন করতে হাসপাতালটি বিশেষ ভূমিকা পালন করে আসছে।";

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_animal_hospital_information);
        LinearLayout liner1 = (LinearLayout) findViewById(R.id.liner1);
        LinearLayout liner3 = (LinearLayout) findViewById(R.id.liner3);
        final TextView animalHospitalInfo = (TextView) findViewById(R.id.animal_hospital_info);
        final TextView moreButton = (TextView) findViewById(R.id.more);
        ImageView backButton = (ImageView) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.AnimalHospitalInformationActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                AnimalHospitalInformationActivity.this.m156xb3bcafb9(view);
            }
        });
        Button callButton = (Button) findViewById(R.id.call);
        liner1.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.AnimalHospitalInformationActivity.1
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                Intent intent = new Intent("android.intent.action.VIEW", Uri.parse("http://dls.betagi.barguna.gov.bd/"));
                AnimalHospitalInformationActivity.this.startActivity(intent);
            }
        });
        liner3.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.AnimalHospitalInformationActivity.2
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                Uri gmmIntentUri = Uri.parse("geo:" + AnimalHospitalInformationActivity.ANIMAL_HOSPITAL_LOCATION.latitude + "," + AnimalHospitalInformationActivity.ANIMAL_HOSPITAL_LOCATION.longitude + "?q=Animal+Hospital");
                Intent mapIntent = new Intent("android.intent.action.VIEW", gmmIntentUri);
                mapIntent.setPackage("com.google.android.apps.maps");
                if (mapIntent.resolveActivity(AnimalHospitalInformationActivity.this.getPackageManager()) != null) {
                    AnimalHospitalInformationActivity.this.startActivity(mapIntent);
                    return;
                }
                String mapsUrl = "https://www.google.com/maps/search/?api=1&query=" + AnimalHospitalInformationActivity.ANIMAL_HOSPITAL_LOCATION.latitude + "," + AnimalHospitalInformationActivity.ANIMAL_HOSPITAL_LOCATION.longitude;
                Intent browserIntent = new Intent("android.intent.action.VIEW", Uri.parse(mapsUrl));
                AnimalHospitalInformationActivity.this.startActivity(browserIntent);
            }
        });
        moreButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.AnimalHospitalInformationActivity.3
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                animalHospitalInfo.setText("বেতাগী প্রাণী হাসপাতাল একটি গুরুত্বপূর্ণ প্রতিষ্ঠান, যা এলাকার পশুসম্পদ সুরক্ষা ও উন্নয়নের জন্য নিবেদিত। এটি প্রতিষ্ঠিত হয়েছিল ১৯৮৫ সালে, যখন স্থানীয় পশুপ্রেমীদের প্রচেষ্টায় এবং সরকারি সহায়তায় হাসপাতালটি গড়ে তোলা হয়। প্রতিষ্ঠার মূল উদ্যোক্তা ছিলেন ডা. আব্দুল করিম, যিনি প্রাণীদের প্রতি তার গভীর ভালোবাসা এবং সেবার মনোভাব থেকে এটি প্রতিষ্ঠা করেন। হাসপাতালটিতে গরু, ছাগল, হাঁস-মুরগি সহ বিভিন্ন প্রাণীর চিকিৎসা প্রদান করা হয়। এখানে রোগ নির্ণয়, টিকা প্রদান এবং অপারেশন সহ আধুনিক চিকিৎসা সেবা পাওয়া যায়। প্রাণী মালিকদের সঠিক পরামর্শ এবং যত্ন সম্পর্কে সচেতন করতে হাসপাতালটি বিশেষ ভূমিকা পালন করে আসছে।");
                moreButton.setVisibility(View.GONE);
            }
        });
        callButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.AnimalHospitalInformationActivity.4
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                Intent callIntent = new Intent("android.intent.action.DIAL");
                callIntent.setData(Uri.parse("tel:01733334149"));
                AnimalHospitalInformationActivity.this.startActivity(callIntent);
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-AnimalHospitalInformationActivity  reason: not valid java name */
    public /* synthetic */ void m156xb3bcafb9(View v) {
        finish();
    }
}
