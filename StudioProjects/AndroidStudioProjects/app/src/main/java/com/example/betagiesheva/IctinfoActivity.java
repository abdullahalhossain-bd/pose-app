package com.example.betagiesheva;


import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.net.MailTo;
import java.util.Locale;
/* loaded from: classes4.dex */
public class IctinfoActivity extends AppCompatActivity implements TextToSpeech.OnInitListener, TextToSpeech.OnUtteranceCompletedListener {
    private boolean isSpeaking = false;
    private ImageView speakerIcon;
    private TextToSpeech textToSpeech;

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_ictinfo);
        ImageButton backButton = (ImageButton) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.IctinfoActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                IctinfoActivity.this.m648lambda$onCreate$0$comexamplebetagiesevaIctinfoActivity(view);
            }
        });
        this.textToSpeech = new TextToSpeech(this, this);
        LinearLayout liner1 = (LinearLayout) findViewById(R.id.liner1);
        LinearLayout liner2 = (LinearLayout) findViewById(R.id.liner2);
        LinearLayout liner3 = (LinearLayout) findViewById(R.id.liner3);
        LinearLayout liner4 = (LinearLayout) findViewById(R.id.liner4);
        this.speakerIcon = (ImageView) findViewById(R.id.speaker_icon);
        liner1.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.IctinfoActivity.1
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                IctinfoActivity.this.openContactSavePage("ইঞ্জিঃ মোঃ মিলন গাজী", "01741635687");
            }
        });
        liner2.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.IctinfoActivity.2
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                IctinfoActivity.this.openEmail("gmmilon15@gmail.com");
            }
        });
        liner3.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.IctinfoActivity.3
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                IctinfoActivity.this.sendMessage("01741635687");
            }
        });
        liner4.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.IctinfoActivity.4
            @Override // android.view.View.OnClickListener
            public void onClick(View v) {
                if (!IctinfoActivity.this.isSpeaking) {
                    IctinfoActivity.this.speakerIcon.setImageResource(R.drawable.speaker_on);
                    IctinfoActivity.this.speak("ইঞ্জিনিয়ার মোঃ মিলন গাজী,উপজেলা আইসিটি অফিসার,মোবাইল , 01741635687,ই-মেইল. gmmilon15@gmail.com");
                    IctinfoActivity.this.isSpeaking = true;
                    return;
                }
                IctinfoActivity.this.textToSpeech.stop();
                IctinfoActivity.this.speakerIcon.setImageResource(R.drawable.speaker);
                IctinfoActivity.this.isSpeaking = false;
            }
        });
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-IctinfoActivity  reason: not valid java name */
    public /* synthetic */ void m648lambda$onCreate$0$comexamplebetagiesevaIctinfoActivity(View v) {
        finish();
    }

    @Override // android.speech.tts.TextToSpeech.OnInitListener
    public void onInit(int status) {
        if (status != 0) {
            Log.e("TextToSpeech", "Initialization failed");
            return;
        }
        int langResult = this.textToSpeech.setLanguage(Locale.getDefault());
        if (langResult == -1 || langResult == -2) {
            Log.e("TextToSpeech", "Language not supported or missing data");
        }
    }

    /* JADX INFO: Access modifiers changed from: private */
    public void speak(String text) {
        if (this.textToSpeech != null && !this.isSpeaking) {
            this.textToSpeech.speak(text, 0, null, null);
        }
    }

    @Override // androidx.appcompat.app.AppCompatActivity, androidx.fragment.app.FragmentActivity, android.app.Activity
    public void onDestroy() {
        if (this.textToSpeech != null) {
            this.textToSpeech.stop();
            this.textToSpeech.shutdown();
        }
        super.onDestroy();
    }

    @Override // android.speech.tts.TextToSpeech.OnUtteranceCompletedListener
    public void onUtteranceCompleted(String uttId) {
        this.speakerIcon.setImageResource(R.drawable.speaker);
        this.isSpeaking = false;
    }

    /* JADX INFO: Access modifiers changed from: private */
    public void openContactSavePage(String name, String phone) {
        Intent intent = new Intent("android.intent.action.INSERT");
        intent.setType("vnd.android.cursor.dir/contact");
        intent.putExtra("name", name);
        intent.putExtra("phone", phone);
        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
        } else {
            Toast.makeText(this, "No app found to add contact", 0).show();
        }
    }

    /* JADX INFO: Access modifiers changed from: private */
    public void openEmail(String email) {
        Intent intent = new Intent("android.intent.action.SENDTO");
        intent.setData(Uri.parse(MailTo.MAILTO_SCHEME + email));
        intent.putExtra("android.intent.extra.SUBJECT", "Subject");
        intent.putExtra("android.intent.extra.TEXT", "Body of the email");
        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
        } else {
            Toast.makeText(this, "No email client found", 0).show();
        }
    }

    /* JADX INFO: Access modifiers changed from: private */
    public void sendMessage(String phoneNumber) {
        Intent intent = new Intent("android.intent.action.VIEW", Uri.parse("sms:" + phoneNumber));
        intent.putExtra("sms_body", "Hello");
        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
        } else {
            Toast.makeText(this, "No SMS app found", 0).show();
        }
    }
}
