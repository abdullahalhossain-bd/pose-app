package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import com.airbnb.lottie.LottieAnimationView;
import com.google.android.material.card.MaterialCardView;

/* loaded from: classes4.dex */
public class BusActivity extends AppCompatActivity {
    private ImageView arrowIcon1;
    private ImageView arrowIcon2;
    private ImageView arrowIcon3;
    private ImageView arrowIcon4;
    private ImageView arrowIcon5;
    private ImageView arrowIcon6;
    private ImageView arrowIcon7;
    private ImageView arrowIcon8;
    private ImageView arrowIcon9;
    private MaterialCardView cardView1;
    private MaterialCardView cardView2;
    private MaterialCardView cardView3;
    private MaterialCardView cardView4;
    private MaterialCardView cardView5;
    private MaterialCardView cardView6;
    private MaterialCardView cardView7;
    private MaterialCardView cardView8;
    private MaterialCardView cardView9;
    private LinearLayout detailsSection1;
    private LinearLayout detailsSection2;
    private LinearLayout detailsSection3;
    private LinearLayout detailsSection4;
    private LinearLayout detailsSection5;
    private LinearLayout detailsSection6;
    private LinearLayout detailsSection7;
    private LinearLayout detailsSection8;
    private LinearLayout detailsSection9;
    private LottieAnimationView lottieCall1;
    private LottieAnimationView lottieCall2;
    private LottieAnimationView lottieCall3;
    private LottieAnimationView lottieCall4;
    private LottieAnimationView lottieCall5;
    private LottieAnimationView lottieCall6;
    private LottieAnimationView lottieCall7;
    private LottieAnimationView lottieCall8;
    private LottieAnimationView lottieCall9;

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bus);
        ImageButton backButton = (ImageButton) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m218lambda$onCreate$0$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.arrowIcon1 = (ImageView) findViewById(R.id.arrow_icon1);
        this.arrowIcon2 = (ImageView) findViewById(R.id.arrow_icon2);
        this.arrowIcon3 = (ImageView) findViewById(R.id.arrow_icon3);
        this.arrowIcon4 = (ImageView) findViewById(R.id.arrow_icon4);
        this.arrowIcon5 = (ImageView) findViewById(R.id.arrow_icon5);
        this.arrowIcon6 = (ImageView) findViewById(R.id.arrow_icon6);
        this.arrowIcon7 = (ImageView) findViewById(R.id.arrow_icon7);
        this.arrowIcon8 = (ImageView) findViewById(R.id.arrow_icon8);
        this.arrowIcon9 = (ImageView) findViewById(R.id.arrow_icon9);
        this.detailsSection1 = (LinearLayout) findViewById(R.id.details_section1);
        this.detailsSection2 = (LinearLayout) findViewById(R.id.details_section2);
        this.detailsSection3 = (LinearLayout) findViewById(R.id.details_section3);
        this.detailsSection4 = (LinearLayout) findViewById(R.id.details_section4);
        this.detailsSection5 = (LinearLayout) findViewById(R.id.details_section5);
        this.detailsSection6 = (LinearLayout) findViewById(R.id.details_section6);
        this.detailsSection7 = (LinearLayout) findViewById(R.id.details_section7);
        this.detailsSection8 = (LinearLayout) findViewById(R.id.details_section8);
        this.detailsSection9 = (LinearLayout) findViewById(R.id.details_section9);
        this.cardView1 = (MaterialCardView) findViewById(R.id.card1);
        this.cardView2 = (MaterialCardView) findViewById(R.id.card2);
        this.cardView3 = (MaterialCardView) findViewById(R.id.card3);
        this.cardView4 = (MaterialCardView) findViewById(R.id.card4);
        this.cardView5 = (MaterialCardView) findViewById(R.id.card5);
        this.cardView6 = (MaterialCardView) findViewById(R.id.card6);
        this.cardView7 = (MaterialCardView) findViewById(R.id.card7);
        this.cardView8 = (MaterialCardView) findViewById(R.id.card8);
        this.cardView9 = (MaterialCardView) findViewById(R.id.card9);
        this.lottieCall1 = (LottieAnimationView) findViewById(R.id.lottie_call1);
        this.lottieCall2 = (LottieAnimationView) findViewById(R.id.lottie_call2);
        this.lottieCall3 = (LottieAnimationView) findViewById(R.id.lottie_call3);
        this.lottieCall4 = (LottieAnimationView) findViewById(R.id.lottie_call4);
        this.lottieCall5 = (LottieAnimationView) findViewById(R.id.lottie_call5);
        this.lottieCall6 = (LottieAnimationView) findViewById(R.id.lottie_call6);
        this.lottieCall7 = (LottieAnimationView) findViewById(R.id.lottie_call7);
        this.lottieCall8 = (LottieAnimationView) findViewById(R.id.lottie_call8);
        this.lottieCall9 = (LottieAnimationView) findViewById(R.id.lottie_call9);
        this.detailsSection1.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda1
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m219lambda$onCreate$1$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.detailsSection2.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda2
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m229lambda$onCreate$2$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.detailsSection3.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda3
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m230lambda$onCreate$3$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.detailsSection4.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda4
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m231lambda$onCreate$4$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.detailsSection5.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda5
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m232lambda$onCreate$5$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.detailsSection6.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda6
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m233lambda$onCreate$6$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.detailsSection7.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda7
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m234lambda$onCreate$7$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.detailsSection8.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda8
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m235lambda$onCreate$8$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.detailsSection9.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda9
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m236lambda$onCreate$9$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall1.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda10
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m220lambda$onCreate$10$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall2.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda11
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m221lambda$onCreate$11$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall3.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda12
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m222lambda$onCreate$12$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall4.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda13
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m223lambda$onCreate$13$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall5.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda14
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m224lambda$onCreate$14$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall6.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda15
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m225lambda$onCreate$15$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall7.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda16
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m226lambda$onCreate$16$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall8.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda17
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m227lambda$onCreate$17$comexamplebetagiesevaBusActivity(view);
            }
        });
        this.lottieCall9.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.BusActivity$$ExternalSyntheticLambda18
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                BusActivity.this.m228lambda$onCreate$18$comexamplebetagiesevaBusActivity(view);
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m218lambda$onCreate$0$comexamplebetagiesevaBusActivity(View v) {
        finish();
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$1$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m219lambda$onCreate$1$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView1, this.arrowIcon1);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$2$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m229lambda$onCreate$2$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView2, this.arrowIcon2);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$3$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m230lambda$onCreate$3$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView3, this.arrowIcon3);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$4$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m231lambda$onCreate$4$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView4, this.arrowIcon4);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$5$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m232lambda$onCreate$5$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView5, this.arrowIcon5);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$6$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m233lambda$onCreate$6$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView6, this.arrowIcon6);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$7$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m234lambda$onCreate$7$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView7, this.arrowIcon7);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$8$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m235lambda$onCreate$8$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView8, this.arrowIcon8);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$9$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m236lambda$onCreate$9$comexamplebetagiesevaBusActivity(View v) {
        toggleVisibility(this.cardView9, this.arrowIcon9);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$10$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m220lambda$onCreate$10$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01309388238");
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$11$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m221lambda$onCreate$11$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01792-219546");
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$12$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m222lambda$onCreate$12$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01712441248");
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$13$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m223lambda$onCreate$13$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01782706020");
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$14$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m224lambda$onCreate$14$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01777534643");
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$15$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m225lambda$onCreate$15$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01758440294");
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$16$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m226lambda$onCreate$16$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01731962167");
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$17$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m227lambda$onCreate$17$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01721481808");
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$18$com-example-betagieseva-BusActivity  reason: not valid java name */
    public /* synthetic */ void m228lambda$onCreate$18$comexamplebetagiesevaBusActivity(View v) {
        makeCall("01734858922");
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

    private void makeCall(String phoneNumber) {
        Intent intent = new Intent("android.intent.action.DIAL");
        intent.setData(Uri.parse("tel:" + phoneNumber));
        startActivity(intent);
    }
}
