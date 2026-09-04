package com.example.betagiesheva.Fragment;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.Toolbar;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.toolbox.JsonObjectRequest;
import com.bumptech.glide.Glide;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.NoticeModel;
import com.example.betagiesheva.R;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;

public class NoticeDetailsFragment extends Fragment {

    private static final String KEY_NOTICE = "notice";

    private TextView titleText, typeText, dateText, departmentText, descriptionText, attachmentCountText;
    private ImageView noticeImage;
    private RecyclerView attachmentRecyclerView;
    private LinearLayout emptyStateLayout, attachmentContainer;
    private ProgressBar progressBar;
    private Toolbar toolbar;

    private NoticeModel noticeModel;

    public static NoticeDetailsFragment newInstance(NoticeModel model) {
        NoticeDetailsFragment fragment = new NoticeDetailsFragment();
        Bundle b = new Bundle();
        b.putSerializable(KEY_NOTICE, model);
        fragment.setArguments(b);
        return fragment;
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater,
                             @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_notice_details, container, false);

        noticeModel = (NoticeModel) getArguments().getSerializable(KEY_NOTICE);
        if (noticeModel == null) {
            toast("নোটিশ তথ্য পাওয়া যায়নি");
            requireActivity().onBackPressed();
            return view;
        }

        initViews(view);
        setupToolbar();
        loadNoticeDetails();

