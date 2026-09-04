package com.example.betagiesheva;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;


import com.example.betagiesheva.Adapter.PersonAdapter;
import com.example.betagiesheva.Model.Person;

import java.util.ArrayList;
/* loaded from: classes4.dex */
public class PersonActivity extends AppCompatActivity {
    public static String TITLE = "";

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_person);
        ImageButton backButton = (ImageButton) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.PersonActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                PersonActivity.this.m840lambda$onCreate$0$comexamplebetagiesevaPersonActivity(view);
            }
        });
        TextView toolbar = (TextView) findViewById(R.id.name);
        ArrayList<Person> personList = (ArrayList) getIntent().getSerializableExtra("personList");
        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.recyclerView);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(new PersonAdapter(this, personList));
        toolbar.setText(TITLE);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-PersonActivity  reason: not valid java name */
    public /* synthetic */ void m840lambda$onCreate$0$comexamplebetagiesevaPersonActivity(View v) {
        finish();
    }
}
