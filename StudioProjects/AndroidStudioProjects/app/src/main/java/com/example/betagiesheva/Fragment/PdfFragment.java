package com.example.betagiesheva.Fragment;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.fragment.app.Fragment;

import com.airbnb.lottie.LottieAnimationView;
import com.example.betagiesheva.R;


public class PdfFragment extends Fragment {
    private LottieAnimationView myLottie;
    private WebView webView;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_pdf, container, false);

        webView = view.findViewById(R.id.webView);
        myLottie = view.findViewById(R.id.myLottie);

        // Configure WebView settings
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.setWebChromeClient(new WebChromeClient());

        // Set initial visibility states
        myLottie.setVisibility(View.VISIBLE);
        webView.setVisibility(View.INVISIBLE);

        // Set WebView client to handle page loading events
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                myLottie.setVisibility(View.GONE);
                webView.setVisibility(View.VISIBLE);
                super.onPageFinished(view, url);
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                myLottie.setVisibility(View.VISIBLE);
                webView.setVisibility(View.INVISIBLE);
                super.onPageStarted(view, url, favicon);
            }
        });

        // Load the PDF URL
        webView.loadUrl("https://drive.google.com/file/d/13I3NtihiBaxM46Fs1YmRpYVtG21A5LLR/preview");

        return view;
    }
}