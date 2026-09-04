package com.example.betagiesheva;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

/* loaded from: classes4.dex */
public class HospitalActivity extends AppCompatActivity {
    private ImageButton callButton1;
    private ImageButton callButton2;
    private TextView callText1;
    private TextView callText2;
    private CardView card1;
    private CardView card2;
    private final String hospitalPhoneNumber1 = "01730-324406";
    private final String hospitalPhoneNumber2 = "01303210917";

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hospital);
        ImageView backButton = (ImageView) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.HospitalActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                HospitalActivity.this.m605lambda$onCreate$0$comexamplebetagiesevaHospitalActivity(view);
            }
        });
        this.card1 = (CardView) findViewById(R.id.card1);
        this.card2 = (CardView) findViewById(R.id.card2);
        this.card1.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.HospitalActivity$$ExternalSyntheticLambda1
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                HospitalActivity.this.m606lambda$onCreate$1$comexamplebetagiesevaHospitalActivity(view);
            }
        });
        this.card2.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.HospitalActivity$$ExternalSyntheticLambda2
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                HospitalActivity.this.m607lambda$onCreate$2$comexamplebetagiesevaHospitalActivity(view);
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-HospitalActivity  reason: not valid java name */
    public /* synthetic */ void m605lambda$onCreate$0$comexamplebetagiesevaHospitalActivity(View v) {
        finish();
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$1$com-example-betagieseva-HospitalActivity  reason: not valid java name */
    public /* synthetic */ void m606lambda$onCreate$1$comexamplebetagiesevaHospitalActivity(View v) {
        Intent intent = new Intent(this, NothingActivity.class);
        startActivity(intent);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$2$com-example-betagieseva-HospitalActivity  reason: not valid java name */
    public /* synthetic */ void m607lambda$onCreate$2$comexamplebetagiesevaHospitalActivity(View v) {
        Intent intent = new Intent(this, AnimalHospitalInformationActivity.class);
        startActivity(intent);
    }
}
