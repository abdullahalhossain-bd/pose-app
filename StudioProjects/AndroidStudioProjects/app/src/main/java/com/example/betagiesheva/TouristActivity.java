package com.example.betagiesheva;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

/* loaded from: classes4.dex */
public class TouristActivity extends AppCompatActivity {
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
        setContentView(R.layout.activity_tourist);
        ImageView backButton = (ImageView) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.TouristActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                TouristActivity.this.m963lambda$onCreate$0$comexamplebetagiesevaTouristActivity(view);
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
        this.detailsSection1.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.TouristActivity$$ExternalSyntheticLambda1
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                TouristActivity.this.m964lambda$onCreate$1$comexamplebetagiesevaTouristActivity(view);
            }
        });
        this.detailsSection2.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.TouristActivity$$ExternalSyntheticLambda2
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                TouristActivity.this.m965lambda$onCreate$2$comexamplebetagiesevaTouristActivity(view);
            }
        });
        this.detailsSection3.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.TouristActivity$$ExternalSyntheticLambda3
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                TouristActivity.this.m966lambda$onCreate$3$comexamplebetagiesevaTouristActivity(view);
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-TouristActivity  reason: not valid java name */
    public /* synthetic */ void m963lambda$onCreate$0$comexamplebetagiesevaTouristActivity(View v) {
        finish();
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$1$com-example-betagieseva-TouristActivity  reason: not valid java name */
    public /* synthetic */ void m964lambda$onCreate$1$comexamplebetagiesevaTouristActivity(View v) {
        toggleVisibility(this.cardView1, this.arrowIcon1);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$2$com-example-betagieseva-TouristActivity  reason: not valid java name */
    public /* synthetic */ void m965lambda$onCreate$2$comexamplebetagiesevaTouristActivity(View v) {
        toggleVisibility(this.cardView2, this.arrowIcon2);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$3$com-example-betagieseva-TouristActivity  reason: not valid java name */
    public /* synthetic */ void m966lambda$onCreate$3$comexamplebetagiesevaTouristActivity(View v) {
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
