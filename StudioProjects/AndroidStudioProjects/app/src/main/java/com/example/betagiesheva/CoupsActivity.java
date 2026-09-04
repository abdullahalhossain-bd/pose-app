package com.example.betagiesheva;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

/* loaded from: classes4.dex */
public class CoupsActivity extends AppCompatActivity {
    private ImageView arrowIcon1;
    private ImageView arrowIcon2;
    private ImageView arrowIcon3;
    private ImageView arrowIcon4;
    private CardView cardView1;
    private CardView cardView2;
    private CardView cardView3;
    private CardView cardView4;
    private LinearLayout detailsSection1;
    private LinearLayout detailsSection2;
    private LinearLayout detailsSection3;
    private LinearLayout detailsSection4;

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_coups);
        ImageView backButton = (ImageView) findViewById(R.id.back);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.CoupsActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                CoupsActivity.this.m322lambda$onCreate$0$comexamplebetagiesevaCoupsActivity(view);
            }
        });
        this.arrowIcon1 = (ImageView) findViewById(R.id.arrow_icon1);
        this.arrowIcon2 = (ImageView) findViewById(R.id.arrow_icon2);
        this.arrowIcon3 = (ImageView) findViewById(R.id.arrow_icon3);
        this.detailsSection1 = (LinearLayout) findViewById(R.id.details_section1);
        this.detailsSection2 = (LinearLayout) findViewById(R.id.details_section2);
        this.detailsSection3 = (LinearLayout) findViewById(R.id.details_section3);
        this.cardView1 = (CardView) findViewById(R.id.card1);
        this.cardView2 = (CardView) findViewById(R.id.card2);
        this.cardView3 = (CardView) findViewById(R.id.card3);
        this.detailsSection1.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.CoupsActivity$$ExternalSyntheticLambda1
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                CoupsActivity.this.m323lambda$onCreate$1$comexamplebetagiesevaCoupsActivity(view);
            }
        });
        this.detailsSection2.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.CoupsActivity$$ExternalSyntheticLambda2
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                CoupsActivity.this.m324lambda$onCreate$2$comexamplebetagiesevaCoupsActivity(view);
            }
        });
        this.detailsSection3.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.CoupsActivity$$ExternalSyntheticLambda3
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                CoupsActivity.this.m325lambda$onCreate$3$comexamplebetagiesevaCoupsActivity(view);
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-CoupsActivity  reason: not valid java name */
    public /* synthetic */ void m322lambda$onCreate$0$comexamplebetagiesevaCoupsActivity(View v) {
        finish();
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$1$com-example-betagieseva-CoupsActivity  reason: not valid java name */
    public /* synthetic */ void m323lambda$onCreate$1$comexamplebetagiesevaCoupsActivity(View v) {
        toggleVisibility(this.cardView1, this.arrowIcon1);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$2$com-example-betagieseva-CoupsActivity  reason: not valid java name */
    public /* synthetic */ void m324lambda$onCreate$2$comexamplebetagiesevaCoupsActivity(View v) {
        toggleVisibility(this.cardView2, this.arrowIcon2);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$3$com-example-betagieseva-CoupsActivity  reason: not valid java name */
    public /* synthetic */ void m325lambda$onCreate$3$comexamplebetagiesevaCoupsActivity(View v) {
        toggleVisibility(this.cardView3, this.arrowIcon3);
    }

    private void toggleVisibility(CardView cardView, ImageView arrowIcon) {
        if (cardView.getVisibility() == 8) {
            cardView.setVisibility(0);
            arrowIcon.setImageResource(R.drawable.baseline_arrow_upward_24);
            return;
        }
        cardView.setVisibility(8);
        arrowIcon.setImageResource(R.drawable.baseline_arrow_downward_24);
    }
}
