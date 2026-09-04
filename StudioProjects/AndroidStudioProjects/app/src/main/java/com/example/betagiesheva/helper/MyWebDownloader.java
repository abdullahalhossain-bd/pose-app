package com.example.betagiesheva.helper;

import static android.content.Context.DOWNLOAD_SERVICE;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.util.Log;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.URLUtil;
import android.webkit.WebView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

public class MyWebDownloader {

    static MyHelper myHelper;
    private static BroadcastReceiver onComplete;

    public MyWebDownloader(MyHelper myHelper) {
        MyWebDownloader.myHelper = myHelper;
    }

    public MyWebDownloader() {
    }

    public static void WebDownloader(WebView webView, Activity activity) {
        webView.setDownloadListener(new DownloadListener() {
            @Override
            public void onDownloadStart(final String url, final String userAgent, String contentDisposition, String mimetype, long contentLength) {
                if (Build.VERSION.SDK_INT >= 33) {
                    if (ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_MEDIA_IMAGES) != PackageManager.PERMISSION_GRANTED
                            && ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_MEDIA_AUDIO) != PackageManager.PERMISSION_GRANTED
                            && ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_MEDIA_VIDEO) != PackageManager.PERMISSION_GRANTED) {

                        ActivityCompat.requestPermissions(
                                activity, new String[]{Manifest.permission.READ_MEDIA_IMAGES,
                                        Manifest.permission.READ_MEDIA_AUDIO, Manifest.permission.READ_MEDIA_VIDEO}, 1);

                        Log.v("WebBrowser", "Permission is revoked");
                        myHelper.finishLoading();

                    } else {
                        Log.v("WebBrowser", "Permission is granted");
                        downloadDialog(url, userAgent, contentDisposition, mimetype, activity);
                    }
                } else if (Build.VERSION.SDK_INT >= 23) {
                    if (activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
                        Log.v("WebBrowser", "Permission is granted");
                        downloadDialog(url, userAgent, contentDisposition, mimetype, activity);

                    } else {
                        Log.v("WebBrowser", "Permission is revoked");
                        myHelper.finishLoading();
                        ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
                    }
                } else {
                    Log.v("WebBrowser", "Permission is granted");
                    downloadDialog(url, userAgent, contentDisposition, mimetype, activity);
                    myHelper.finishLoading();
                }
            }
        });
    }

    public static void downloadDialog(final String url, final String userAgent, String contentDisposition, String mimetype, Activity activity) {
        final String filename = URLUtil.guessFileName(url, contentDisposition, mimetype);

        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setTitle("Downloading");
        builder.setMessage("We are trying to download: " + filename);

        builder.setPositiveButton("Download", new DialogInterface.OnClickListener() {
            @SuppressLint("UnspecifiedRegisterReceiverFlag")
            @Override
            public void onClick(DialogInterface dialog, int which) {
                myHelper.finishLoading();

                // Configure the download request
                DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
                String cookie = CookieManager.getInstance().getCookie(url);
                request.addRequestHeader("Cookie", cookie);
                request.addRequestHeader("User-Agent", userAgent);
                request.allowScanningByMediaScanner();
                request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, filename);

                DownloadManager downloadManager = (DownloadManager) activity.getSystemService(DOWNLOAD_SERVICE);
                downloadManager.enqueue(request);

                // BroadcastReceiver for download completion
                onComplete = new BroadcastReceiver() {
                    public void onReceive(Context ctxt, Intent intent) {
                        Toast.makeText(activity, "Download Complete", Toast.LENGTH_SHORT).show();
                    }
                };

                // Register the receiver with the appropriate flag
                IntentFilter filter = new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { // Android 13 and above
                    activity.registerReceiver(onComplete, filter, Context.RECEIVER_NOT_EXPORTED);
                } else {
                    activity.registerReceiver(onComplete, filter);
                }
            }
        });

        builder.setNegativeButton("NOT NOW", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                myHelper.finishLoading();
                dialog.cancel();
                myHelper.webGoBack();
            }
        });

        builder.show();
    }

    public static void unregisterReceiver(Activity activity) {
        if (onComplete != null) {
            try {
                activity.unregisterReceiver(onComplete);
            } catch (IllegalArgumentException e) {
                Log.w("MyWebDownloader", "Receiver already unregistered");
            }
        }
    }
}
