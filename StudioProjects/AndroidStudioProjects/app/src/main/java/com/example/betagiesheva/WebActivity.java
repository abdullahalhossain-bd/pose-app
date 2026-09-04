package com.example.betagiesheva;

import android.os.Bundle;
import android.view.MenuItem;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
/* loaded from: classes4.dex */
public class WebActivity extends AppCompatActivity {
    private ProgressBar progressBar;
    private WebView webView;
    public static String URL = "";
    public static String TITLE = "";

    /* JADX INFO: Access modifiers changed from: protected */
    @Override // androidx.fragment.app.FragmentActivity, androidx.activity.ComponentActivity, androidx.core.app.ComponentActivity, android.app.Activity
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_web);
        ImageView backButton = (ImageView) findViewById(R.id.back_button);
        backButton.setOnClickListener(new View.OnClickListener() { // from class: com.example.betagieseva.WebActivity$$ExternalSyntheticLambda0
            @Override // android.view.View.OnClickListener
            public final void onClick(View view) {
                WebActivity.this.m1027lambda$onCreate$0$comexamplebetagiesevaWebActivity(view);
            }
        });
        TextView toolbar = (TextView) findViewById(R.id.name);
        this.progressBar = (ProgressBar) findViewById(R.id.progressBar);
        this.webView = (WebView) findViewById(R.id.webView);
        WebSettings webSettings = this.webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        this.webView.setWebChromeClient(new WebChromeClient() { // from class: com.example.betagieseva.WebActivity.1
            @Override // android.webkit.WebChromeClient
            public void onProgressChanged(WebView view, int newProgress) {
                super.onProgressChanged(view, newProgress);
                WebActivity.this.progressBar.setProgress(newProgress);
                if (newProgress == 100) {
                    WebActivity.this.progressBar.setVisibility(8);
                } else {
                    WebActivity.this.progressBar.setVisibility(0);
                }
            }
        });
        this.webView.setWebViewClient(new WebViewClient());
        this.webView.loadUrl(URL);
        toolbar.setText(TITLE);
    }

    /* JADX INFO: Access modifiers changed from: package-private */
    /* renamed from: lambda$onCreate$0$com-example-betagieseva-WebActivity  reason: not valid java name */
    public /* synthetic */ void m1027lambda$onCreate$0$comexamplebetagiesevaWebActivity(View v) {
        finish();
    }

    @Override // android.app.Activity
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == 16908332) {
            onBackPressed();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override // androidx.activity.ComponentActivity, android.app.Activity
    public void onBackPressed() {
        if (this.webView.canGoBack()) {
            this.webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
