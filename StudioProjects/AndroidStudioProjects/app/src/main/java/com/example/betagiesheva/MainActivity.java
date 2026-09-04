package com.example.betagiesheva;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.Intent;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.provider.MediaStore;
import android.view.View;
import android.webkit.CookieManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.airbnb.lottie.LottieAnimationView;
import com.example.betagiesheva.controller.MyControl;
import com.example.betagiesheva.controller.MyMethods;
import com.example.betagiesheva.helper.ChromeClient;
import com.example.betagiesheva.helper.HelloWebViewClient;
import com.example.betagiesheva.helper.MyHelper;
import com.example.betagiesheva.helper.MyWebDownloader;
import com.example.betagiesheva.network.NetworkStateReceiver;

import java.io.ByteArrayOutputStream;
import java.util.Arrays;
import java.util.List;
import java.util.Random;

public class MainActivity extends AppCompatActivity implements NetworkStateReceiver.NetworkStateReceiverListener {

    public static String weburls="";
    WebView webView2;
    SwipeRefreshLayout swipeRefreshLayout2;
    LottieAnimationView progress_loading;
    LinearLayout no_Internet;
    TextView nonetTitle, nonetDescription,red,bl,gr;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // For Internet
        MyMethods.startNetworkBroadcastReceiver(this);




        webView2 = findViewById(R.id.webViewf);




        swipeRefreshLayout2 = findViewById(R.id.swipeRefreshLayoutf);
        progress_loading = findViewById(R.id.progress_loading);
        no_Internet = findViewById(R.id.No_Internet);
        nonetTitle = findViewById(R.id.nonetTitle);
        nonetDescription = findViewById(R.id.nonetDescription);


        // Initialize and configure WebView 2 (activity_main2.xml)
        setupWebView(webView2, weburls); // Load URL for WebView 2

