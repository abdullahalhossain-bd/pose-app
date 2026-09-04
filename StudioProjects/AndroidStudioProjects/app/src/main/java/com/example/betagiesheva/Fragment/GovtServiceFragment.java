package com.example.betagiesheva.Fragment;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import com.example.betagiesheva.Config;
import com.example.betagiesheva.IctinfoActivity;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;
import com.example.betagiesheva.UnionActivity;
import com.example.betagiesheva.UnoActivity;
import com.example.betagiesheva.WebActivity;

public class GovtServiceFragment extends Fragment {

    private View rootView; // To hold the root view of the fragment

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        rootView = inflater.inflate(R.layout.fragment_govt_service, container, false);
        return rootView;
    }

    @Override
    public void onViewCreated(@NonNull View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setupCardClickListeners();
        setupViewAllRequests();
        setupFeeCalculator();
        setupGovernmentProjects();
        setupGovernmentWebsites();
    }

    private void setupCardClickListeners() {
        // Setup card click listeners using helper methods
        rootView.findViewById(R.id.ict).setOnClickListener(v -> startActivity(IctinfoActivity.class));
        rootView.findViewById(R.id.uno).setOnClickListener(v -> startActivity(UnoActivity.class));
        rootView.findViewById(R.id.union).setOnClickListener(v -> startActivity(UnionActivity.class));

        // Setup web activity cards
        setupWebCard(R.id.certificate, "https://uniontax.gov.bd/sonod/search", "সনদ যাচাই");
        setupWebCard(R.id.card4, "https://www.uniontax.gov.bd/application/Citizenship_certificate", "নাগরিক সনদ");
        setupWebCard(R.id.card5, "https://www.uniontax.gov.bd/application/Certificate_of_Character", "চারিত্রিক সনদ");
        setupWebCard(R.id.card6, "https://bdris.gov.bd/dr/application", "মৃত্যু সনদ");
        setupWebCard(R.id.card7, "https://bdris.gov.bd/br/application", "জন্ম নিবন্ধন");
        setupWebCard(R.id.card8, "https://uniontax.gov.bd/application/Disability_application", "প্রতিবন্ধী সনদ");
        setupWebCard(R.id.card10, "https://www.uniontax.gov.bd/application/Unmarried_certificate", "অবিবাহিত সনদ");
        setupWebCard(R.id.card11, "https://uniontax.gov.bd/application/Landless_certificate", "ভূমিহীন সনদ");
        setupWebCard(R.id.card13, "https://www.epassport.gov.bd/onboarding", "ই-পাসপোর্ট");

        setupCitizenServiceCards();
    }

    private void setupViewAllRequests() {
        View viewAll = rootView.findViewById(R.id.viewAllRequests);
        if (viewAll != null) {
            viewAll.setOnClickListener(v -> {
                // For now, open the generic union tax citizen portal to track applications
                setupWebCardLaunch("https://www.uniontax.gov.bd/", "সেবা আবেদন সমূহ");
            });
        }
    }

    private void setupFeeCalculator() {
        AutoCompleteTextView serviceTypeAutoComplete = rootView.findViewById(R.id.serviceTypeAutoComplete);
        TextView feeAmount = rootView.findViewById(R.id.feeAmount);

        if (serviceTypeAutoComplete == null || feeAmount == null) return;

        // Define a simple in-app fee table
        String[] serviceTypes = {
                "নাগরিক সনদ",
                "চারিত্রিক সনদ",
                "জন্ম সনদ",
                "মৃত্যু সনদ",
                "প্রতিবন্ধী সনদ",
                "অবিবাহিত সনদ",
                "ভূমিহীন সনদ"
        };

        final int[] fees = {
                50,  // নাগরিক সনদ
                100, // চারিত্রিক সনদ
                25,  // জন্ম সনদ
                25,  // মৃত্যু সনদ
                0,   // প্রতিবন্ধী সনদ
                100, // অবিবাহিত সনদ
                0    // ভূমিহীন সনদ
        };

        ArrayAdapter<String> adapter = new ArrayAdapter<>(
                requireContext(),
                android.R.layout.simple_dropdown_item_1line,
                serviceTypes
        );
        serviceTypeAutoComplete.setAdapter(adapter);

        serviceTypeAutoComplete.setOnItemClickListener((parent, view, position, id) -> {
            int fee = (position >= 0 && position < fees.length) ? fees[position] : 0;
            feeAmount.setText("৳ " + fee);
        });
    }

    private void setupGovernmentProjects() {
        View currentProjects = rootView.findViewById(R.id.current_projects_card);
        View applyProjects = rootView.findViewById(R.id.apply_projects_card);

        if (currentProjects != null) {
            currentProjects.setOnClickListener(v ->
                    setupWebCardLaunch("https://www.lged.gov.bd/", "চলমান সরকারি প্রকল্প")
            );
        }

        if (applyProjects != null) {
            applyProjects.setOnClickListener(v ->
                    setupWebCardLaunch("https://www.uniontax.gov.bd/", "প্রকল্পে আবেদন")
            );
        }
    }

    private void setupGovernmentWebsites() {
        // National portal
        View nationalPortal = rootView.findViewById(R.id.card_national_portal);
        if (nationalPortal != null) {
            nationalPortal.setOnClickListener(v ->
                    setupWebCardLaunch("https://www.nationalportal.gov.bd/", "জাতীয় পোর্টাল")
            );
        }

        // E-services
        View eServices = rootView.findViewById(R.id.card_e_services);
        if (eServices != null) {
            eServices.setOnClickListener(v ->
                    setupWebCardLaunch("https://services.nidw.gov.bd/", "ই-সেবা")
            );
        }

        // Tax department
        View taxDept = rootView.findViewById(R.id.card_tax_department);
        if (taxDept != null) {
            taxDept.setOnClickListener(v ->
                    setupWebCardLaunch("https://nbr.gov.bd/", "কর বিভাগ")
            );
        }

        // Education board
        View educationBoard = rootView.findViewById(R.id.card_education_board);
        if (educationBoard != null) {
            educationBoard.setOnClickListener(v ->
                    setupWebCardLaunch("https://www.educationboardresults.gov.bd/", "শিক্ষা বোর্ড")
            );
        }

        // Health ministry
        View healthMinistry = rootView.findViewById(R.id.card_health_ministry);
        if (healthMinistry != null) {
            healthMinistry.setOnClickListener(v ->
                    setupWebCardLaunch("https://dghs.gov.bd/", "স্বাস্থ্য মন্ত্রণালয়")
            );
        }

        // Transport department
        View transportDept = rootView.findViewById(R.id.card_transport_department);
        if (transportDept != null) {
            transportDept.setOnClickListener(v ->
                    setupWebCardLaunch("https://brta.gov.bd/", "পরিবহন বিভাগ")
            );
        }
    }

    private void setupWebCardLaunch(String url, String title) {
        Intent intent = new Intent(getActivity(), WebActivity.class);
        WebActivity.URL = url;
        WebActivity.TITLE = title;
        startActivity(intent);
    }

    private void setupWebCard(int cardId, String url, String title) {
        rootView.findViewById(cardId).setOnClickListener(v -> {
            Intent intent = new Intent(getActivity(), WebActivity.class);
            WebActivity.URL = url;
            WebActivity.TITLE = title;
            startActivity(intent);
        });
    }

    private void startActivity(Class<?> activityClass) {
        Intent intent = new Intent(getActivity(), activityClass);
        startActivity(intent);
    }

    private void setupCitizenServiceCards() {
        // Setup complaint card - open complaint filing fragment
        rootView.findViewById(R.id.card1).setOnClickListener(v -> openComplaintFilingFragment());

        setupWebCard(
                R.id.card2,
                getString(R.string.citizen_service_interview_url),
                getString(R.string.citizen_service_interview_title)
        );

        // Setup information sharing card - open information sharing fragment
        rootView.findViewById(R.id.card3).setOnClickListener(v -> openInformationSharingFragment());
    }

    private void openComplaintFilingFragment() {
        // Get user ID from SharedPreferences or bundle
        String userId = getUserId();

        if (userId == null || userId.isEmpty()) {
            Toast.makeText(getContext(), "ব্যবহারকারী ID পাওয়া যায়নি", Toast.LENGTH_SHORT).show();
            return;
        }

        ComplaintFilingFragment fragment = ComplaintFilingFragment.newInstance(userId);
        getParentFragmentManager().beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .addToBackStack(null)
                .commit();
    }

    private void openInformationSharingFragment() {
        Toast.makeText(getContext(), "এই ফিচারটি এখনো চালু হয়নি।", Toast.LENGTH_SHORT).show();
    }

    private String getUserId() {
        SharedPreferences pref = requireActivity().getSharedPreferences(Config.PREF_NAME, Context.MODE_PRIVATE);
        return pref.getString("id", null);
    }
}
