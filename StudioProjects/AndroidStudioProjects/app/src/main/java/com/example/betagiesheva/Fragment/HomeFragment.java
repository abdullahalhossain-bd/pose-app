package com.example.betagiesheva.Fragment;


import static android.content.Context.MODE_PRIVATE;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;

import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TableLayout;
import android.widget.TableRow;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.android.volley.DefaultRetryPolicy;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonArrayRequest;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.denzcoskun.imageslider.ImageSlider;
import com.denzcoskun.imageslider.constants.ScaleTypes;
import com.denzcoskun.imageslider.models.SlideModel;
import com.example.betagiesheva.AppsDetailsActivity;
import com.example.betagiesheva.BudgetDetailsActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.MainActivity;
import com.example.betagiesheva.R;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;

public class HomeFragment extends Fragment {


    TextView txtMarquee;
    private TextView cityName, temperature, feelsLike, weatherDescription,currentDay,dayPhaseTextView,sunriseTextView,sunsetTextView;
    private ImageView weatherIcon;
    private ImageView refreshButton;

    // OpenWeatherMap API key (free tier). For production, replace with a key stored in gradle.properties.
    private final String API_KEY = "9e0aa9415e08b1813f541bf13e4ce566";
    // Betagi is in Barishal district, Bangladesh. Previous value "Sirajganj" was a template leftover.
    private final String CITY_NAME = "Betagi,BD";


    CardView sirajganj,weathers,fbpage,fbgroup;
    LinearLayout hotlines;
    ImageSlider imageSlider;

    private final NumberFormat banglaNumberFormat = NumberFormat.getInstance(new Locale("bn", "BD"));

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        // Inflate the fragment layout
        View view = inflater.inflate(R.layout.fragment_home, container, false);


        // casting of textview
        txtMarquee = view.findViewById(R.id.marqueeText);
        txtMarquee.setSelected(true);

        fetchNoticeFromServer();

        temperature = view.findViewById(R.id.temperature);
        feelsLike = view.findViewById(R.id.feelsLike);
        weatherDescription = view.findViewById(R.id.weatherDescription);
        weatherIcon = view.findViewById(R.id.weatherIcon);
        refreshButton = view.findViewById(R.id.refreshButton);
        dayPhaseTextView = view.findViewById(R.id.dayPhaseTextView);
        currentDay = view.findViewById(R.id.dayTextView);
        sunriseTextView = view.findViewById(R.id.sunriseTextView);
        sunsetTextView = view.findViewById(R.id.sunsetTextView);

        sirajganj = view.findViewById(R.id.srin);
        weathers = view.findViewById(R.id.wetherin);
        fbgroup = view.findViewById(R.id.fbgrin);
        fbpage = view.findViewById(R.id.fbpagein);
        hotlines = view.findViewById(R.id.hotline);



        // Find the ImageSlider view
        imageSlider = view.findViewById(R.id.image_slider);



        // ProfileFragment already fetches the user's profile from the server via Config.PROFILE_URL
        // and saves it to SessionManager. The previous fetchUserData() call here was dead code that
        // hit a wrong template URL (R.string.user) and read non-existent JSON fields (user_id, user_name,
        // user_password, user_image_url). Removed entirely.

        fetchSliderImages();

        fetchWeatherData();

        updateDayAndPhase();
        weatherDataShow();

        refreshButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                fetchWeatherData();
                weatherDataShow();
            }
        });



        sirajganj.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent=new Intent(getContext(), AppsDetailsActivity.class);
                startActivity(intent);
            }
        });
        weathers.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Betagi info page — using the national portal's Betagi page as a safe default.
                MainActivity.weburls="https://en.wikipedia.org/wiki/Betagi_Upazila";
                Intent intent=new Intent(getContext(), MainActivity.class);
                startActivity(intent);
            }
        });
        fbpage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openFacebookPage();
            }
        });
        fbgroup.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openFacebookGroup();
            }
        });


        // Make individual hotline cards directly callable
        View hotline999Card = view.findViewById(R.id.hotline_999_card);
        View hotline109Card = view.findViewById(R.id.hotline_109_card);
        View hotline16263Card = view.findViewById(R.id.hotline_16263_card);

        if (hotline999Card != null) {
            hotline999Card.setOnClickListener(v -> dialNumber("999"));
        }
        if (hotline109Card != null) {
            hotline109Card.setOnClickListener(v -> dialNumber("109"));
        }
        if (hotline16263Card != null) {
            hotline16263Card.setOnClickListener(v -> dialNumber("16263"));
        }



        return view;
    }

    private void dialNumber(String number) {
        if (getContext() == null || number == null || number.trim().isEmpty()) {
            return;
        }
        try {
            Intent intent = new Intent(Intent.ACTION_DIAL);
            intent.setData(Uri.parse("tel:" + number));
            startActivity(intent);
        } catch (Exception ignored) {
        }
    }


    private void fetchWeatherData() {
        String url = "https://api.openweathermap.org/data/2.5/weather?q=" + CITY_NAME + "&units=metric&appid=" + API_KEY;

        RequestQueue queue = Volley.newRequestQueue(getContext());

        StringRequest stringRequest = new StringRequest(Request.Method.GET, url,
                new Response.Listener<String>() {
                    @Override
                    public void onResponse(String response) {
                        try {
                            JSONObject jsonObject = new JSONObject(response);

                            // Get main data
                            JSONObject main = jsonObject.getJSONObject("main");
                            String temp = main.getString("temp");
                            String feelsLikeTemp = main.getString("feels_like");

                            // Get weather description
                            JSONObject weather = jsonObject.getJSONArray("weather").getJSONObject(0);
                            String description = weather.getString("description").toLowerCase();

                            // Translate description to Bengali
                            String bengaliDescription = getBengaliDescription(description);

                            SharedPreferences sharedPreferences = getContext().getSharedPreferences("WeatherPrefs", MODE_PRIVATE);
                            SharedPreferences.Editor editor = sharedPreferences.edit();
                            editor.putString("temp", temp);
                            editor.putString("feel", feelsLikeTemp);
                            editor.putString("situation", bengaliDescription);

                            editor.apply();


                            // Set the appropriate icon
                            setWeatherIcon(description);

                            temperature.setText(temp + "°C");
                            feelsLike.setText("মনে হচ্ছে: " + feelsLikeTemp + "°C");
                            weatherDescription.setText("অবস্থা: " + bengaliDescription);

                        } catch (Exception e) {
                            // Toast.makeText(getContext(), "ডেটা প্রক্রিয়াকরণে ত্রুটি", Toast.LENGTH_SHORT).show();
                        }
                    }
                }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                // Toast.makeText(getContext(), "ডেটা আনার সময় ত্রুটি", Toast.LENGTH_SHORT).show();
            }
        });

        queue.add(stringRequest);
    }

    private void setWeatherIcon(String description) {
        switch (description) {
            case "clear sky":
                weatherIcon.setImageResource(R.drawable.cloudy); // Replace with your sunny icon
                break;
            case "few clouds":
            case "scattered clouds":
                weatherIcon.setImageResource(R.drawable.cloud); // Replace with your partly cloudy icon
                break;
            case "broken clouds":
            case "overcast clouds":
                weatherIcon.setImageResource(R.drawable.brokencloud); // Replace with your cloudy icon
                break;
            case "fog":
            case "mist":
            case "haze":
                weatherIcon.setImageResource(R.drawable.fog); // Replace with your fog icon
                break;
            case "shower rain":
            case "rain":
            case "light rain":
            case "moderate rain":
            case "heavy intensity rain":
                weatherIcon.setImageResource(R.drawable.raining); // Replace with your rainy icon
                break;
            case "thunderstorm":
                weatherIcon.setImageResource(R.drawable.thunderstorm); // Replace with your thunderstorm icon
                break;
            case "snow":
            case "light snow":
            case "heavy snow":
                weatherIcon.setImageResource(R.drawable.snowy); // Replace with your snowy icon
                break;
            case "sleet":
            case "freezing rain":
                weatherIcon.setImageResource(R.drawable.sleet); // Replace with your sleet icon
                break;
            case "sand":
            case "dust":
            case "ash":
            case "smoke":
                weatherIcon.setImageResource(R.drawable.smog); // Replace with your dusty icon
                break;
            case "tornado":
                weatherIcon.setImageResource(R.drawable.tornado); // Replace with your tornado icon
                break;
            default:
                weatherIcon.setImageResource(R.drawable.cloudy); // Default weather icon
                break;
        }
    }

    private String getBengaliDescription(String description) {
        HashMap<String, String> translations = new HashMap<>();
        translations.put("clear sky", "পরিষ্কার আকাশ");
        translations.put("few clouds", "অল্প মেঘ");
        translations.put("scattered clouds", "ছিটিয়ে থাকা মেঘ");
        translations.put("broken clouds", "ভাঙা মেঘ");
        translations.put("overcast clouds", "ঢেকে থাকা আকাশ");
        translations.put("fog", "কুয়াশা");
        translations.put("mist", "মিহি কুয়াশা");
        translations.put("haze", "মেঘাচ্ছন্ন কুয়াশা");
        translations.put("shower rain", "ছিটিয়ে থাকা বৃষ্টি");
        translations.put("rain", "বৃষ্টি");
        translations.put("light rain", "হালকা বৃষ্টি");
        translations.put("moderate rain", "মাঝারি বৃষ্টি");
        translations.put("heavy intensity rain", "তীব্র বৃষ্টি");
        translations.put("thunderstorm", "বজ্রঝড়");
        translations.put("snow", "তুষারপাত");
        translations.put("light snow", "হালকা তুষারপাত");
        translations.put("heavy snow", "তীব্র তুষারপাত");
        translations.put("sleet", "বরফ বৃষ্টি");
        translations.put("freezing rain", "জমাট বাঁধা বৃষ্টি");
        translations.put("sand", "বালি ঝড়");
        translations.put("dust", "ধুলো ঝড়");
        translations.put("ash", "ছাই ঝড়");
        translations.put("smoke", "ধোঁয়াশা");
        translations.put("tornado", "ঘূর্ণিঝড়");

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return translations.getOrDefault(description, description); // Return the original description if no translation is found
        }
        return description;
    }

    private void updateDayAndPhase() {
        Calendar calendar = Calendar.getInstance();
        SimpleDateFormat dayFormat = new SimpleDateFormat("EEEE", new Locale("bn", "BD")); // Bengali Locale for Bangladesh




        String day = dayFormat.format(calendar.getTime());


        SharedPreferences sharedPreferences = getContext().getSharedPreferences("WeatherPrefs", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString("day", day);
        editor.apply();

        currentDay.setText(day);



        // Fetch and display sunrise and sunset times
        fetchSunriseAndSunsetTimes(calendar);
    }

    private void fetchSunriseAndSunsetTimes(Calendar calendar) {
        String url = "https://api.openweathermap.org/data/2.5/weather?q=" + CITY_NAME + "&units=metric&appid=" + API_KEY;

        RequestQueue queue = Volley.newRequestQueue(getContext());

        StringRequest stringRequest = new StringRequest(Request.Method.GET, url,
                new Response.Listener<String>() {
                    @Override
                    public void onResponse(String response) {
                        try {
                            JSONObject jsonObject = new JSONObject(response);
                            JSONObject sys = jsonObject.getJSONObject("sys");

                            // Get sunrise and sunset times in seconds (UNIX timestamp)
                            long sunrise = sys.getLong("sunrise");
                            long sunset = sys.getLong("sunset");

                            // Adjust times to milliseconds (as Calendar uses milliseconds)
                            sunrise *= 1000;
                            sunset *= 1000;

                            // Get current time in milliseconds
                            long currentTime = System.currentTimeMillis();

                            // Update day phase based on sunrise, sunset, and current time
                            updateDayPhase(sunrise, sunset, currentTime);

                            // Format and display the sunrise and sunset times
                            displaySunriseAndSunsetTimes(sunrise, sunset);

                        } catch (Exception e) {
                            //  Toast.makeText(getContext(), "ডেটা প্রক্রিয়াকরণে ত্রুটি", Toast.LENGTH_SHORT).show();
                        }
                    }
                }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                //  Toast.makeText(getContext(), "ডেটা আনার সময় ত্রুটি", Toast.LENGTH_SHORT).show();
            }
        });

        queue.add(stringRequest);
    }

    private void displaySunriseAndSunsetTimes(long sunriseTime, long sunsetTime) {
        // Convert sunrise and sunset times to a readable format
        SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm", Locale.getDefault());

        // Format sunrise and sunset times
        String sunriseFormatted = timeFormat.format(new Date(sunriseTime));
        String sunsetFormatted = timeFormat.format(new Date(sunsetTime));

        SharedPreferences sharedPreferences = getContext().getSharedPreferences("WeatherPrefs", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString("sunrise", sunriseFormatted);
        editor.putString("sunset", sunsetFormatted);
        editor.apply();

        sunriseTextView.setText("সূর্যোদয়ের সময়:\n" + sunriseFormatted);
        sunsetTextView.setText("সূর্যাস্তের সময়:\n" + sunsetFormatted);

    }

    private void updateDayPhase(long sunriseTime, long sunsetTime, long currentTime) {
        String phase;

        // Sunrise to 30 minutes after sunrise
        if (currentTime >= sunriseTime && currentTime < sunriseTime + 30 * 60 * 1000) { // 30 minutes
            phase = "এখন: সূর্যোদয়"; // Sunrise phase
        }
        // 30 minutes after sunrise to noon
        else if (currentTime >= sunriseTime + 30 * 60 * 1000 && currentTime < sunriseTime + 6 * 3600 * 1000) {
            phase = "এখন: সকাল"; // Morning phase
        }
        // Noon to 2 hours before sunset
        else if (currentTime >= sunriseTime + 6 * 3600 * 1000 && currentTime < sunsetTime - 2 * 3600 * 1000) {
            phase = "এখন: দুপুর"; // Afternoon phase
        }
        // 2 hours before sunset to sunset
        else if (currentTime >= sunsetTime - 2 * 3600 * 1000 && currentTime < sunsetTime) {
            phase = "এখন: বিকেল"; // Evening phase
        }
        // Sunset to 20 minutes after sunset
        else if (currentTime >= sunsetTime && currentTime < sunsetTime + 20 * 60 * 1000) { // 20 minutes
            phase = "এখন: সন্ধ্যা"; // Twilight phase
        }
        // 20 minutes after sunset to midnight
        else if (currentTime >= sunsetTime + 20 * 60 * 1000 && currentTime < sunriseTime + 24 * 3600 * 1000) {
            phase = "এখন: রাত"; // Night phase
        }
        // Midnight to sunrise
        else {
            phase = "এখন: রাত"; // Midnight phase
        }

        SharedPreferences sharedPreferences = getContext().getSharedPreferences("WeatherPrefs", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString("dayphase", phase);
        editor.apply();
        dayPhaseTextView.setText(phase);
    }






    private void openFacebookPage() {
        // Betagi E-Sheva Facebook page (placeholder — admin updates via remote config later).
        String facebookPageId = "betagi.esheva";
        String facebookUrl = "https://www.facebook.com/" + facebookPageId;
        String facebookAppUrl = "fb://page/" + facebookPageId;

        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(facebookAppUrl));
            startActivity(intent);
        } catch (ActivityNotFoundException e) {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(facebookUrl));
            startActivity(intent);
        }
    }


    private void openFacebookGroup() {
        // Betagi community group (placeholder — admin updates via remote config later).
        // Using the page URL as fallback since no group ID is configured yet.
        String groupUrl = "https://www.facebook.com/betagi.esheva";

        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(groupUrl));
            startActivity(intent);
        } catch (ActivityNotFoundException e) {
            // No fallback needed — URL opens in browser by default
        }
    }


    private void fetchSliderImages() {
        // No slider endpoint exists on the Betagi server yet. The previous code called
        // getString(R.string.homeImageSlider) which pointed to a wrong template URL
        // (https://maxplay-tv.fun/sirajganj/...). Until a /get_slider_images.php endpoint
        // is added to the server, we use local drawable images.
        List<SlideModel> slideModels = new ArrayList<>();
        slideModels.add(new SlideModel(R.drawable.bibichini, ScaleTypes.FIT));
        slideModels.add(new SlideModel(R.drawable.mokamia, ScaleTypes.FIT));
        slideModels.add(new SlideModel(R.drawable.park, ScaleTypes.FIT));
        slideModels.add(new SlideModel(R.drawable.resombari, ScaleTypes.FIT));
        imageSlider.setImageList(slideModels);
    }


    private void weatherDataShow(){

        // Retrieve weather data from SharedPreferences
        SharedPreferences sharedPreferences = getContext().getSharedPreferences("WeatherPrefs", MODE_PRIVATE);
        String temp = sharedPreferences.getString("temp", "N/A");
        String feelsLikeTemp = sharedPreferences.getString("feel", "N/A");
        String bengaliDescription = sharedPreferences.getString("situation", "N/A");
        String day = sharedPreferences.getString("day", "N/A");
        String phase = sharedPreferences.getString("dayphase", "N/A");
        String sunriseFormatted = sharedPreferences.getString("sunrise", "N/A");
        String sunsetFormatted = sharedPreferences.getString("sunset", "N/A");




        temperature.setText(temp + "°C");
        feelsLike.setText("মনে হচ্ছে: " + feelsLikeTemp + "°C");
        weatherDescription.setText("অবস্থা: " + bengaliDescription);
        currentDay.setText(day);

        dayPhaseTextView.setText(phase);
        sunriseTextView.setText("সূর্যোদয়ের সময়:\n" + sunriseFormatted);
        sunsetTextView.setText("সূর্যাস্তের সময়:\n" + sunsetFormatted);



    }

    private void fetchNoticeFromServer() {
        // Server's get_notice.php returns a RAW JSON ARRAY (not {notice: "..."}).
        // We fetch the latest notice and use its title as the marquee text.
        RequestQueue requestQueue = Volley.newRequestQueue(getContext());

        JsonArrayRequest jsonArrayRequest = new JsonArrayRequest(
                Request.Method.GET,
                Config.NOTICE_LIST_URL,
                null,
                response -> {
                    try {
                        if (response.length() > 0) {
                            JSONObject latest = response.getJSONObject(0);
                            String title = latest.optString("title", "");
                            if (!title.isEmpty()) {
                                txtMarquee.setText("📢 " + title);
                            } else {
                                txtMarquee.setText("📢 কোনো নতুন নোটিস নেই");
                            }
                        } else {
                            txtMarquee.setText("📢 কোনো নতুন নোটিস নেই");
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        txtMarquee.setText("📢 কোনো নতুন নোটিস নেই");
                    }
                },
                error -> {
                    error.printStackTrace();
                    txtMarquee.setText("📢 নোটিস লোড করতে সমস্যা হয়েছে");
                }
        );

        requestQueue.add(jsonArrayRequest);
    }



    private double resolveNumber(JSONObject source, String... keys) {
        if (source == null || keys == null) {
            return 0;
        }
        for (String key : keys) {
            if (source.has(key)) {
                return parseNumber(source, key);
            }
        }
        return 0;
    }

    private double parseNumber(JSONObject source, String key) {
        if (source == null || key == null) {
            return 0;
        }
        Object value = source.opt(key);
        if (value instanceof Number) {
            return ((Number) value).doubleValue();
        }
        if (value instanceof String) {
            try {
                return Double.parseDouble((String) value);
            } catch (NumberFormatException ignored) {
            }
        }
        return 0;
    }

    private String formatCurrency(double amount) {
        if (Double.isNaN(amount) || Double.isInfinite(amount)) {
            amount = 0;
        }
        return banglaNumberFormat.format(amount);
    }

    private String formatCurrencyWithSuffix(double amount) {
        return formatCurrency(amount) + " টাকা";
    }



    @Override
    public void onResume() {
        super.onResume();
        // Fetch the weather data again when the user returns to this activity
        fetchWeatherData();
        weatherDataShow();
    }



    // fetchUserData() was previously here but was DEAD CODE — it called a wrong template URL
    // (R.string.user → https://maxplay-tv.fun/...) and read non-existent JSON fields like
    // user_password (storing passwords locally is also a security smell). ProfileFragment
    // already handles profile fetching correctly via Config.PROFILE_URL using SessionManager.
    // Removed entirely to avoid confusion and network waste.



}