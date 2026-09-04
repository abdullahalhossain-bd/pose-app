package com.example.betagiesheva;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.util.Log;
import android.view.View;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.util.Locale;

public class UnoActivity extends AppCompatActivity implements TextToSpeech.OnInitListener {
    private boolean isSpeaking = false;
    private ImageView speakerIcon;
    private TextToSpeech textToSpeech;
    private static final String TAG = "UnoActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_uno);

        // Back Button
        ImageButton backButton = findViewById(R.id.back_button);
        backButton.setOnClickListener(v -> finish());

        // Initialize TextToSpeech
        textToSpeech = new TextToSpeech(this, this);

        // Find Views
        LinearLayout liner1 = findViewById(R.id.liner1);
        LinearLayout liner2 = findViewById(R.id.liner2);
        LinearLayout liner3 = findViewById(R.id.liner3);
        LinearLayout liner4 = findViewById(R.id.liner4);
        speakerIcon = findViewById(R.id.speaker_icon);

        // Set Click Listeners
        liner1.setOnClickListener(v ->
                openContactSavePage("মুহম্মদ বশির গাজী", "01733348029")
        );

        liner2.setOnClickListener(v ->
                openEmail("unobetagi@mopa.gov.bd")
        );

        liner3.setOnClickListener(v ->
                sendMessage("01733348029")
        );

        liner4.setOnClickListener(v -> {
            if (!isSpeaking) {
                speakerIcon.setImageResource(R.drawable.speaker_on);
                speak("মুহম্মদ বশির গাজী,উপজেলা নির্বাহী অফিসার,মোবাইল , 01733348029,ই-মেইল. unobetagi@mopa.gov.bd");
                isSpeaking = true;
            } else {
                textToSpeech.stop();
                speakerIcon.setImageResource(R.drawable.speaker);
                isSpeaking = false;
            }
        });
    }

    @Override
    public void onInit(int status) {
        if (status == TextToSpeech.SUCCESS) {
            // Set language to Bengali
            int langResult = textToSpeech.setLanguage(new Locale("bn", "BD"));

            if (langResult == TextToSpeech.LANG_MISSING_DATA ||
                    langResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.e(TAG, "Bengali language not supported, trying default locale");
                textToSpeech.setLanguage(Locale.getDefault());
            }

            // Set UtteranceProgressListener (OnUtteranceCompletedListener is deprecated)
            textToSpeech.setOnUtteranceProgressListener(new UtteranceProgressListener() {
                @Override
                public void onStart(String utteranceId) {
                    // Speech started
                }

                @Override
                public void onDone(String utteranceId) {
                    // Speech completed
                    runOnUiThread(() -> {
                        speakerIcon.setImageResource(R.drawable.speaker);
                        isSpeaking = false;
                    });
                }

                @Override
                public void onError(String utteranceId) {
                    // Speech error
                    runOnUiThread(() -> {
                        speakerIcon.setImageResource(R.drawable.speaker);
                        isSpeaking = false;
                        Toast.makeText(UnoActivity.this,
                                "Speech error occurred", Toast.LENGTH_SHORT).show();
                    });
                }
            });
        } else {
            Log.e(TAG, "TextToSpeech initialization failed");
            Toast.makeText(this, "Text-to-Speech initialization failed",
                    Toast.LENGTH_SHORT).show();
        }
    }

    private void speak(String text) {
        if (textToSpeech != null && !isSpeaking) {
            textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, null, "UniqueID");
        }
    }

    @Override
    protected void onDestroy() {
        if (textToSpeech != null) {
            textToSpeech.stop();
            textToSpeech.shutdown();
        }
        super.onDestroy();
    }

    private void openContactSavePage(String name, String phone) {
        Intent intent = new Intent(Intent.ACTION_INSERT);
        intent.setType("vnd.android.cursor.dir/contact");
        intent.putExtra("name", name);
        intent.putExtra("phone", phone);

        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
        } else {
            Toast.makeText(this, "কন্টাক্ট যোগ করার জন্য কোনো অ্যাপ পাওয়া যায়নি",
                    Toast.LENGTH_SHORT).show();
        }
    }

    private void openEmail(String email) {
        Intent intent = new Intent(Intent.ACTION_SENDTO);
        intent.setData(Uri.parse("mailto:" + email));
        intent.putExtra(Intent.EXTRA_SUBJECT, "বিষয়");
        intent.putExtra(Intent.EXTRA_TEXT, "ইমেইলের বিষয়বস্তু");

        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
        } else {
            Toast.makeText(this, "ইমেইল ক্লায়েন্ট পাওয়া যায়নি",
                    Toast.LENGTH_SHORT).show();
        }
    }

    private void sendMessage(String phoneNumber) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("sms:" + phoneNumber));
        intent.putExtra("sms_body", "হ্যালো");

        if (intent.resolveActivity(getPackageManager()) != null) {
            startActivity(intent);
        } else {
            Toast.makeText(this, "SMS অ্যাপ পাওয়া যায়নি",
                    Toast.LENGTH_SHORT).show();
        }
    }
}