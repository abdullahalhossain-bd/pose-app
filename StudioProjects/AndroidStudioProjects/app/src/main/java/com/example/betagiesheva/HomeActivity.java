package com.example.betagiesheva;

import android.animation.ObjectAnimator;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import androidx.core.content.ContextCompat;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;

import com.example.betagiesheva.Fragment.GovtServiceFragment;
import com.example.betagiesheva.Fragment.HomeFragment;
import com.example.betagiesheva.Fragment.NoticeFragment;
import com.example.betagiesheva.Fragment.ProfileFragment;
import com.example.betagiesheva.Fragment.ServiceFragment;
import com.google.android.material.navigation.NavigationView;

public class HomeActivity extends AppCompatActivity {

    private View currentlyPushedUp = null;
    private boolean doubleBackToExitPressedOnce = false;

    private DrawerLayout drawerLayout;
    SessionManager sessionManager;

    String userId = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 🔐 Session check

        setContentView(R.layout.activity_home);

        // Load user id
        SharedPreferences pref = getSharedPreferences(Config.PREF_NAME, MODE_PRIVATE);
        userId = pref.getString("id", "");

        LinearLayout navHome = findViewById(R.id.nav_home);
        LinearLayout navNotice = findViewById(R.id.nav_notice);
        LinearLayout navPromote = findViewById(R.id.nav_promote);
        LinearLayout navPost = findViewById(R.id.nav_post);
        LinearLayout navProfile = findViewById(R.id.nav_profile);

        // Back press handling
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                handleCustomBackPressed();
            }
        });

        if (savedInstanceState == null) {
            loadFragment(new HomeFragment());
        }

        if (savedInstanceState != null) {
            int viewId = savedInstanceState.getInt("currentlyPushedUpId", -1);
            if (viewId != -1) {
                View restoredView = findViewById(viewId);
                if (restoredView != null) {
                    pushUpView(restoredView);
                    currentlyPushedUp = restoredView;
                }
            }
        }

        navHome.setOnClickListener(v -> handleNavigationClick(navHome, new HomeFragment()));
        navNotice.setOnClickListener(v -> handleNavigationClick(navNotice, new NoticeFragment()));
        navPromote.setOnClickListener(v -> handleNavigationClick(navPromote, new GovtServiceFragment()));
        navPost.setOnClickListener(v -> handleNavigationClick(navPost, new ServiceFragment()));
        navProfile.setOnClickListener(v -> handleNavigationClick(navProfile, new ProfileFragment()));

        drawerLayout = findViewById(R.id.drawer_layout);
        findViewById(R.id.draw).setOnClickListener(v ->
                drawerLayout.openDrawer(GravityCompat.START));

        ActionBarDrawerToggle toggle =
                new ActionBarDrawerToggle(this, drawerLayout,
                        R.string.open, R.string.close);
        drawerLayout.addDrawerListener(toggle);
        toggle.syncState();

        NavigationView navigationView = findViewById(R.id.navigation_view);
        navigationView.setNavigationItemSelectedListener(this::handleDrawerMenu);

        CardView notification = findViewById(R.id.notification);
        notification.setOnClickListener(v ->
                startActivity(new Intent(this, NotifiationActivity.class)));

        askNotificationPermission();

        new Handler().postDelayed(this::showCustomDialogUno, 500);
    }

    private void handleNavigationClick(View view, Fragment fragment) {
        if (currentlyPushedUp != null && currentlyPushedUp != view) {
            resetViewPosition(currentlyPushedUp);
        }
        pushUpView(view);
        currentlyPushedUp = view;
        loadFragment(fragment);
    }

    private void loadFragment(Fragment fragment) {
        Fragment current = getSupportFragmentManager()
                .findFragmentById(R.id.fragment_container);

        if (current != null && current.getClass().equals(fragment.getClass())) return;

        getSupportFragmentManager().beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
    }

    private void pushUpView(View view) {
        float pushDistance = view.getHeight() * 0.07f;
        ObjectAnimator.ofFloat(view, "translationY", 0f, -pushDistance)
                .setDuration(300).start();
        view.setBackgroundResource(R.drawable.red);
    }

    private void resetViewPosition(View view) {
        ObjectAnimator.ofFloat(view, "translationY",
                        view.getTranslationY(), 0f)
                .setDuration(300).start();
        view.setBackgroundResource(R.drawable.gr);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putInt("currentlyPushedUpId",
                currentlyPushedUp != null ? currentlyPushedUp.getId() : -1);
    }

    private boolean handleDrawerMenu(MenuItem item) {

        Fragment selectedFragment = null;

        if (item.getItemId() == R.id.nav_home) {
            selectedFragment = new HomeFragment();
        } else if (item.getItemId() == R.id.nav_promote) {
            selectedFragment = new GovtServiceFragment();
        } else if (item.getItemId() == R.id.nav_service) {
            selectedFragment = new ServiceFragment();
        } else if (item.getItemId() == R.id.nav_profile) {
            selectedFragment = new ProfileFragment();
        }
        if (selectedFragment != null) {
            getSupportFragmentManager().beginTransaction()
                    .replace(R.id.fragment_container, selectedFragment)
                    .commit();
        }

        drawerLayout.closeDrawer(GravityCompat.START);
        return true;
    }

    private void handleCustomBackPressed() {
        Fragment current = getSupportFragmentManager()
                .findFragmentById(R.id.fragment_container);

        if (current != null && !(current instanceof HomeFragment)) {
            loadFragment(new HomeFragment());
            if (currentlyPushedUp != null) {
                resetViewPosition(currentlyPushedUp);
                currentlyPushedUp = null;
            }
        } else if (!doubleBackToExitPressedOnce) {
            doubleBackToExitPressedOnce = true;
            Toast.makeText(this,
                    "আরেকবার ব্যাক চাপুন অ্যাপ বন্ধ করতে",
                    Toast.LENGTH_SHORT).show();
            new Handler().postDelayed(
                    () -> doubleBackToExitPressedOnce = false, 2000);
        } else {
            finishAffinity();
        }
    }

    private final ActivityResultLauncher<String> requestPermissionLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.RequestPermission(),
                    isGranted -> {
                        if (!isGranted) {
                            Toast.makeText(this,
                                    "নোটিফিকেশন অনুমতি না দিলে আপডেট মিস হতে পারে",
                                    Toast.LENGTH_LONG).show();
                        }
                    });

    private void askNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this,
                    android.Manifest.permission.POST_NOTIFICATIONS)
                    != PackageManager.PERMISSION_GRANTED) {

                requestPermissionLauncher.launch(
                        android.Manifest.permission.POST_NOTIFICATIONS);
            }
        }
    }

    private void showCustomDialogUno() {
        Dialog dialog = new Dialog(this);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setContentView(R.layout.custom_dialog_uno);
        dialog.setCancelable(true);

        ImageButton btnClose = dialog.findViewById(R.id.btnClose);
        if (btnClose != null) btnClose.setOnClickListener(v -> dialog.dismiss());

        dialog.show();
    }
}
