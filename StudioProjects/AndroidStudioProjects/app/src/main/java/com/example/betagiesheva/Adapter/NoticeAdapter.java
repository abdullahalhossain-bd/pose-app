package com.example.betagiesheva.Adapter;

import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.Request;
import com.android.volley.RetryPolicy;
import com.android.volley.toolbox.StringRequest;
import com.example.betagiesheva.AddNoticeActivity;
import com.example.betagiesheva.Config;
import com.example.betagiesheva.Model.NoticeModel;
import com.example.betagiesheva.R;
import com.example.betagiesheva.SessionManager;
import com.example.betagiesheva.helper.AuthRequest;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class NoticeAdapter extends RecyclerView.Adapter<NoticeAdapter.ViewHolder> {

    Context context;
    ArrayList<NoticeModel> list;
    OnNoticeClickListener listener;
    SessionManager sessionManager;
    String userType = "";

    public interface OnNoticeClickListener {
        void onNoticeClick(NoticeModel model);
    }

    public NoticeAdapter(Context context, ArrayList<NoticeModel> list, OnNoticeClickListener listener) {
        this.context = context;
        this.list = list;
        this.listener = listener;
        this.sessionManager = new SessionManager(context);
        this.userType = sessionManager.getUserType();
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context)
                .inflate(R.layout.item_notice, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        NoticeModel model = list.get(position);

        holder.title.setText(model.getTitle());
        holder.description.setText(model.getDescription());
        holder.date.setText(model.getDate());
        holder.department.setText(model.getDepartment());

        // Set notice type with background based on type
        String noticeType = model.getType();
        if (!TextUtils.isEmpty(noticeType)) {
            holder.type.setText(noticeType);
            holder.type.setVisibility(View.VISIBLE);

            // Set background based on type
            switch (noticeType) {
                case "গুরুত্বপূর্ণ":
                    holder.type.setBackgroundResource(R.drawable.notice_type_important);
                    break;
                case "সাধারণ":
                    holder.type.setBackgroundResource(R.drawable.notice_type_general);
                    break;
                case "ইভেন্ট":
                    holder.type.setBackgroundResource(R.drawable.notice_type_event);
                    break;
                case "ছুটি":
                    holder.type.setBackgroundResource(R.drawable.notice_type_holiday);
                    break;
                default:
                    holder.type.setBackgroundResource(R.drawable.notice_type_general);
            }
        } else {
            // Show default type if empty
            holder.type.setText("সাধারণ");
            holder.type.setBackgroundResource(R.drawable.notice_type_general);
            holder.type.setVisibility(View.VISIBLE);
        }

        // Image indicator
        if (!TextUtils.isEmpty(model.getImageUrl())) {
            holder.imageIndicator.setVisibility(View.VISIBLE);
        } else {
            holder.imageIndicator.setVisibility(View.GONE);
        }

        // Attachment indicator (multiple attachments support)
        int attachmentCount = model.getAttachmentCount();
        if (attachmentCount > 0) {
            holder.attachment.setText("সংযুক্তি: " + attachmentCount);
            holder.attachment.setVisibility(View.VISIBLE);
        } else {
            holder.attachment.setVisibility(View.GONE);
        }

        // Admin controls - only show for admins
        if ("Admin".equalsIgnoreCase(userType)) {
            holder.editButton.setVisibility(View.VISIBLE);
            holder.deleteButton.setVisibility(View.VISIBLE);

            holder.editButton.setOnClickListener(v -> {
                Intent intent = new Intent(context, AddNoticeActivity.class);
                intent.putExtra("notice_data", model);
                context.startActivity(intent);
            });

            holder.deleteButton.setOnClickListener(v -> deleteNotice(model, position));
        } else {
            holder.editButton.setVisibility(View.GONE);
            holder.deleteButton.setVisibility(View.GONE);
        }

        holder.itemView.setOnClickListener(v -> listener.onNoticeClick(model));
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    private void deleteNotice(NoticeModel model, int position) {
        AuthRequest request = new AuthRequest(
                Request.Method.POST,
                Config.DELETE_NOTICE_URL,
                response -> {
                    try {
                        JSONObject jsonObject = new JSONObject(response);
                        if (jsonObject.optBoolean("success", false)) {
                            list.remove(position);
                            notifyItemRemoved(position);
                            notifyItemRangeChanged(position, list.size());
                            Toast.makeText(context, "নোটিশ সফলভাবে মুছে দেওয়া হয়েছে", Toast.LENGTH_SHORT).show();
                        } else {
                            String message = jsonObject.optString("message", "মুছে ফেলা ব্যর্থ হয়েছে");
                            Toast.makeText(context, message, Toast.LENGTH_SHORT).show();
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        Toast.makeText(context, "Error: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                    }
                },
                error -> {
                    error.printStackTrace();
                    Toast.makeText(context, "নেটওয়ার্ক সমস্যা", Toast.LENGTH_SHORT).show();
                },
                context
        ) {
            @Override
            protected Map<String, String> getParams() throws AuthFailureError {
                Map<String, String> params = new HashMap<>();
                params.put("id", model.getId());
                return params;
            }
        };

        int socketTimeout = 30000;
        RetryPolicy policy = new DefaultRetryPolicy(socketTimeout,
                DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
                DefaultRetryPolicy.DEFAULT_BACKOFF_MULT);
        request.setRetryPolicy(policy);

        Config.getInstance(context).addToRequestQueue(request);
    }

    static class ViewHolder extends RecyclerView.ViewHolder {

        TextView type, date, title, description, department, attachment;
        ImageView imageIndicator;
        ImageButton editButton, deleteButton;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            type = itemView.findViewById(R.id.noticeTypeText);
            date = itemView.findViewById(R.id.noticeDateText);
            title = itemView.findViewById(R.id.noticeTitleText);
            description = itemView.findViewById(R.id.noticeDescriptionText);
            department = itemView.findViewById(R.id.noticeDepartmentText);
            attachment = itemView.findViewById(R.id.noticeAttachmentText);
            imageIndicator = itemView.findViewById(R.id.noticeImageIndicator);
            editButton = itemView.findViewById(R.id.noticeEditButton);
            deleteButton = itemView.findViewById(R.id.noticeDeleteButton);
        }
    }
}