package com.example.betagiesheva;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
/* loaded from: classes4.dex */
public class PrimaryActivity extends AppCompatActivity {
    private ImageView backButton;

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        EdgeToEdge.enable(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_primary);
        ImageButton backButton = (ImageButton) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.PrimaryActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                PrimaryActivity.this.m867lambda$onCreate$0$comexamplebetagiesevaPrimaryActivity(view);
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-PrimaryActivity  reason: not valid java name */
    public /* synthetic */ void m867lambda$onCreate$0$comexamplebetagiesevaPrimaryActivity(View v) {
        finish();
    }
}