        // Optionally ask for notification permission when entering the main web view
        // (kept lightweight – can be moved based on UX preference)
        askNotificationPermission();




    } // OnCreate Method End Here ===================

    @SuppressLint("SuspiciousIndentation")
    @Override
    public void networkAvailable() {
        MyControl.NETWORK_AVAILABLE = true;

        if (MyControl.FAILED_FOR_OTHER_REASON==false)
            no_Internet.setVisibility(View.GONE);
        else
            no_Internet.setVisibility(View.VISIBLE);
    }

    @Override
    public void networkUnavailable() {
        MyControl.NETWORK_AVAILABLE = false;
        no_Internet.setVisibility(View.VISIBLE);
        nonetTitle.setText("No Internet");
        nonetDescription.setText("Please Check Internet Connection and Try Again..");
    }

    @Override
    protected void onPause() {
        MyMethods.unregisterNetworkBroadcastReceiver(this);
        super.onPause();
    }

    @Override
    protected void onResume() {
        MyMethods.registerNetworkBroadcastReceiver(this);
        super.onResume();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        MyWebDownloader.unregisterReceiver(this);
    }
    //=================================================================

    private void WebViewRefresh(WebView webView, SwipeRefreshLayout swipeRefreshLayout) {
        // Check internet connection
        if (!MyMethods.isConnected(MainActivity.this)) {
            // Stop the refresh animation and show no internet message
            swipeRefreshLayout.setRefreshing(false);
            swipeRefreshLayout.setVisibility(View.GONE); // Hide SwipeRefreshLayout
            webView.setVisibility(View.GONE); // Hide the WebView
            no_Internet.setVisibility(View.VISIBLE); // Show no internet message
        } else {
            // Show SwipeRefreshLayout and WebView
            swipeRefreshLayout.setVisibility(View.VISIBLE);
            webView.setVisibility(View.VISIBLE);
            no_Internet.setVisibility(View.GONE);
            progress_loading.setVisibility(View.VISIBLE); // Hide the Lottie animation
            // Start the refreshing animation
            swipeRefreshLayout.setRefreshing(true);

            // Delay for 2 seconds before reloading the WebView
            new Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    // Stop the refresh animation
                    swipeRefreshLayout.setRefreshing(false);
                    progress_loading.setVisibility(View.GONE); // Hide the Lottie animation
                    // Reload the specific WebView
                    if (webView != null) {
                        progress_loading.setVisibility(View.GONE); // Hide the Lottie animation
                        webView.reload(); // Reload the WebView
                    }
                }
            }, 2000);
        }

        // Set color scheme for SwipeRefreshLayout
        swipeRefreshLayout.setColorSchemeColors(
                getResources().getColor(android.R.color.holo_blue_dark),
                getResources().getColor(android.R.color.holo_orange_dark),
                getResources().getColor(android.R.color.holo_green_dark),
                getResources().getColor(android.R.color.holo_red_dark)
        );
    }




    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent intent) {
        super.onActivityResult(requestCode, resultCode, intent);
        if (Build.VERSION.SDK_INT >= 21) {
            Uri[] results = null;

            /*-- if file request cancelled; exited camera. we need to send null value to make future attempts workable --*/
            if (resultCode == Activity.RESULT_CANCELED) {
                MyControl.file_path.onReceiveValue(null);
                return;
            }

            /*-- continue if response is positive --*/
            if (resultCode == Activity.RESULT_OK) {
                if (null == MyControl.file_path) {
                    return;
                }
                ClipData clipData;
                String stringData;

                try {
                    clipData = intent.getClipData();
                    stringData = intent.getDataString();
                } catch (Exception e) {
                    clipData = null;
                    stringData = null;
                }
                if (clipData == null && stringData == null && MyControl.cam_file_data != null) {
                    results = new Uri[]{Uri.parse(MyControl.cam_file_data)};
                } else {
                    if (clipData != null) {
                        final int numSelectedFiles = clipData.getItemCount();
                        results = new Uri[numSelectedFiles];
                        for (int i = 0; i < clipData.getItemCount(); i++) {
                            results[i] = clipData.getItemAt(i).getUri();
                        }
                    } else {
                        try {
                            Bitmap cam_photo = (Bitmap) intent.getExtras().get("data");
                            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
                            cam_photo.compress(Bitmap.CompressFormat.JPEG, 100, bytes);
                            stringData = MediaStore.Images.Media.insertImage(this.getContentResolver(), cam_photo, null, null);
                        } catch (Exception ignored) {
                        }

                        results = new Uri[]{Uri.parse(stringData)};
                    }
                }
            }

            MyControl.file_path.onReceiveValue(results);
            MyControl.file_path = null;
        } else {
            if (requestCode == MyControl.file_req_code) {
                if (null == MyControl.file_data) return;
                Uri result = intent == null || resultCode != RESULT_OK ? null : intent.getData();
                MyControl.file_data.onReceiveValue(result);
                MyControl.file_data = null;
            }
        }

    } // onActivityResult End Here =============

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
    }




    private static final int TIME_INTERVAL = 2000; // # milliseconds, desired
    private long mBackPressed;

    @Override
    public void onBackPressed() {
        // Handle back navigation for WebViews
        if (webView2.canGoBack()) {
            webView2.goBack(); // Go back in WebView 2 if possible
        }
        else {
            finish();
        }
    }
    // end of onBackpressed method

    //#############################################################################################



