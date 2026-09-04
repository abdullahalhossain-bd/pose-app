package com.example.betagiesheva.helper;


import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.example.betagiesheva.controller.MyControl;
import com.example.betagiesheva.controller.MyMethods;

import java.net.URISyntaxException;

public class HelloWebViewClient extends WebViewClient {

    Activity activity;
    static MyHelper myHelper;

    public HelloWebViewClient(MyHelper myHelper) {
        HelloWebViewClient.myHelper = myHelper;
    }

    public HelloWebViewClient(Activity activity) {
        this.activity = activity;
    }

    @Override
    public boolean shouldOverrideUrlLoading(WebView view, String url) {

        if (!MyMethods.isConnected(activity)) {
            myHelper.finishLoading();
        } else {
            myHelper.loading();
        }

        // Handle social media URLs with deep linking
        if (url.contains("facebook.com") || url.startsWith("https://m.facebook.com") || url.contains("fb.com")) {
            openFacebook(url);
            return true;
        }




        if (url.contains("youtube.com")) {
            openYouTube(url);
            return true;
        }

        if (url.contains("twitter.com")) {
            openTwitter(url);
            return true;
        }

        if (url.contains("play.google.com")) {
            openPlayStore(url);
            return true;
        }

        if (url.contains("gmail.com")) {
            openGmail(url);
            return true;
        }

        if (url.contains("t.me") || url.contains("telegram.org")) {
            openTelegram(url);
            return true; // Do not load the URL in WebView
        }

        if (url.contains("whatsapp.com")) {
            openWhatsApp(url);
            return true;
        }

        // Continue loading other URLs in WebView as usual
        if (url.startsWith("http")) return false;

        // Try to handle intent:// URLs
        if (url.startsWith("intent:")) {
            try {
                Intent intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME);
                if (intent.resolveActivity(activity.getPackageManager()) != null) {
                    activity.startActivity(intent);
                    return true;
                }

                // Try fallback URL
                String fallbackUrl = intent.getStringExtra("browser_fallback_url");
                if (fallbackUrl != null) {
                    myHelper.webLoadUrl(fallbackUrl);
                    return true;
                }

                // Invite to install from the Play Store
                Intent marketIntent = new Intent(Intent.ACTION_VIEW).setData(
                        Uri.parse("market://details?id=" + intent.getPackage()));
                if (marketIntent.resolveActivity(activity.getPackageManager()) != null) {
                    activity.startActivity(marketIntent);
                    return true;
                }
            } catch (URISyntaxException e) {
                e.printStackTrace();
            }
        }

        return true;
    }

    // Function to open Facebook app with specific URL
    private void openFacebook(String url) {
        String facebookId = "fb://facewebmodal/f?href=" + url; // Deep link for Facebook app
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(facebookId));
            activity.startActivity(intent);
        } catch (Exception e) {
            // If Facebook app is not installed, open in browser
            Intent webIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            activity.startActivity(webIntent);
        }
    }

    // Function to open YouTube app with specific URL
    private void openYouTube(String url) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            intent.setPackage("com.google.android.youtube"); // Open YouTube in app
            activity.startActivity(intent);
        } catch (Exception e) {
            // If YouTube app is not installed, open in browser
            Intent webIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            activity.startActivity(webIntent);
        }
    }

    // Function to open Twitter app with specific URL
    private void openTwitter(String url) {
        String twitterId = "twitter://user?screen_name=" + Uri.parse(url).getLastPathSegment();
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(twitterId));
            activity.startActivity(intent);
        } catch (Exception e) {
            // If Twitter app is not installed, open in browser
            Intent webIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            activity.startActivity(webIntent);
        }
    }

    // Function to open Play Store app with specific URL
    private void openPlayStore(String url) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            intent.setPackage("com.android.vending"); // Open Play Store app
            activity.startActivity(intent);
        } catch (Exception e) {
            // If Play Store app is not installed, open in browser
            Intent webIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            activity.startActivity(webIntent);
        }
    }

    // Function to open Gmail app with specific URL
    private void openGmail(String url) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            intent.setPackage("com.google.android.gm"); // Open Gmail app
            activity.startActivity(intent);
        } catch (Exception e) {
            // If Gmail app is not installed, open in browser
            Intent webIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            activity.startActivity(webIntent);
        }
    }

    // Function to open Telegram app with specific URL
    private void openTelegram(String url) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            intent.setPackage("org.telegram.messenger"); // Open Telegram app
            activity.startActivity(intent);
        } catch (Exception e) {
            // If Telegram app is not installed, open in browser
            Intent webIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            activity.startActivity(webIntent);
        }
    }

    // Function to open WhatsApp app with specific URL
    private void openWhatsApp(String url) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            intent.setPackage("com.whatsapp"); // Open WhatsApp app
            activity.startActivity(intent);
        } catch (Exception e) {
            // If WhatsApp app is not installed, open in browser
            Intent webIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            activity.startActivity(webIntent);
        }
    }

    @Override
    public void onReceivedError(WebView view, int errorCode, String description, String url) {
        MyControl.LOAD_ERROR_REASON = description;

        if (MyControl.NETWORK_AVAILABLE) {
            MyControl.FAILED_FOR_OTHER_REASON = true;
        }
        myHelper.errorLoading();
    }

    @Override
    public void onPageFinished(WebView view, String url) {
        // Do your stuff here after the page is loaded
    }

    @Override
    public void onPageStarted(WebView view, String url, Bitmap favicon) {
        super.onPageStarted(view, url, favicon);
        MyControl.FAILED_FOR_OTHER_REASON = false;
    }
}