        return view;
    }

    private void initViews(View view) {
        toolbar = view.findViewById(R.id.toolbar);
        titleText = view.findViewById(R.id.titleText);
        typeText = view.findViewById(R.id.typeText);
        dateText = view.findViewById(R.id.dateText);
        departmentText = view.findViewById(R.id.departmentText);
        descriptionText = view.findViewById(R.id.descriptionText);
        noticeImage = view.findViewById(R.id.noticeImage);
        attachmentRecyclerView = view.findViewById(R.id.attachmentRecyclerView);
        progressBar = view.findViewById(R.id.progressBar);
        emptyStateLayout = view.findViewById(R.id.emptyStateLayout);
        attachmentContainer = view.findViewById(R.id.attachmentContainer);
        attachmentCountText = view.findViewById(R.id.attachmentCountText);
    }

    private void setupToolbar() {
        if (toolbar != null) {
            toolbar.setTitle("নোটিশ বিস্তারিত");
            toolbar.setNavigationIcon(R.drawable.ic_arrow_back_black_24);
            toolbar.setNavigationOnClickListener(v -> requireActivity().onBackPressed());
        }
    }

    private void loadNoticeDetails() {
        if (noticeModel == null || TextUtils.isEmpty(noticeModel.getId())) {
            toast("নোটিশ আইডি পাওয়া যায়নি");
            return;
        }

        progressBar.setVisibility(View.VISIBLE);

        // Fetch complete notice data from API
        // NOTE: server's get_notice.php reads ?id=, not ?notice_id= — using the
        // wrong param made this always fall through to the list branch (raw array),
        // which JsonObjectRequest can't parse.
        String url = Config.NOTICE_LIST_URL + "?id=" + noticeModel.getId();
        JsonObjectRequest request = new JsonObjectRequest(
                Request.Method.GET,
                url,
                null,
                response -> {
                    progressBar.setVisibility(View.GONE);
                    try {
                        // Display notice data - now reading from flattened response
                        String title = response.optString("title", "শিরোনাম নেই");
                        titleText.setText(title);

                        // Set type with proper styling
                        String type = response.optString("type", "");
                        if (!TextUtils.isEmpty(type)) {
                            typeText.setText(type);
                            typeText.setVisibility(View.VISIBLE);
                            // Set background based on type
                            switch (type) {
                                case "গুরুত্বপূর্ণ":
                                    typeText.setBackgroundResource(R.drawable.notice_type_important);
                                    break;
                                case "সাধারণ":
                                    typeText.setBackgroundResource(R.drawable.notice_type_general);
                                    break;
                                case "ইভেন্ট":
                                    typeText.setBackgroundResource(R.drawable.notice_type_event);
                                    break;
                                case "ছুটি":
                                    typeText.setBackgroundResource(R.drawable.notice_type_holiday);
                                    break;
                                default:
                                    typeText.setBackgroundResource(R.drawable.notice_type_general);
                            }
                        } else {
                            typeText.setVisibility(View.GONE);
                        }

                        // Set date
                        String date = response.optString("notice_date", "তারিখ নেই");
                        dateText.setText(date);

                        // Set department
                        String department = response.optString("department", "");
                        departmentText.setText(department);
                        departmentText.setVisibility(TextUtils.isEmpty(department) ? View.GONE : View.VISIBLE);

                        // Set description
                        String description = response.optString("description", "কোন বিবরণ নেই");
                        descriptionText.setText(description);

                        // Load notice image
                        // NOTE: "image_url" is already a full URL built by the server's
                        // imageUrl() helper — do NOT prepend Config.IMAGE_URL (that
                        // constant only applies to /uploads/profiles/, i.e. user avatars).
                        String imageUrl = response.optString("image_url", "");
                        if (!TextUtils.isEmpty(imageUrl)) {
                            noticeImage.setVisibility(View.VISIBLE);
                            Glide.with(NoticeDetailsFragment.this)
                                    .load(imageUrl)
                                    .placeholder(R.drawable.profile)
                                    .error(R.drawable.profile)
                                    .into(noticeImage);
                        } else {
                            noticeImage.setVisibility(View.GONE);
                        }

                        // Handle attachments
                        setupAttachments(response);

                    } catch (Exception e) {
                        e.printStackTrace();
                        toast("ডেটা পার্স করতে ত্রুটি: " + e.getMessage());
                        progressBar.setVisibility(View.GONE);
                    }
                },
                error -> {
                    progressBar.setVisibility(View.GONE);
                    error.printStackTrace();
                    toast("নোটিশ লোড করতে ব্যর্থ হয়েছে");
                }
        );

        Config.getInstance(requireContext()).addToRequestQueue(request);
    }

    private void setupAttachments(JSONObject response) {
        try {
            JSONArray attachments = response.optJSONArray("attachments");
            // NOTE: get_notice.php's single-notice response has no "attachment_count"
            // key (that's only added on the list endpoint) — derive it from the array.
            int attachmentCount = attachments != null ? attachments.length() : 0;

            if (attachments != null && attachments.length() > 0) {
                attachmentContainer.setVisibility(View.VISIBLE);
                attachmentCountText.setText("সংযুক্তি (" + attachmentCount + ")");

                // Clear previous attachment views
                LinearLayout attachmentList = attachmentContainer.findViewById(R.id.attachmentListContainer);
                if (attachmentList != null) {
                    attachmentList.removeAllViews();

                    // Add each attachment as a clickable item
                    for (int i = 0; i < attachments.length(); i++) {
                        JSONObject attachment = attachments.getJSONObject(i);
                        String fileName = attachment.optString("file_name", "ফাইল " + (i + 1));
                        String filePath = attachment.optString("file_path", "");
                        String fileType = attachment.optString("file_type", "");

                        View attachmentView = createAttachmentView(fileName, filePath, fileType);
                        attachmentList.addView(attachmentView);
                    }
                }
            } else {
                attachmentContainer.setVisibility(View.GONE);
            }
        } catch (Exception e) {
            e.printStackTrace();
            attachmentContainer.setVisibility(View.GONE);
        }
    }

    private View createAttachmentView(String fileName, String filePath, String fileType) {
        View view = getLayoutInflater().inflate(R.layout.item_attachment, null);

        TextView fileNameText = view.findViewById(R.id.attachmentFileName);
        TextView fileTypeText = view.findViewById(R.id.attachmentFileType);
        ImageView fileIcon = view.findViewById(R.id.attachmentIcon);

        fileNameText.setText(fileName);
        fileTypeText.setText(fileType);

        // Set icon based on file type
        if (fileType.contains("pdf")) {
            fileIcon.setImageResource(R.drawable.ic_pdf);
        } else if (fileType.contains("image")) {
            fileIcon.setImageResource(R.drawable.ic_image);
        } else if (fileType.contains("doc")) {
            fileIcon.setImageResource(R.drawable.ic_doc);
        } else {
            fileIcon.setImageResource(R.drawable.ic_file);
        }

        view.setOnClickListener(v -> openAttachment(filePath));

        return view;
    }

    private void openAttachment(String url) {
        if (TextUtils.isEmpty(url)) {
            toast("অ্যাটাচমেন্ট URL পাওয়া যায়নি");
            return;
        }

        try {
            // If URL doesn't start with http, prepend the base URL
            String fullUrl = url;
            if (!url.startsWith("http")) {
                fullUrl = Config.BASE_URL + url;
            }

            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(fullUrl));
            startActivity(intent);
        } catch (Exception e) {
            toast("ফাইল খোলা যায়নি: " + e.getMessage());
        }
    }

    private void toast(String msg) {
        Toast.makeText(getContext(), msg, Toast.LENGTH_SHORT).show();
    }
}