//////////////////////

    ///////////////

    private void setupWebView(WebView webView, String url) {

        webView.getSettings().setUserAgentString(MyControl.USER_AGENT);
        webView.getSettings().setLoadsImagesAutomatically(true);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setAllowFileAccess(true);
        webView.getSettings().setLoadWithOverviewMode(true);
        webView.getSettings().setUseWideViewPort(true);
        webView.setWebChromeClient(new ChromeClient(MainActivity.this));
        webView.setWebViewClient(new HelloWebViewClient(MainActivity.this));
        webView.getSettings().setDomStorageEnabled(true);

        //web settings
        WebSettings webSettings = webView.getSettings();
        webSettings.setMediaPlaybackRequiresUserGesture(false);
        webSettings.setAllowContentAccess(true);
        webSettings.setDomStorageEnabled(true);

        webSettings.setSaveFormData(true);
        webSettings.setRenderPriority(WebSettings.RenderPriority.HIGH);
        webSettings.setCacheMode(WebSettings.LOAD_DEFAULT);
        webSettings.setLayoutAlgorithm(WebSettings.LayoutAlgorithm.NARROW_COLUMNS);
        webSettings.setUseWideViewPort(true);
        webSettings.setEnableSmoothTransition(true);

        webView.getSettings().setBlockNetworkLoads(false);
        webView.getSettings().setMediaPlaybackRequiresUserGesture(false);
        webView.getSettings().setDomStorageEnabled(true);

        webView.getSettings().setJavaScriptCanOpenWindowsAutomatically(true);
        webView.clearCache(true);
        webView.setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);

        webView.getSettings().setAllowFileAccess(true);
        webView.getSettings().setUserAgentString(getRandomUserAgent());

        webSettings.setSupportZoom(true);
        webSettings.setBuiltInZoomControls(true);
        webSettings.setDisplayZoomControls(false); // Hide the zoom control buttons


        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            webView.getSettings().setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            webView.setWebContentsDebuggingEnabled(true);
        }

        // Enable Cookies
        CookieManager.getInstance().setAcceptCookie(true);
        if (android.os.Build.VERSION.SDK_INT >= 21) {
            CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true);
        }




        // HelloWebViewClient
        new HelloWebViewClient(new MyHelper() {
            @Override
            public void loading() {

            }

            @Override
            public void finishLoading() {

            }

            @Override
            public void webGoBack() {
                webView.goBack();
            }

            @Override
            public void webLoadUrl(String url) {
                webView.loadUrl(url);
            }

            @Override
            public void errorLoading() {
                if(MyControl.NETWORK_AVAILABLE){
                    //We have internet but something went wrong -- Show the error page
                    no_Internet.setVisibility(View.VISIBLE);
                    nonetTitle.setText("Website Load Failed");
                    nonetDescription.setText("Error Reason:\n"+MyControl.LOAD_ERROR_REASON);
                }


            }
        });




        // Handle WebLoading
        new ChromeClient(new MyHelper() {
            @Override
            public void loading() {
                progress_loading.setVisibility(View.VISIBLE);
            }

            @Override
            public void finishLoading() {
                progress_loading.setVisibility(View.GONE);
            }

            @Override
            public void webGoBack() {

            }

            @Override
            public void webLoadUrl(String url) {

            }

            @Override
            public void errorLoading() {

            }
        });




        // Handle Download Loading
        if (MyControl.isDownloading) {
            new MyWebDownloader(new MyHelper() {
                @Override
                public void loading() {
                }

                @Override
                public void finishLoading() {
                    progress_loading.setVisibility(View.GONE);
                }

                @Override
                public void webGoBack() {
                    webView.goBack();
                }

                @Override
                public void webLoadUrl(String url) {

                }

                @Override
                public void errorLoading() {

                }
            });

            MyWebDownloader.WebDownloader(webView, MainActivity.this);
        }

        // For Refresh in WebView



        swipeRefreshLayout2.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                WebViewRefresh(webView2, swipeRefreshLayout2);
            }
        });


        webView.loadUrl(url);



    }

    private String getRandomUserAgent() {
        List<String> userAgents = Arrays.asList(
                "Mozilla/5.0 (Linux; Android 10; Mobile; rv:81.0) Gecko/81.0 Firefox/81.0",
                "Mozilla/5.0 (Linux; Android 9; Mobile; rv:80.0) Gecko/80.0 Firefox/80.0",
                "Mozilla/5.0 (Linux; Android 8.1; Mobile; rv:68.0) Gecko/68.0 Firefox/68.0",
                "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
        );
        Random random = new Random();
        return userAgents.get(random.nextInt(userAgents.size()));
    }





    private final ActivityResultLauncher<String> requestPermissionLauncher =
            registerForActivityResult(new ActivityResultContracts.RequestPermission(), isGranted -> {
                if (isGranted) {
                    // FCM SDK (and your app) can post notifications.
                } else {
                    // Inform user that the app will not show notifications without permission
                    Toast.makeText(this,
                            "নোটিফিকেশন অনুমতি না দিলে আপনি গুরুত্বপূর্ণ আপডেট মিস করতে পারেন।",
                            Toast.LENGTH_LONG).show();
                }
            });

    private void askNotificationPermission() {
        // This is only necessary for API level >= 33 (TIRAMISU)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) ==
                    PackageManager.PERMISSION_GRANTED) {
                // Already granted – nothing to do
            } else if (shouldShowRequestPermissionRationale(android.Manifest.permission.POST_NOTIFICATIONS)) {
                // Show educational UI before requesting permission
                new AlertDialog.Builder(this)
                        .setTitle("নোটিফিকেশন অনুমতি প্রয়োজন")
                        .setMessage("আপডেট, জরুরি বিজ্ঞপ্তি এবং গুরুত্বপূর্ণ বার্তা পেতে নোটিফিকেশন অনুমতি দিন।")
                        .setPositiveButton("ঠিক আছে", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                requestPermissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS);
                            }
                        })
                        .setNegativeButton("না, ধন্যবাদ", (dialog, which) -> {
                            dialog.dismiss();
                        })
                        .show();
            } else {
                // Directly ask for the permission
                requestPermissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS);
            }
        }





    }





} // Public Class End Here ==========================